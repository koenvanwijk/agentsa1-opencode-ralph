#!/usr/bin/env python3
"""dslc — a tiny, reusable DSL compiler/validator.

Usage:
    dslc.py check    <file>...        # validate; exit 0 iff ALL files compile
    dslc.py compile  <file>           # validate and print the canonical JSON artifact
    dslc.py list                      # list registered grammars (by extension)
    dslc.py selftest [corpus_dir]     # golden self-test of a DSL's linter vs its corpus
                     [--emit-bad DIR]  #   also write the derived bad/ examples to DIR

A "grammar" is any module dropped into grammars/ that defines:

    EXTENSIONS = [".foo"]                      # file extensions it handles
    def compile(text: str) -> (ok, errors, artifact)
        # ok:       bool
        # errors:   list[str]  ("LINE: [RULE_ID] message", filename added by dslc)
        # artifact: any JSON-serialisable value (the "compiled" output)

Drop a new grammar module into grammars/ and it is picked up automatically —
that is the whole point of the registry: reuse this same compiler for new DSLs
without touching dslc.py.

`selftest` is the golden gate from CORPUS_REQUIREMENTS.md: it validates a DSL's
linter against its corpus WITHOUT any LLM. It (1) checks every good/ example
compiles clean, (2) checks the mutators cover the fault catalogue, and (3) for
each good example derives one bad example per rule-id (via mutators/<name>.py)
and checks the linter rejects it with EXACTLY that rule-id, at the expected
line. The derived-bad set is what keeps the test independent of the linter.
"""
import argparse
import importlib.util
import json
import os
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
GRAMMARS_DIR = HERE / "grammars"

_RULE_RE = re.compile(r"^\s*(\d+):\s*\[([A-Z_][A-Z0-9_]*)\]")
_CATALOGUE_RE = re.compile(r"^##\s+`([A-Z_][A-Z0-9_]*)`")


def _load_grammars():
    """Discover every grammar module in grammars/ and map extension -> module."""
    reg = {}
    for path in sorted(GRAMMARS_DIR.glob("*.py")):
        if path.name.startswith("_"):
            continue
        mod = _load_module("grammars", path.stem)
        for ext in getattr(mod, "EXTENSIONS", []):
            reg[ext] = mod
    return reg


