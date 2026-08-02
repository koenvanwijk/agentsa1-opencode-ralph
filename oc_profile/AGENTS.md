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
    leading or trailing whitespace/newline in the string.
  - CONTEXT BUDGET: your context window is limited. NEVER read a large input file (WAL logs,
    big datasets, generated outputs with many lines/entries) in full into the conversation
    just to "check" it — that wastes tokens you need to finish the task and can cause a fatal
    context-overflow error late in the run. Instead verify large files programmatically:
    use shell commands (`wc -l file`, `grep -c pattern file`, `tail -n 20 file`) or a short
    Python script that reads the file, computes/prints only a compact summary (counts,
    checksums, first/last few lines, or specific assert results), and inspect that summary
    instead of the raw file. Only read a file's full contents into the conversation if it is
    small (roughly under 100 lines) or you specifically need to view an exact snippet.
