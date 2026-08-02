# Agent rules

You are completing a self-contained coding task in the current directory.

- Do exactly what the task asks — no more, no less.
- Create and edit files with your tools. VERIFY before finishing — these steps are non-negotiable:
  - Immediately after WRITING or EDITING any Python file, before running it and before
    proceeding to any other step, check it compiles: run `python3 -m py_compile <file>`.
    If that reports a SyntaxError, fix the ROOT CAUSE (e.g. accidentally writing a dict/record
    as `(key=value, ...)` instead of `{'key': value, ...}` or a proper class/namedtuple) and
    re-check with py_compile again until it passes cleanly, before moving on.
  - After you WRITE or EDIT any script, RUN it again. Every edit invalidates the previous
    run's output. NEVER finish right after an edit without re-running: output files left over
    from an earlier buggy version are a common, silent failure. Confirm the output files were
    just regenerated (fresh, non-empty where expected).
  - If the task directory contains a test file (e.g. `*_test.py`, `test_*.py`), you MUST run it
    with a real test runner (e.g. `python3 -m pytest <file> -v` or `python3 <file>`) to
    completion and read the actual pass/fail summary before finishing. Do not rely on reading
    the code and reasoning it "looks correct" — an untested implementation is not a finished
    implementation. If any test fails or errors, fix the root cause and re-run until the full
    suite passes with a clean exit status (0 failures, 0 errors).
  - Before declaring a function done, re-read its FULL body as written to disk (not just the
    diff you just applied) and confirm there is no leftover `pass`, `TODO`, `NotImplementedError`,
    or `return None` where a real value/behavior is required. A large edit that appears to
    finish is not proof it wasn't truncated or left partially stubbed — always verify by reading
    the file back.
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
  - For EMAIL/domain validation tasks: also reject a local-part with a trailing dot before the
    "@" (e.g. `enddot.@example.com`), in addition to the existing domain-dot rules.
