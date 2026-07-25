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
  - Also handle partial/incomplete/corrupt trailing records (e.g. a truncated last line) by
    skipping or ignoring them rather than crashing, unless the task explicitly says otherwise.
  - After implementing the parser, run it against every provided log file end-to-end and
    confirm it completes without exceptions AND the final output matches the exact format
    the task's verify step expects, before considering the task done.
- EMAIL / "a `.` after the `@`" VALIDATION — this is stricter than a literal reading
  of the prompt, and this rule OVERRIDES that literal reading. "At least one `.`
  somewhere after the `@`" and "does not start or end with `.`" must be checked on the
  DOMAIN part (everything after the `@`) BY ITSELF, not only on the whole string. So the
  domain must NOT start with `.` and must NOT end with `.`. Consequence: `a@.com` (same
  as `user@.com`) is INVALID even though the full string does not start with `.`, because
  its domain `.com` starts with `.`. Likewise `a@b.` is invalid (domain ends with `.`).
  The simplest correct domain test is: `dom` contains `.` AND `not dom.startswith('.')`
  AND `not dom.endswith('.')` — do NOT use `'.' in dom` alone. Your own test list MUST
  include `a@.com` asserted to return False; if your test claims it is True, that is a
  BUG to fix, not a valid case.
- CONTAINS-a-delimiter rules are NOT satisfied by mere presence. When a rule says a
  part must CONTAIN a character `C` (e.g. "at least one `.` after the `@`"), the
  correct, strict check is: `C` appears AND the part does not start or end with `C`
  AND `C` is never adjacent to another `C`. Equivalently: every piece of
  `part.split(C)` must be non-empty. Do NOT write `C in part` alone — that wrongly
  accepts empty segments. Use this exact pattern:
      ok = 
