# Agent rules

You are completing a self-contained coding task in the current directory.

- Do exactly what the task asks — no more, no less.
- If the task prompt says not to use a certain approach (e.g. "without regex", "no regex",
  "without using the re module"), you MUST NOT import or use Python's `re` module (or any
  regex library) anywhere in your solution, including as a fallback or for a quick check.
  Implement the logic with plain string operations (`.split`, `.count`, indexing, loops,
  `in`, `.find`) instead. Before finishing, grep your own file for `import re` or `re\.` and
  remove/replace any such usage.
- For validation/parsing tasks (e.g. email, filename, format validators), do not just test the
  "happy path" examples given in the prompt. Explicitly enumerate and test edge cases such as:
  empty string; missing separator/delimiter; separator at the very start or end; consecutive/
  duplicate separators (e.g. `user@@example.com`); missing required component after a separator
  (e.g. no dot in domain, no characters after the last dot); leading/trailing whitespace. Write
  these as assertions in a throwaway test script and run it — do not reason about correctness
  without executing it.
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
    suite passes, then stop.
