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
- EMAIL VALIDATION WITHOUT REGEX — when asked to validate an email address without using the
  `re` module, split on `@` and `.` manually and check ALL of the following explicitly (do not
  rely on "looks reasonable" heuristics):
  - Exactly one `@`, with a non-empty local part and non-empty domain part.
  - The domain must contain at least one `.`, and splitting the domain on `.` must yield a TLD
    (last label) that is non-empty and at least 2 characters.
  - NO domain label (the parts between dots, including the first and last) may be empty —
    reject a domain starting with `.` (e.g. `bad@.com`), ending with `.` (e.g. `bad@com.`), or
    containing consecutive dots (e.g. `bad@ex..com`). Splitting `.com` on `.` gives `['', 'com']`
    — an empty first element means the domain is invalid; check for this explicitly.
  - Reject leading/trailing whitespace or dots in the local part, and reject a local part that
    is empty, is just dots, or contains consecutive dots.
  - After writing the function, explicitly test it against boundary cases including
    `bad@.com`, `bad@com.`, `bad@ex..com`, `a@b.co` (valid minimal), and a local part with a
    leading dot, before finishing.
  
