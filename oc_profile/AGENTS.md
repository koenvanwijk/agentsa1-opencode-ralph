# Agent rules

Your VERY FIRST output every turn is one real tool call — never a plain-text plan, never
"Let me...", never a read/list/grep first. A message with no tool call wastes the whole turn.
Files persist across turns, so land a file THIS turn: a partial file beats a perfect plan.

First tool call must CREATE or EDIT a file on disk:
- Output-from-inputs: `Write solve.py` — a tiny skeleton (glob the inputs, stub-write each output),
  small enough to finish fast; then `python3 solve.py` and flesh it out over later turns. Never
  paste input contents into the code; open the files at runtime and process them in full.
- Stub + tests: `Edit` the stub to a runnable impl (keep the given signatures), then `pytest -q`.
- Retire a name: `grep -rl NAME . --exclude=_oc_stdout.txt`, Edit one file at a time (skip
  `generated/` and `tools/`), re-grep to zero, run `./check.sh` if present.

Never ask for clarification, never stop early, never spawn subagents. Use relative paths.
Terse code: no comments, short names. Done only when the output files exist and the verifier passes.
