#!/usr/bin/env python3
"""Tier-B deterministic fan-out solver: one opencode subagent per part.

A multi-part task (feature-flag cleanup across several languages/DSLs) is solved
by running ONE opencode invocation per part, each in an ISOLATED workdir that
contains only that part's files plus a shared spec. Every subagent therefore
runs with a small, focused context — independent of whether the model can
orchestrate delegation itself (that is Tier A).

Reusable: point it at any task dir that carries a `subagents.json` manifest:

    {
      "spec": "<shared instruction every subagent gets>",
      "subagents": [
        {"name": "python", "files": ["features.py", "app.py"], "hint": "..."},
        ...
      ]
    }

Usage:
    fanout.py --task <task_dir> --work <workdir> [--dry-run] [--only NAME]

--dry-run prints each subagent's isolated file set + prompt WITHOUT calling the
model (proves the "small context" claim offline). --only NAME runs one subagent.
"""
import argparse
import json
import os
import pathlib
import shutil
import subprocess
import sys

REPO = pathlib.Path(__file__).resolve().parents[2]
MODEL = os.environ.get("OC_MODEL", "agentsa1/Agents-A1")
OPENCODE = os.environ.get("OPENCODE_BIN", os.path.expanduser("~/.local/bin/opencode"))
TIMEOUT = int(os.environ.get("FANOUT_TIMEOUT", "600"))

# Small, scoped rules for each subagent. MUST carry the critical anti-freeze
# rule — a fan-out that only shrinks context (dropping the main AGENTS.md)
# regresses this model into reading files then ending its turn without editing.
SCOPED_AGENTS = (
    "# Cleanup subagent\n\n"
    "You edit files in THIS directory to complete the change in the prompt.\n\n"
    "CRITICAL — do NOT end your turn right after a Read. Reading changes nothing.\n"
    "If the last thing you did was Read, your turn is UNFINISHED: your VERY NEXT\n"
    "action MUST be an Edit/Write tool call that actually removes the dead flags.\n"
    "You are only done once the file on disk has been edited; after editing,\n"
    "briefly confirm the change is present and that the file still parses.\n\n"
    "- Edit ONLY the files already in this directory; use relative paths.\n"
    "- Do not create new files or read anything outside this directory.\n"
)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--task", required=True)
    ap.add_argument("--work", required=True)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--only")
    args = ap.parse_args()

    task = pathlib.Path(args.task)
    work = pathlib.Path(args.work)
    manifest = json.loads((task / "subagents.json").read_text())
    spec = manifest["spec"]
    base_cfg = (REPO / "oc_profile" / "opencode.json").read_text()
    fan = work / ".fanout"

    for sub in manifest["subagents"]:
        name = sub["name"]
        if args.only and name != args.only:
            continue
        files = sub["files"]
        hint = sub.get("hint", "")

        d = fan / name
        if d.exists():
            shutil.rmtree(d)
        d.mkdir(parents=True)
        # copy ONLY this subagent's files -> isolated, minimal context
        for f in files:
            src, dst = work / f, d / f
            dst.parent.mkdir(parents=True, exist_ok=True)
            if src.exists():
                shutil.copy2(src, dst)
        (d / "opencode.json").write_text(base_cfg)
        (d / "AGENTS.md").write_text(SCOPED_AGENTS)

        prompt = (
            f"{spec}\n\n"
            f"You are the '{name}' cleanup subagent. {hint}\n"
            f"Edit ONLY these files (they are the only files here): {', '.join(files)}.\n"
            f"Make the change, then stop. Do not create new files."
        )

        if args.dry_run:
            present = sorted(p for p in os.listdir(d) if p not in ("opencode.json", "AGENTS.md"))
            print(f"===== subagent {name} =====")
            print(f"context files: {present}  (+ scoped AGENTS.md/opencode.json)")
            print(f"prompt ({len(prompt.split())} words):")
            print(prompt)
            print()
            continue

        try:
            with open(d / "_oc.txt", "w") as log:
                subprocess.run(
                    [OPENCODE, "run", "--dir", str(d), "-m", MODEL, prompt],
                    stdout=log, stderr=subprocess.STDOUT, timeout=TIMEOUT,
                )
        except subprocess.TimeoutExpired:
            print(f"subagent {name}: TIMEOUT after {TIMEOUT}s", file=sys.stderr)
        # merge edited files back into the shared workdir
        for f in files:
            s = d / f
            if s.exists():
                shutil.copy2(s, work / f)
        print(f"done subagent {name}")


if __name__ == "__main__":
    main()
