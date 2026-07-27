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
- STATEFUL LOG / WAL / TRANSACTION PROCESSING TASKS — before writing code, explicitly decide
  the state schema: what are the keys (must be simple hashable values like a string account id
  or int, NEVER a dict, list, or other mutable/unhashable value) and what are the values (may be
  dicts, e.g. `{"balance": int}`). A `TypeError: unhashable type: 'dict'` or similar means you
  used a whole record as a key instead of extracting it
- NO-REGEX EMAIL VALIDATION — the local part and the domain part have DIFFERENT dot rules.
  Do not apply the same "no leading/trailing dot" check to both halves:
  - LOCAL part (before the @): must be non-empty, and must NOT start or end with a dot
    (`.user@host.com` is invalid, `user.@host.com` is invalid).
  - DOMAIN part (after the @): must be non-empty and must NOT END with a dot
    (`user@host.com.` is invalid, `user@com.` is invalid). However a domain that STARTS
    with a dot is VALID and must be accepted (`user@.com` is valid, `invalid@.com` is valid) —
    do not reject a leading dot in the domain, only a trailing one.
  - Also reject: no `@`, more than one `@`, empty local or domain, any whitespace anywhere,
    and domain with no dot at all (`user@domain` is invalid). Write one dedicated test per
    rule above (both a passing and failing example) before finishing.
