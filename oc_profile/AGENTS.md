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
- For a Forth-style evaluator (or any language where you can define named words/macros that
  reference other words), word definitions use EARLY BINDING: a definition captures the CURRENT
  meaning of every word it references at the moment it is defined, NOT at call time. Concretely,
  when you process a `: name ... ;` definition, expand each referenced user-defined word to its
  current definition (inline its stored tokens) and store that fully-expanded body — do NOT store
  the referenced word's NAME and look it up later. Otherwise a later redefinition wrongly changes
  earlier definitions: for `: foo 5 ;`, `: bar foo ;`, `: foo 6 ;`, `bar foo` must yield `[5, 6]`
  (bar keeps the old foo=5), and `: foo 10 ;`, `: foo foo 1 + ;`, `foo` must yield `11` (the new
  foo references the old foo). Late binding gives `[6, 6]` and infinite recursion respectively —
  both wrong. Redefining an existing word is always allowed and never an error.
- For log-replay / parse-and-count tasks that classify every input line as VALID vs
  MALFORMED/REJECTED/SKIPPED and then report aggregate COUNTS (e.g. `malformed N`), you MUST
  actually RUN your script and sanity-check the counts before finishing — never stop with the
  script written but unrun, and never trust an unverified count. Real input is mostly
  well-formed, so the malformed/invalid/skipped count must be a SMALL fraction of the total
  line count. If that count equals (or nearly equals) the total number of lines, your validity
  check is inverted or buggy — STOP and debug it. The classic cause is stripping the newline
  inconsistently: `line.rstrip('\n') != line.lstrip()` is True for EVERY ordinary line because
  `.lstrip()` keeps the trailing `\n`, so the whole file gets flagged malformed. Strip the
  newline exactly ONCE at the top (`line = line.rstrip('\n')`) and run every field/whitespace/
  case check on that single normalized string. Before you stop: print the counts and the first
  few lines of each output file, confirm the numbers are plausible (malformed « total), and
  confirm ALL required output files exist and are non-empty.
- When the task specifies an EXACT output-line format (especially when it gives an example line
  like `2024-02.log:317 WITHDRAW` or `A1005 erin $7983.83`), your output must match that example
  field-for-field: the SAME number of fields, the same separators, and the same KIND of value in
  each position — no extra trailing fields and no substituting one value for another. Emit ONLY the
  fields the format names, in that order. If the format is `FILENAME:LINE OP`, write just the
  operation word (`DEPOSIT`), NOT the whole transaction line with its account/amount arguments. If a
  position names a field like `OWNER`, put that literal string from the input there (e.g. the owner
  name `erin`), never a number such as a balance or a cents value. Before finishing, print the first
  2-3 lines of each output file (`head -n 3 <file>`) and check each field position against the
  spec's example line — mismatched field count or a number where a name belongs means your writer is
  wrong; fix it and re-run before you stop.
