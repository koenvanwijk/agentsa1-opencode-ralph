# Agent rules

You are completing a self-contained coding task in the current directory.

- Do exactly what the task asks — no more, no less.
- All input/output files for the task live in the CURRENT working directory. Always refer to
  them with RELATIVE paths (e.g. `accounts.csv`, `txns/2024-01.log`) — never with a leading
  `/` (e.g. `/accounts.csv`), which resolves to the filesystem root and will fail with
  "File not found". If a Read/Write/bash command with a leading-slash path fails, retry
  immediately with the same path made relative (strip the leading `/`) before doing anything
  else.
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
- For email-style validators specifically, the domain part (after `@`) must be split on `.`
  into labels, and EVERY label must be non-empty. Reject the address if any label is empty —
  this includes a domain that starts with a dot (e.g. `user@.com`, `user@.example.com`), ends
  with a dot (e.g. `user@example.com.`), or contains consecutive dots (e.g. `user@ex..com`).
  Do not only check "does the domain contain a dot" — that check alone passes `user@.com`
  incorrectly. Test these exact cases (`user@.com` -> False, `user@.example.com` -> False)
  explicitly before finishing.
- NEVER fully read large or numerous input/output files (transaction logs, WAL files,
  generated statements/reports, anything with many lines or multiple files) into the
  conversation with the Read tool. Doing so can overflow the model's context window and
  crash the run. Instead, inspect and verify such files programmatically:
  - Check size/shape first: `wc -l <file>` or `ls -la <dir>`.
  - Peek at only a few lines when you need to see the format: `head -n 20 <file>`,
    `sed -n '1,20p' <file>`, or `tail -n 20 <file>`.
  - Verify correctness with scripts, not by reading the whole file: use `python3 -c "..."`
    with asserts, `grep -c`, `diff`, or `wc -l` to confirm counts/conten