def _load_module(subdir, stem):
    """Load tools/dslc/<subdir>/<stem>.py, or return None if it does not exist."""
    path = HERE / subdir / f"{stem}.py"
    if not path.exists():
        return None
    spec = importlib.util.spec_from_file_location(f"dslc_{subdir}_{stem}", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _check_one(reg, filename):
    ext = os.path.splitext(filename)[1]
    grammar = reg.get(ext)
    if grammar is None:
        return False, [f"{filename}: no grammar registered for extension '{ext}'"], None
    try:
        text = pathlib.Path(filename).read_text()
    except OSError as exc:
        return False, [f"{filename}: {exc}"], None
    ok, errors, artifact = grammar.compile(text)
    errors = [f"{filename}:{e}" for e in errors]
    return ok, errors, artifact


def _rule_ids(errors):
    """Rule-ids extracted from a list of 'LINE: [ID] msg' diagnostics."""
    out = []
    for e in errors:
        m = _RULE_RE.match(e)
        if m:
            out.append(m.group(2))
    return out


def _err_lines(errors):
    return {int(m.group(1)) for e in errors if (m := _RULE_RE.match(e))}


def _catalogue_ids(mistakes_path):
    ids = set()
    for line in pathlib.Path(mistakes_path).read_text().splitlines():
        m = _CATALOGUE_RE.match(line)
        if m:
            ids.add(m.group(1))
    return ids


def cmd_selftest(corpus_dir, emit_bad=None):
    corpus = pathlib.Path(corpus_dir).resolve()
    manifest_path = corpus / "manifest.json"
    if not manifest_path.exists():
        print(f"selftest: no manifest.json in {corpus}", file=sys.stderr)
        return 2
    manifest = json.loads(manifest_path.read_text())

    required = ["name", "extensions", "version", "spec", "mistakes", "examples_good"]
    miss = [k for k in required if k not in manifest]
    if miss:
        print(f"selftest: manifest missing keys: {miss}", file=sys.stderr)
        return 2

    name = manifest["name"]
    grammar = _load_module("grammars", name)
    if grammar is None:
        print(f"selftest: no grammar grammars/{name}.py", file=sys.stderr)
        return 2
    mutmod = _load_module("mutators", name)
    if mutmod is None or not getattr(mutmod, "MUTATORS", None):
        print(f"selftest: no mutators mutators/{name}.py with MUTATORS", file=sys.stderr)
        return 2

    exts = tuple(manifest["extensions"])
    good_dir = corpus / manifest["examples_good"]
    good_files = sorted(p for p in good_dir.glob("*") if p.suffix in exts)
    if not good_files:
        print(f"selftest: no good examples in {good_dir}", file=sys.stderr)
        return 2

    mistakes_path = corpus / manifest["mistakes"]
    catalogue = _catalogue_ids(mistakes_path) if mistakes_path.exists() else set()

    failures = []
    notes = []

    # 1. every good example must compile clean --------------------------------
    good_ok = 0
    for gf in good_files:
        ok, errors, _ = grammar.compile(gf.read_text())
        if ok:
            good_ok += 1
        else:
            failures.append(f"GOOD {gf.name} should compile but reported: {errors}")

    # 2. mutators must cover the fault catalogue ------------------------------
    mut_ids = set(mutmod.MUTATORS)
    if catalogue:
        uncovered = catalogue - mut_ids
        if uncovered:
            failures.append(f"catalogue rule-ids without a mutator: {sorted(uncovered)}")
        extra = mut_ids - catalogue
        if extra:
            notes.append(f"mutators not in catalogue (ignored): {sorted(extra)}")
    else:
        notes.append("no fault catalogue found; skipping coverage check")

    # 3. derive one bad example per (good, rule-id) and check the diagnosis ----
    emit_dir = pathlib.Path(emit_bad).resolve() if emit_bad else None
    if emit_dir:
        emit_dir.mkdir(parents=True, exist_ok=True)
    mutants = 0
    produced_by_id = {rid: 0 for rid in mutmod.MUTATORS}
    for gf in good_files:
        good_text = gf.read_text()
        for rid, fn in mutmod.MUTATORS.items():
            res = fn(good_text)
            if res is None:
                continue  # operator not applicable to this good file
            mutant, line = res
            produced_by_id[rid] += 1
            mutants += 1
            ok, errors, _ = grammar.compile(mutant)
            ids = set(_rule_ids(errors))
            if ok:
                failures.append(f"BAD {gf.stem}+{rid}: mutant compiled clean (no fault detected)")
            elif ids != {rid}:
                failures.append(f"BAD {gf.stem}+{rid}: expected only [{rid}], got {sorted(ids)}")
            elif line not in _err_lines(errors):
                failures.append(f"BAD {gf.stem}+{rid}: expected fault at line {line}, got {sorted(_err_lines(errors))}")
            elif emit_dir:
                stem = f"{gf.stem}__{rid.lower()}"
                (emit_dir / f"{stem}{gf.suffix}").write_text(mutant)
                (emit_dir / f"{stem}.expect").write_text(f"expect-error: {rid} at line {line}\n")

    # every catalogue id must have been exercised by at least one good file
    for rid in mutmod.MUTATORS:
        if rid in catalogue and produced_by_id[rid] == 0:
            failures.append(f"rule-id {rid} has a mutator but no good example could be mutated for it")

    # report -----------------------------------------------------------------
    for n in notes:
        print(f"selftest: note: {n}", file=sys.stderr)
    for f in failures:
        print(f"selftest: FAIL: {f}", file=sys.stderr)
    summary = (f"selftest[{name}]: {good_ok}/{len(good_files)} good compile, "
               f"{mutants} derived-bad mutants, {len(mut_ids)} rule-ids")
    if failures:
        print(f"{summary} -> FAIL ({len(failures)} problem(s))", file=sys.stderr)
        return 1
    print(f"{summary} -> PASS", file=sys.stderr)
    return 0


def main(argv):
    if not argv:
        print(__doc__)
        return 2
    cmd, rest = argv[0], argv[1:]

    if cmd == "selftest":
        ap = argparse.ArgumentParser(prog="dslc.py selftest")
        ap.add_argument("corpus_dir", nargs="?",
                        default=str(HERE / "corpus_template" / "flags"))
        ap.add_argument("--emit-bad", default=None)
        args = ap.parse_args(rest)
        return cmd_selftest(args.corpus_dir, args.emit_bad)

    reg = _load_grammars()

    if cmd == "list":
        for ext, mod in sorted(reg.items()):
            print(f"{ext:10s} {mod.__name__}")
        return 0

    if cmd in ("check", "compile"):
        if not rest:
            print(f"dslc: '{cmd}' needs at least one file", file=sys.stderr)
            return 2
        ok_all = True
        for f in rest:
            ok, errors, artifact = _check_one(reg, f)
            if ok:
                if cmd == "compile":
                    print(json.dumps(artifact, indent=2))
                else:
                    print(f"ok  {f}", file=sys.stderr)
            else:
                ok_all = False
                for e in errors:
                    print(f"error: {e}", file=sys.stderr)
        return 0 if ok_all else 1

    print(f"dslc: unknown command '{cmd}'", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
