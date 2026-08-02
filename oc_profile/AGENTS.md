# Agent rules

You are completing a self-contained coding task in the current directory.

- Do exactly what the task asks — no more, no less.
- NEVER fully read large or numerous input/output files (transaction logs, WAL files,
  generated statements/reports, anything with many lines or multiple files) into the
  conversation with the Read tool. Doing so can overflow the model's context window and
  crash the run. Instead, inspect and verify such files programmatically:
  - Check size/shape first: `wc -l <file>` or `ls -la <dir>`.
  - Peek at only a few lines when you need to see the format: `head -n 20 <file>`,
    `sed -n '1,20p' <file>`, or `tail -n 20 <file>`.
  - Verify correctness with scripts, not by reading the whole file: use `python3 -c "..."`
    with asserts, `grep -c`, `diff`, or `wc -l` to confirm counts/contents match expectations.
  - When you must process every line of a large input for the actual task logic, do it inside
    your Python script (open/iterate the file there) — never by loading its full contents into
    your own context via the Read tool.
- Create and edit files with your tools. VERIFY before finishing — these steps are non-negotiable:
  - Immediately after WRITING or EDITING any Python file, before running it and before
    proceeding to any other step, check it compiles: run `python3 -m py_compile <file>`.
    If that reports a SyntaxError, fix the ROOT CAUSE (e.g. accidentally writing a dict/record
    as `(key=value, ...)` instead of `{'key': value, ...}` or a proper class/namedtuple) and
    re-check with py_compile again until it passes cleanly, before moving on.
  - After you WRITE or EDIT any script, RUN it again. Every edit invalidates the previous
    run's output. NEVER finish right after an edit without re-running: output files left over
    from an earlier buggy version are a common, silent failure. Confirm the output files were
    just regenerated (fresh, non-empty where expected), using `wc -l`/`ls -la`/`head`, not a
    full Read of large outputs.
  - If the task directory contains a test file (e.g. `*_test.py`, `test_*.py`), you MUST run it
    with a real test runner (e.g. `python3 -m pytest <file> -v` or `python3 <file>`) to
    completion and read the actual pass/fail summary before finishing. Do not rely on reading
    the code and reasoning it "looks correct" — an untested implementation is not a finished
    implementation. If any test fails or errors, fix the root cause and re-run until the full
    suite passes with a clean exit status (0 failures, 0 errors).
  - If the task has NO provided test file but asks you to implement validation/parsing logic
    (e.g. an email validator, a format checker), you MUST still write your own throwaway
    `python3 -c "..."` or scratch script with explicit `assert` statements covering BOTH valid
    and invalid cases before finishing, and actually run it to confirm every assert passes.
    At minimum, hand-check every edge case the task prompt calls out by name, plus these
    generic edge cases for "one @, non-empty parts, must contain a dot after @, no spaces,
    not starting/ending with @ or .": empty string; string with zero @; string with two or
    more @; string with nothing before @ (e.g. "@x.com"); string with nothing after @
    (e.g. "a@"); domain with no dot at all (e.g. "a@bcom"); a dot immediately after @
    (e.g. "a@.com"); a trailing dot at the very end (e.g. "a@b.com."); embedded spaces;
    leading or trailing whitespace/newline in the st
