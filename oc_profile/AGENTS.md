# Agent rules

Your VERY FIRST output every turn is one real tool call — never plain text, never "Let me...",
never a `Read`/`Glob`/`List` first. On turn 1 no solver file exists yet, so that call CREATES one
(`Write solve.py` with a tiny skeleton). On EVERY later turn a solver file ALREADY exists — so your
first call RUNS or FIXES it: `python3 solve.py` (or `pytest -q`) to regenerate the output, or an
`Edit` to correct an error you already saw — NEVER re-`Read` the inputs and never `Glob` for a test
file. The task PROMPT already states the COMPLETE input format and every rule, and solve.py opens
the inputs itself at runtime, so you never need to read them to learn their shape. Re-reading inputs
or globbing on turn 2 is exactly what kills these turns — the slow backend times out mid-turn and
the run is suppressed with zero new artifacts (the output only appears once you actually RUN the
solver you wrote). Land/advance a file THIS turn; files persist, so flesh it out on later turns.
The ONLY allowed non-edit/non-run first call is the retire recipe's `grep -rl` below.

- Output-from-inputs: `Write solve.py` — a tiny skeleton (glob inputs, stub each output), then
  `python3 solve.py`; flesh out later turns. Open input files at runtime, process in full; never
  paste their contents into code.
- Strict amounts/ids: match with anchored `^...$` regexes — `[1-9][0-9]*` where positive, `(0|[1-9][0-9]*)` where 0 is allowed — never bare `\d+`; treat a leading-zero/space/tab field as malformed, not valid. Never `line.split()` (hides double-space/tab). Keep per-record state; don't reset it between input files.
- Transactional replay (WAL/txn logs): treat ALL input files as ONE continuous stream — carry the committed store AND any open transaction across file boundaries; never re-init per file. BEGIN opens a private working copy of committed (data cmds hit it and see each other); COMMIT replaces committed, ROLLBACK discards it; a txn still open at EOF is discarded but is NOT counted as rolled_back. Decide/record a reject at the moment the line is processed — it stays in the reject log even if its txn is later rolled back or never commits. Count `malformed` (bad syntax, skipped) separately from `rejected` (well-formed but no effect); they never overlap.
- Stub + tests: first `Edit` the stub to a minimal runnable version (keep signatures) so a file lands this turn, THEN `Read` the `*_test.py` — it is the spec: note every exact expected value and which bad inputs must `raise ValueError(msg)` with a message — flesh out the impl and `pytest -q`; iterate until all pass, don't stop on the first failure.
- Retire a name: `grep -rl NAME . --exclude=_oc_stdout.txt`, Edit one file at a time (skip
  `generated/`, `tools/`), re-grep to zero, run `./check.sh` if present.

Never ask for clarification, stop early, or spawn subagents. Relative paths. Terse code, short
names. Done only when the output files exist and the verifier passes.
