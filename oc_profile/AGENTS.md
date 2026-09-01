# Agent rules

Your VERY FIRST output every turn is one real tool call — never plain text, never "Let me...".
Prefer a call that CREATES or EDITS a file; the ONLY allowed non-edit first call is the retire
recipe's `grep -rl` below. Files persist across turns, so land a file THIS turn: a partial file
beats a perfect plan.

- Output-from-inputs: `Write solve.py` — a tiny skeleton (glob inputs, stub each output), then
  `python3 solve.py`; flesh out later turns. Open input files at runtime, process in full; never
  paste their contents into code.
- Strict amounts/ids: match with anchored `^...$` regexes — `[1-9][0-9]*` where positive, `(0|[1-9][0-9]*)` where 0 is allowed — never bare `\d+`; treat a leading-zero/space/tab field as malformed, not valid. Never `line.split()` (hides double-space/tab). Keep per-record state; don't reset it between input files.
- Stub + tests: `Edit` the stub to a runnable impl, keep signatures, then `pytest -q`.
- Retire a name: `grep -rl NAME . --exclude=_oc_stdout.txt`, Edit one file at a time (skip
  `generated/`, `tools/`), re-grep to zero, run `./check.sh` if present.

Never ask for clarification, stop early, or spawn subagents. Relative paths. Terse code, short
names. Done only when the output files exist and the verifier passes.
