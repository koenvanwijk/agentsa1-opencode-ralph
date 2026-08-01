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
  - For EMAIL/domain validation specifically: the domain part must not contain an EMPTY LABEL
    between dots or right after the "@". Concretely, test `user@.com` (label right after @ is
    empty), `user@domain..com` (empty label between two dots), and `user@domain.com.` (empty
    label at the end) — all three MUST be rejected. A common bug is checking only for a "."
    somewhere in the domain without checking each dot-separated label is non-empty.
  - If you write a sentence like "the next step is to verify/fix ...", you MUST do it before
    stopping. Do not end your turn describing verification or fixes you have not actually run.
  - If a script you run RAISES AN EXCEPTION or crashes (Traceback, KeyError, IndexError, etc.),
    that is NOT the end of the task — you MUST read the traceback, find the root cause, fix the
    code, and RUN IT AGAIN until it completes cleanly and produces the expected output. Never
    leave a crashed run unresolved.
  - Before finishing, run a final scan of every file you wrote/edited for leftover stub or
    placeholder code: a bare `pass`, a function that only does `return None`/returns nothing
    where a value is required, `TODO`/`FIXME` comments, `NotImplementedError`, or `...` as a
    function body. Every function the task exercises (check this against the test file or
    prompt, e.g. `evaluate()` in a Forth interpreter) must have a REAL, COMPLETE implementation
    that returns the correct value — not a skeleton you meant to fill in later. If you find any
    such stub, implement it fully and re-run the tests/verification before finishing.
  - When rewriting or replacing an existing file (not a small edit), read the ENTIRE original
    file first and make sure your replacement covers ALL of the original's logic/cases — a
    partial rewrite that drops branches, functions, or edge-case handling is a common source of
    regressions. After rewriting, run the tests to confirm nothing that used to pass now fails.
