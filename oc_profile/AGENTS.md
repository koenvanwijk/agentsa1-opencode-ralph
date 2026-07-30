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
  test script file (e.g. `test_check.py`) with your test cases as real Python code, then run it
  with `python3 test_check.py`.
- When you use the file-read tool on an input/data file (logs, WAL files, snapshots, CSVs,
  etc.), the tool output prepends line numbers / formatting markup to each line for display —
  those numbers and markup are NOT part of the actual file content. Never assume a line's real
  offset, delimiter position, or byte content based on the tool's display. Before writing any
  parsing logic that depends on exact file format (column positions, delimiters, line ordering,
  file sizes), verify the raw content directly, e.g. with `python3 -c "print(repr(open('f').readlines()[:5]))"`
  written into a script file, or `wc -l`/`sort` on the actual filenames — and process the FULL
  file programmatically (never assume you've seen the whole file after reading only a sample).
