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
- STRING-BASED EMAIL / DOMAIN VALIDATION (no-regex tasks): when asked to validate an email
  address WITHOUT using regex, after splitting into local-part and domain on the single "@",
  you MUST explicitly check the domain for empty labels, not just "contains a dot":
  - Split the domain on "." and reject if ANY resulting label is the empty string — this
    catches a dot immediately after "@" (e.g. "user@.com" -> domain ".com" -> labels
    ["", "com"] -> invalid), a trailing dot (e.g. "user@domain." -> ["domain", ""] -> invalid),
    and consecutive dots (e.g. "user@do..main.com").
  - Also require at least 2 labels in the domain (i.e. at least one dot with non-empty parts
    on both sides), and reject a domain that starts or ends with ".".
  - After writing the validator, hand-test it against inputs like "user@.com", "user@domain.",
    and "user@domain..com" specifically — these empty-label cases are the most commonly missed
    edge case — before finishing.
