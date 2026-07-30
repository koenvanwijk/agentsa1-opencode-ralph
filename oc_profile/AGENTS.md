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
- NEVER run ad-hoc test code as an inline `python3 -c "..."` one-liner, especially with long
  lists of test tuples or multiple statements/semicolons. These are error-prone to quote
  correctly and commonly get truncated or mis-escaped by the shell, producing a SyntaxError
  that has NOTHING to do with your actual implementation. Instead, WRITE a small standalone
  test script file (e.g. `test_check.py`) with your test cases as rea
- When a task requires PARSING line-based data files (logs, WAL/transaction files, CSV-like
  formats), do NOT trust visual inspection of individual lines via tools like `sed -n` or the
  Read tool as ground truth for exact byte content — tabs, trailing whitespace, and delimiter
  characters can be invisible or misrendered in a terminal/tool display. Instead, WRITE and RUN
  a small Python script that opens the file (in text or binary mode as appropriate) and parses
  EVERY line programmatically using `.split()`/`.split('\t')`/explicit delimiter logic, then
  prints out any line that fails to parse as expected (e.g. wrong field count, unexpected
  token) so you can see the exact repr() of the problematic line, including whitespace and
  control characters. Never manually eyeball a handful of lines with `sed`/`cat -A` and infer
  the parsing rule for the whole file — process the ENTIRE file in code, and handle every
  malformed/edge-case line the same way a correct implementation must.
