#!/usr/bin/env python3
"""Convert aider polyglot-benchmark Python exercises into bench_pool/ tasks.

Each pool task gets the standard layout (prompt.txt, seed/, _reference/,
verify.sh) and is validated the same way gen_task.sh validates generated
tasks: the reference solution must pass verify.sh, the seed alone must fail.
Valid tasks land in bench_pool/<slug>/ ready for scripts/import_bench.sh.
"""
import json, os, shutil, subprocess, sys, tempfile

SRC = os.path.expanduser("~/.openclaw/workspace/polyglot-benchmark/python/exercises/practice")
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POOL = os.path.join(REPO, "bench_pool")

VERIFY = """#!/bin/bash
# verify.sh <workdir> — restore pristine tests, then run pytest
W="$1"; T="$(cd "$(dirname "$0")" && pwd)"
{restores}
cd "$W" || exit 1
timeout 180 python3 -m pytest -q {tests} >/dev/null 2>&1
"""

PROMPT_FOOTER = """
====
Implement your solution by editing {solutions} in the current directory.
All tests in {tests} must pass. Check your work by running:

    python3 -m pytest -q

Do NOT modify the test file(s). The stub file already exists — replace its
contents with a working implementation.
"""

def convert(ex):
    src = os.path.join(SRC, ex)
    cfg = json.load(open(os.path.join(src, ".meta", "config.json")))
    sols = cfg["files"]["solution"]
    tests = cfg["files"]["test"]
    examples = cfg["files"]["example"]
    if len(sols) != len(examples):
        return f"SKIP {ex}: {len(sols)} solution files vs {len(examples)} examples"

    slug = ex.replace("-", "_")
    dst = os.path.join(POOL, slug)
    if os.path.exists(dst):
        shutil.rmtree(dst)
    os.makedirs(os.path.join(dst, "seed"))
    os.makedirs(os.path.join(dst, "_reference"))

    # seed: stubs + tests, exactly as the benchmark ships them
    for f in sols + tests:
        shutil.copy(os.path.join(src, f), os.path.join(dst, "seed", os.path.basename(f)))
    # reference: example solutions renamed onto the solution filenames
    for sol, exf in zip(sols, examples):
        shutil.copy(os.path.join(src, exf), os.path.join(dst, "_reference", os.path.basename(sol)))

    # prompt: instructions (+append) + our harness footer
    parts = []
    for doc in ("instructions.md", "instructions.append.md", "introduction.md"):
        p = os.path.join(src, ".docs", doc)
        if os.path.exists(p) and doc != "introduction.md" or (doc == "introduction.md" and not parts):
            if os.path.exists(p):
                parts.append(open(p).read())
    tnames = " ".join(os.path.basename(t) for t in tests)
    snames = ", ".join(os.path.basename(s) for s in sols)
    parts.append(PROMPT_FOOTER.format(solutions=snames, tests=tnames))
    open(os.path.join(dst, "prompt.txt"), "w").write("\n".join(parts))

    restores = "\n".join(
        f'cp "$T/seed/{os.path.basename(t)}" "$W/{os.path.basename(t)}" || exit 1'
        for t in tests)
    vpath = os.path.join(dst, "verify.sh")
    open(vpath, "w").write(VERIFY.format(restores=restores, tests=tnames))
    os.chmod(vpath, 0o755)

    # validate: reference passes, seed-only fails
    def run(with_ref):
        w = tempfile.mkdtemp()
        shutil.copytree(os.path.join(dst, "seed"), w, dirs_exist_ok=True)
        if with_ref:
            shutil.copytree(os.path.join(dst, "_reference"), w, dirs_exist_ok=True)
        rc = subprocess.run(["bash", vpath, w], capture_output=True).returncode
        shutil.rmtree(w)
        return rc
    ref_rc, seed_rc = run(True), run(False)
    if ref_rc == 0 and seed_rc != 0:
        return f"OK   {slug}"
    shutil.rmtree(dst)
    return f"FAIL {ex}: ref_rc={ref_rc} seed_rc={seed_rc} — discarded"

def main():
    os.makedirs(POOL, exist_ok=True)
    results = [convert(ex) for ex in sorted(os.listdir(SRC))]
    for r in results:
        print(r)
    ok = sum(1 for r in results if r.startswith("OK"))
    print(f"\n{ok}/{len(results)} exercises converted into {POOL}")

if __name__ == "__main__":
    main()
