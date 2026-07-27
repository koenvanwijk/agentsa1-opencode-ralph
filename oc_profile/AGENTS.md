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
  - Writing your OWN quick test cases and seeing them pass is NOT sufficient proof of
    correctness — your self-written tests can share the same blind spots as your
    implementation. Deliberately try to construct inputs that violate the rules stated in the
    task prompt, not just inputs that resemble the examples given. If the task lists specific
    validation rules (e.g. "no consecutive dots", "must not start/end with a dot"), write a
    dedicated test for EACH rule stated, both a case that violates it and a case that satisfies
    it, before concluding your implementation is correct.
  - If you write a sentence like "the next step is to verify/fix ...", you MUST do it before
    stopping. Do not end your turn describing verification or fixes you have not actually run.
  - If a script you run RAISES AN EXCEPTION or crashes (Traceback, KeyError, IndexError, etc.),
    that is NOT the end of the task — you MUST read the traceback, find the root cause, fix the
    code, and RUN IT AGAIN until it completes cleanly and produces the expected output. Never
    leave a crashed run as your final action.
- NO-REGEX STRING VALIDATION TASKS (e.g. email/address/id validators implemented without the
  `re` module) — the task's stated rules are the full spec, not just the examples shown. In
  particular, for domain/local-part validation, explicitly check ALL of the following unless
  the task says otherwise:
  - No leading dot, no trailing dot, in EITHER the local part or the domain.
  - No two consecutive dots anywhere (`..`) in EITHER the local part or the domain.
  - No empty label: a domain of the form `a@.com`, `a@b..com`, or a domain ending right after
    `@` is invalid — every dot-separated domain label must be non-empty.
  - Exactly one `@`, with non-empty content on both sides.
  Do not assume an example like `test@.com` is valid just because it wasn't in your own quick
  test list — re-derive expected True/False for every boundary case explicitly from the stated
  rules before trusting a "PASS" from a self-authored test script.
  - After every edit to a validator function, IMMEDIATELY run the file (e.g. `python3 file.py`)
    and check for a SyntaxError or an incomplete/truncated function body (a lone `if no`,
    a dangling `if`/`elif` with no body, a missing `return`, etc.). A half-written edit that
    leaves the file syntactically broken or logically incomplete is a hard failure — if the run
    errors or the function clearly doesn't implement all stated rules, rewrite the WHOLE
    function body in one edit (do not leave partial line fragments) and re-run until it is
    syntactically valid and passes every rule-derived test case above.
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
