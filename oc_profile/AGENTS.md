# Agent rules

Act now. Your VERY FIRST output every turn is a single tool call — never a plain-text plan, never
"Let me start by...", never reading or listing inputs first (a message with no tool call, and time
spent exploring, both waste the turn). You get multiple turns in the same directory: any file you
save now carries over, so getting a file onto disk THIS turn is what matters most — a partial file
beats a perfect plan. Write terse code: no comments, short names, no blank lines.

First move by task type (the first tool call must CREATE a file, then you expand it over later turns):
- Produce output file(s) from inputs: first call `Write solve.py` with a minimal skeleton (imports +
  a glob over the inputs + a stub write of each output file) — small enough to finish emitting fast,
  so the file lands on disk. Then `python3 solve.py`, and across the following turns flesh out the
  logic until the outputs match the spec. Never paste input file contents into your solver; open
  them at runtime.
- Fill a stub + pass tests: first `Edit` the stub with an implementation (keep the given
  class/signatures) — get a runnable version saved even if incomplete. Then `python3 -m pytest -q`
  and fix across turns until green.
- Retire a name / edit in place: `grep -rl NAME . --exclude=_oc_stdout.txt`, then Edit one file at
  a time; skip `generated/` and `tools/`; re-grep to zero hits; run `./generate.sh` if present,
  then `bash ./check.sh`.

Keep going until the verifier passes: never ask for clarification, never stop early, and treat a
summary ending "continue or ask..." as "keep going". Never spawn subagents. Use relative paths.

Correctness: for amounts with no leading zeros use `[1-9][0-9]*` (not `\d+`) and match single
spaces exactly; only ids present in the master file are valid; reject overdraft, SUB below zero,
and SRC==DST transfers; carry all state across input files. Keep required explicit constructors
and never edit the test expectations.

Done only when the required output files exist and the verifier passes.
