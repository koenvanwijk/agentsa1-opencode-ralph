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
  - STRICT LINE VALIDATION ("well-formed" checks): when a spec defines a strict line format,
    do NOT use a loose `split()`/regex that silently tolerates violations. Explicitly reject
    (count as malformed) lines with: extra/missing fields; double spaces or tabs anywhere;
    leading or trailing whitespace; wrong case on the command word or key; a VALUE with a
    leading zero (e.g. `00`, `070`) unless the value is exactly `0`; a VALUE with a sign,
    decimal point, or non-decimal digits (`+25`, `-100`, `12.50`, `0x10`); a KEY outside the
    allowed character set/length. Verify field-splitting on a SINGLE space only (splitting on
    generic whitespace silently accepts tabs/multiple spaces as one separator — a common bug).
    Write a few inline unit-style checks against the file's OWN edge-case examples (if the
    prompt calls specific ones out, e.g. tie values, drains to 0, boundary values) before
    trusting the aggregate counts.
- NO-REGEX EMAIL VALIDATION — when asked to validate emails WITHOUT using regex, split on
  structure and check every one of these edge cases explicitly before considering the function
  done (a naive "has an @ and a dot" check WILL fail these):
  - Exactly one `@` — reject zero or multiple `@` characters.
  - Local part (before `@`) must be non-empty and must not start or end with a `.`; reject
    consecutive dots (`..`) in the local part.
  - Domain part (after `@`) must be non-empty, must contain at least one `.`, and must not
    start or end with a `.`; reject consecutive dots (`..`) in the domain.
  - Every label between dots in the domain (e.g. `example`, `com` in `example.com`) must be
    non-empty — an email like `test@.com` or `test@example..com` or `test@com.` is INVALID
    because it produces an empty label; do not just check "domain contains a dot", actually
    split the domain on `.` and verify no resulting piece is empty and the last piece (TLD)
    has length >= 2.
  - Reject whitespace anywhere in the address.
  - After writing the function, test it against BOTH valid examples (`a@b.co`) and ALL the
    invalid edge cases above (`test@.com`, `test@example..com`, `a@b.`, `@b.com`, `a@`,
    `a b@c.com`) and confirm each returns the expected True/False — do not stop after only
    testing the obviously-valid case.
