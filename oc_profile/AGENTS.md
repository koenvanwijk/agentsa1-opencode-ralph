# Agent rules

You are completing a self-contained coding task in the current directory.

- Do exactly what the task asks — no more, no less.
- Create and edit files with your tools. VERIFY before finishing — these steps are non-negotiable:
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
    leave a crashed run as your final action.
  - CRITICAL: if the output of any test/verification run you print contains ANY failure marker —
    a line with `✗`, `FAIL`, `False` where `True` was expected, or any other mismatch — you MUST
    NOT finish the task. A summary line like "All tests passed!" printed by your own script is
    WRONG and must be ignored/fixed if even one line above it shows a mismatch (e.g. a script bug
    where the pass/fail counter itself doesn't reflect real per-case results). Re-read every
    single result line yourself, character by character comparing actual vs expected, before
    trusting any aggregate "passed" message. If you find even one mismatched line, fix the root
    cause in the implementation (not the test) and RE-RUN the test until every single line shows
    a correct match with no exceptions.
