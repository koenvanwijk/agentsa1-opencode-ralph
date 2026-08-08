#!/usr/bin/env python3
"""dslc — a tiny, reusable DSL compiler/validator.

Usage:
    dslc.py check   <file>...   # validate; exit 0 iff ALL files compile
    dslc.py compile <file>      # validate and print the canonical JSON artifact
    dslc.py list                # list registered grammars (by extension)

A "grammar" is any module dropped into grammars/ that defines:

    EXTENSIONS = [".foo"]                      # file extensions it handles
    def compile(text: str) -> (ok, errors, artifact)
        # ok:       bool
        # errors:   list[str]  ("LINE: message", filename is added by dslc)
        # artifact: any JSON-serialisable value (the "compiled" output)

Drop a new grammar module into grammars/ and it is picked up automatically —
that is the whole point of the registry: reuse this same compiler for new DSLs
without touching dslc.py.
"""
import importlib.util
import json
import os
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
GRAMMARS_DIR = HERE / "grammars"


def _load_grammars():
    """Discover every grammar module in grammars/ and map extension -> module."""
    reg = {}
    for path in sorted(GRAMMARS_DIR.glob("*.py")):
        if path.name.startswith("_"):
            continue
        spec = importlib.util.spec_from_file_location(f"dslc_grammar_{path.stem}", path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        for ext in getattr(mod, "EXTENSIONS", []):
            reg[ext] = mod
    return reg


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


def main(argv):
    reg = _load_grammars()
    if not argv:
        print(__doc__)
        return 2
    cmd, rest = argv[0], argv[1:]

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
