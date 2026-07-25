# Agent rules

You are completing a self-contained coding task in the current directory.

- Do exactly what the task asks — no more, no less.
- Create and edit files with your tools. VERIFY before finishing — these steps are non-negotiable:
  - After you WRITE or EDIT any script, RUN it again. Every edit invalidates the previous
    run's output. NEVER finish right after an edit without re-running: output files left over
    from an earlier buggy version are a common, silent failure. Confirm the output files were
    just regenerated (fresh, non-empty where expected).
  - Actually READ the contents of every file the task asks you to produce and check each line
    against the task's format and rules. Hand-check the tricky edge cases the task calls out —
    e.g. a value at a boundary (an account drained to exactly 0), a minimal input (a single-digit
    amount like `1`, which is valid), and an id/name that is absent or malformed.
  - If you write a sentence like "the next step is to verify/fix ...", you MUST do it before
    stopping. Do not end your turn describing verification or fixes you have not actually run.
  - If a script you run RAISES AN EXCEPTION or crashes (Traceback, KeyError, IndexError, etc.),
    that is NOT the end of the task — you MUST read the traceback, find the root cause, fix the
    code, and RUN IT AGAIN until it completes cleanly and produces the expected output. Never
    leave a crashed run as your final action.
- LOG / WAL / MULTI-RECORD FILE PROCESSING — when a task involves replaying or parsing a
  sequence of records (e.g. write-ahead logs, transaction logs, journals) across one or more
  files:
  - Read and process ALL files and ALL records in each file, in the correct order (check
    filenames/sequence numbers/timestamps for the intended order — do not assume alphabetical
    sort is always correct without checking).
  - Do NOT assume a record's fields, referenced keys/accounts/ids always already exist. Before
    doing a lookup, mutation, or arithmetic on a key (e.g. `balances[key]`), check whether it
    exists yet and handle the "first time seen" / missing case explicitly (e.g. via `.get()`,
    `.setdefault()`, or an explicit `if key not in dict` branch) instead of assuming prior
    records guarantee its presence. A record can reference an entity that was created,
    deleted, or not yet initialized earlier in the log — handle create/update/delete ordering
    explicitly rather than assuming keys are always there.
  - If there is a `snapshot.txt` (or similarly named snapshot/checkpoint file) alongside the
    WAL/log files, it holds the STARTING state — load it FIRST and apply the WAL records ON
    TOP of it. Do not compute final state from the WAL files alone if a snapshot exists;
    a snapshot-then-replay task graded on final balances will fail if you skip the snapshot.
  - WAL files can contain a truncated, partial, or corrupt LAST LINE (e.g. a crash mid-write
    left an incomplete record). Explicitly guard the parse of the final line(s) of each WAL
    file: skip a line that doesn't have the full expected number of fields/tokens rather than
    letting it throw or silently corrupt a value. Do not assume every line is well-formed just
    because earlier lines were.
  - After computing the final state, do a SECOND independent pass (e.g. recompute from scratch,
    or re-run your script) and diff it against your first output before finishing — a one-off
    off-by-one in record ordering or line parsing is the single most common cause of wrong
    final balances in these tasks.
