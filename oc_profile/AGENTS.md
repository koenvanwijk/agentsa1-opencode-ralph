# Agent rules

Act now. Your first output every turn is a single tool call, never a plain-text plan (a message
with no tool call ends the turn). Do not read the input data files first — write code that opens
them itself. Write terse code: no comments, short names, no blank lines.

First move by task type:
- Produce output file(s) from inputs: first call `Write solve.py`, a complete solver written from
  the prompt alone that globs and reads its own inputs and writes every output file. Then
  `python3 solve.py` and fix until the outputs match the spec.
- Fill a stub + pass tests: first call `Write`/`Edit` the stub with a complete implementation
  (keep the given class/signatures). Then `python3 -m pytest -q` and fix until green.
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
