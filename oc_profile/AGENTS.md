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
- NO-REGEX EMAIL VALIDATION — when a task asks you to validate emails WITHOUT using regex
  (no `re` module, no regex library), implement `is_valid_email` using plain string
  operations (`.split`, `.count`, indexing, `.isalnum`, etc.) and explicitly handle ALL of
  these edge cases, testing each one by hand against your implementation before finishing:
  - Exactly one `@` character: reject empty string, reject no `@`, reject more than one `@`
    (e.g. `user@@domain.com`, `user@domain@com`).
  - Local part (before `@`) must be non-empty and must NOT start or end with a `.`
    (e.g. `.name@domain.com` is invalid).
  - Domain part (after `@`) must be non-empty, must contain at least one `.`, must NOT
    start with `.` (e.g. `invalid@.com`), must NOT end with `.` (e.g. `user@domain.com.`),
    and the substring immediately after the LAST `.` (the TLD) must be non-empty and
    alphabetic with length >= 1 (e.g. `test@domain.c` is valid; `test@domain` with no
    dot is invalid).
  - Reject any email containing whitespace anywhere (spaces, tabs) — e.g.
    `user name@domain.com` and a trailing space `user@domain.com ` are both invalid.
  - Do not strip/trim the input before validating — leading/trailing whitespace or a
    trailing dot must cause rejection, not silent cleanup.
  - After writing the function, run it against a test list that includes every edge case
    above (both valid and invalid examples) and confirm each result matches expectations
    before considering the task done — do not stop after a single crash or an unverified run.
