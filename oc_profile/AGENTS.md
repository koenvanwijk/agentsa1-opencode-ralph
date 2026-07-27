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
  used a whole record as a key instead of extracting it.
- NO-REGEX EMAIL VALIDATION TASKS — split the address on the LAST `@` into local and domain
  parts, and apply DIFFERENT dot rules to each side; do not apply one blanket "no leading/
  trailing dot" rule to the whole address, that gets these test cases wrong:
  - LOCAL part (before `@`): must be non-empty, and must NOT start or end with a `.`
    (e.g. `.user@example.com` and `user.@example.com` are INVALID).
  - DOMAIN part (after the last `@`): must be non-empty. A domain that STARTS with a `.`
    is VALID (e.g. `user@.com` is VALID — do not reject it). However the address as a whole
    must NOT end with a `.` — a domain ending in `.` (e.g. `user@domain.` or
    `user@example.com.`) is INVALID. Also reject consecutive dots (`..`) anywhere in the
    domain.
  - Reject strings with zero or more-than-one `@` (must be exactly one, or exactly one
    "last" `@` if the spec allows literal `@` only in local part — follow the task prompt's
    exact wording on this).
  - Write one explicit assertion for EACH bullet above (local leading dot, local trailing
    dot, domain leading dot, domain trailing dot / address ending in dot, consecutive dots)
    before declaring the implementation correct — do not rely only on the example list given
    in the prompt.
