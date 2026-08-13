# Agent rules

Do the task in the CURRENT directory. Context is ~32k and the turn dies at a hard timeout, so
DO NOT think at length and DO NOT read files before acting. Your FIRST output MUST be a
repo-changing tool call (`Write` or `Edit`), authored from the prompt alone. Never emit a
plain-text plan first — a message with no tool call ENDS the turn. Keep prose to ONE final line
after the verifier passes.

First move by task type:
- Turns inputs into OUTPUT file(s): FIRST call is `Write solve.py`, a COMPLETE solver written
  blind from the spec. It globs its own inputs, reads them ALL programmatically, writes every
  output file. Then `python3 solve.py`, then fix and re-run until correct. Don't Read/ls/cat first.
- Stub + tests: FIRST call is `Write` filling the stub with a COMPLETE implementation (keep the
  class/signatures). Then `python3 -m pytest -q` and fix until green. No `solve.py`.
- Edit-in-place / retire a flag/name / "keep it compiling": `grep -rl NAME . --exclude=_oc_stdout.txt`
  for the file list, then Read→Edit ONE FILE AT A TIME down that list (never batch-read, never
  re-read an edited file, skip `generated/`+`tools/*`). Then re-grep every spelling until zero hits
  (or the ONE allowed loader discard line), run `./generate.sh` if present, then `bash ./check.sh`.

Never stop to "ask for clarification" — the prompt has every rule you need; keep going until the
verifier passes. A re-injected summary ending "continue or ask..." means KEEP GOING.

Never spawn subagents / `task` / fanout — one GPU, they block and time out. Do multi-file work
yourself, sequentially.

Use RELATIVE paths only (`solve.py`, `txns/2024-01.log`) — bare filenames write to cwd.

Don't dump big files into the terminal (`cat`/`grep -n`/`sed` a whole file overflows context).
Shape with `wc -l`/`head -n 20`; let your PARSER encode every validity rule and compute
`FILENAME:LINE OP` line numbers internally (`enumerate(f, start=1)`, basename only).

Correctness reminders:
- Integers with "no leading zeros": anchor the WHOLE line with regex, `[1-9][0-9]*` not `\d+`
  (a bare `\d+` wrongly accepts `0500`). Don't `line.split()` — match literal single spaces.
- Ledger replay: only ids in the master file (`accounts.csv`) are valid; reject unknown ids for
  every op, no `defaultdict`; overdraft strict (0 ok), SRC==DST transfer rejected.
- Retirement: keep required explicit constructors; don't rewrite test expectations; the transcript
  `_oc_stdout.txt` also gets graded, so if a task forbids the name everywhere, `: > _oc_stdout.txt`
  as your LAST call.

Done only when the required OUTPUT files exist and the verifier passes — printing the answer in
your reply does NOT count. Run the verifier before your final line.
