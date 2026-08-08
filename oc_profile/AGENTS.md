# Agent rules

You are completing a self-contained coding task in the current directory.

- CRITICAL — NEVER end your turn right after a Read. A Read produces nothing: no file is
  created or changed by reading. If the last thing you did this turn was Read a stub, a test
  file, or an input file, your turn is UNFINISHED — do not stop. The moment the file contents
  come back, your VERY NEXT action MUST be a Write/Edit tool call that creates or fills the
  required file, followed by actually running/verifying it. You may only end your turn once the
  required output file exists with real content AND (for stub-implementation tasks) you have RUN
  `python3 -m pytest -q` and watched every test pass. Reading ≠ done; writing + a green run = done.
- CRITICAL — EXPLORING IS NOT PROGRESS; NEVER STOP AFTER ONLY EXPLORING. Read, Glob, `ls`,
  `wc`, `head`, `cat` and every other look-at-the-input tool call produces NOTHING on disk. On
  any task that must produce output files (e.g. write rejected.txt/statement.txt/final.txt/
  stats.txt by replaying logs), you are NOT allowed to end your turn while the only things you
  have done are explore, plan, or describe a solution in prose. A turn that contains no
  Write/Edit and no run of your own script is a total failure that scores zero, no matter how
  correct your plan sounds. You are an autonomous agent: do NOT stop to present a plan, ask a
  question, or wait for confirmation — keep emitting real tool calls in the SAME turn until the
  required output files exist. Concretely, the moment you have glanced at the input format
  (`head -n 20`, `wc -l`), your VERY NEXT action MUST be a Write tool call creating a solver
  script (e.g. `solve.py`) that reads ALL the input programmatically and writes EVERY required
  output file, immediately followed by a bash call that RUNS it (`python3 solve.py`). Only after
  the output files exist on disk and you have re-checked them may you finish.
- Do exactly what the task asks — no more, no less.
- The task is only complete when the required OUTPUT ARTIFACT exists on disk. When the task
  says to write/save/output a value or result to a named file (e.g. "write the sum to
  result.txt", "write ONLY that number to result.txt"), you MUST create that file with a real
  Write tool call containing exactly the required content. Computing the answer and printing/
  echoing it in your text response DOES NOT satisfy the task and leaves the output file empty or
  missing — this is a total failure even when your number is correct. So: after you Read the
  input and work out the answer, your NEXT action must be a Write tool call that creates the
  named output file; do not end your turn until that file has been written. Before finishing,
  confirm the file exists and holds the intended value (e.g. `cat result.txt` for a tiny file,
  or `wc -c result.txt`).
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
  conversation — NOT with the Read tool, and NOT with a bash command that prints the whole
  file to the terminal (`cat <file>`, `grep -n "" <file>`, `grep -n <pat> <bigfile>`,
  `sed -n '1,$p'`, `head -n <huge>`, `cat -n`, or `awk '{print}'`). The context window is
  only ~32k tokens; dumping even one multi-thousand-line file to stdout overflows it and
  crashes the run BEFORE any output file is written (you get nothing). This is the #1 cause
  of a total failure on log/WAL tasks. Instead, inspect and verify such files
  programmatically:
  - Check size/shape first: `wc -l <file>` or `ls -la <dir>`.
  - Peek at only a few lines when you need to see the format: `head -n 20 <file>`,
    `sed -n '1,20p' <file>`, or `tail -n 20 <file>`.
  - If you need per-line NUMBERS (e.g. for output like `FILENAME:LINE OP`), do NOT
    `grep -n`/`cat -n` the file to get them — compute them INSIDE your script with
    `enumerate(f, start=1)` while you read each file line by line. Line numbers are 1-based
    and reset per file. Never print the numbered lines to the terminal.
  - Verify correctness with scripts, not by reading the whole file: use `python3 -c "..."`
    with asserts, `grep -c` (a COUNT, not `-n`), `diff`, or `wc -l` to confirm counts/content.
  - Do NOT try to HUNT for the tricky/malformed/rejected/edge-case lines by grepping the log
    files (`grep -n -E '<pattern>' txns/*.log`). Such a pattern almost always matches a huge
    fraction of the lines, and an UNBOUNDED grep (one without `| head`, or where you misjudged
    the match count) dumps thousands of matched lines to the terminal and overflows the 32k
    context — crashing the run before any output file is written. This is exactly how these
    tasks fail. Your PARSER is the single source of truth: encode EVERY validity/rejection rule
    from the prompt directly in your script and let it classify each line as it reads them; you
    never need to see the offending lines yourself. If you must run a diagnostic grep over the
    logs at all, use `grep -c` (a count) — never `grep -n`/`grep -E` that prints matched lines,
    and never a grep over `*.log` without a trailing `| head -n 20`.
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
- For a Hex / Connect / Polygon board-connection task (a parallelogram of HEXAGONAL cells shown
  as rows each indented one more space than the row above, two players `O` and `X`), the ONE thing
  that decides pass/fail is getting the hex ADJACENCY right — every trial that wrote a full BFS/DFS
  still failed because it used the wrong neighbor offsets. Parse the board by taking each line,
  `.strip()`-ing it and `.split()`-ting on whitespace into `grid[r][c]`. Each cell `(r, c)` has
  EXACTLY these 6 neighbors (clip any that fall off the board):
      (r, c-1), (r, c+1),      # same row: left, right
      (r-1, c), (r-1, c+1),    # row ABOVE
      (r+1, c-1), (r+1, c)     # row BELOW
  Do NOT use `(r-1, c-1)` or `(r+1, c+1)` — in this layout those diagonals are NOT adjacent, and
  using them (as is the intuitive but wrong guess) is the #1 cause of wrong winners. Win rules:
  `O` plays TOP→BOTTOM — it wins iff some `O` stone on the top edge (`r == 0`) connects through
  same-colour neighbors to the bottom edge (`r == height-1`). `X` plays LEFT→RIGHT — it wins iff
  some `X` stone on the left edge (`c == 0`) connects to the right edge (`c == width-1`). Only
  cells of the SAME player count as connected. Check `O` first, then `X`; if neither connects,
  return the empty string `''` (not `None`). A 1x1 board of `X` returns `'X'`, of `O` returns
  `'O'`. After writing connect.py, RUN `python3 -m pytest -q` and confirm every test passes before
  finishing.
- For a reactive / spreadsheet-style cell system (input cells with settable values, compute
  cells whose value is derived from other cells, plus change-notification callbacks), a value
  change must propagate to a NEW STABLE STATE before ANY callback fires. Do not freeze on the
  complexity — implement it directly with this exact recipe: each compute cell registers itself
  as an observer of every input cell it depends on, and its value is PURELY a function of its
  inputs' CURRENT values. When an input cell's value is set: (1) record the OLD value of every
  transitively-affected compute cell; (2) recompute those cells in DEPENDENCY ORDER (a cell is
  only recomputed after all cells it depends on have been recomputed) — repeat until no value
  changes, i.e. the system is stable; (3) THEN, once stable, fire each compute cell's callbacks
  exactly ONCE, and ONLY for the cells whose FINAL value differs from the old value recorded in
  step 1. NEVER fire callbacks during intermediate propagation, and NEVER fire when a cell's
  final value equals its old value even if intermediate values fluctuated. Concretely, if
  `plus_one` and `minus_one` both change but `always_two = plus_one - minus_one` stays 2, then
  `always_two`'s callback must NOT fire ([] expected, not [3, 2]) — this is the #1 bug in these
  tasks. After writing react.py (or the named stub), RUN `python3 -m pytest -q` and iterate
  until all tests pass; do not stop after only reading the stub and the test file.
- For an SGF (Smart Game Format) parser task — implement `parse(input_string)` returning an
  `SgfTree(properties, children)` — the make-or-break part is the TREE/CHILD structure; every
  trial that wrote a full parser still failed because it mishandled how nodes chain and how
  variations become children. Recipe (single recursive-descent pass over an index):
  1. VALIDATION first, with these EXACT messages: empty string, or a string not starting with
     `(` → `raise ValueError("tree missing")`; a tree with no first node such as `"()"` →
     `raise ValueError("tree with no nodes")`; a KEY that is not all-uppercase →
     `raise ValueError("property must be in uppercase")`; a `[...]` value with no preceding key,
     or properties lacking a delimiter → `raise ValueError("properties without delimiter")`.
     Then strip the outer `(` `)` and parse the inside as a node sequence.
  2. A NODE begins with `;`. After it, read the KEY (run of letters, must satisfy `.isupper()`),
     then read one OR MORE consecutive `[...]` groups — MULTIPLE `[..]` after one key are
     MULTIPLE VALUES for that key (`AB[aa][ab][ba]` → `{"AB": ["aa","ab","ba"]}`). Repeat per key
     until you hit `;`, `(`, or the end.
  3. CHILDREN — THIS is the bug everyone hits:
       - A chained `;` right after a node means that node has exactly ONE child: recursively parse
         the rest starting at that `;` into `children` (so `(;A[B];B[C])` → root `A[B]` with one
         child `B[C]`; a further `;C[D]` is that child's child — a single chain).
       - One or more `(...)` groups right after a node are that node's MULTIPLE children
         (variations): each balanced top-level `(...)` group is ONE separate child subtree — parse
         each independently and append each to `children`. So `(;A[B](;B[C])(;C[D]))` → root
         `A[B]` with TWO SIBLING children `B[C]` and `C[D]` (NOT nested, NOT flattened into a
         chain). This is exactly `test_two_child_trees`.
  4. VALUE text rules inside `[...]`: `\` is the escape char — `\]`→`]`, `\\`→`\`, and any
     NON-whitespace char after `\` is inserted as-is (so `\t`→`t`, `\n`→`n`; SGF has NO `\t`/`\n`
     whitespace escapes). A `\` immediately followed by a real newline deletes that newline (line
     continuation). Every whitespace char EXCEPT newline (tab, etc.) becomes a single space; real
     newlines stay as `\n`. `[`, `;`, `(`, `)` inside a value need no escaping.
  After writing sgf_parsing.py, RUN `python3 -m pytest -q` and iterate until every test passes;
  do not stop after only reading the stub and the test file, and do not leave scratch `print`
  debugging in the final file.
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
- For ledger/replay tasks that give a FIXED master list of accounts (e.g. `accounts.csv`), that
  file is the ONLY source of valid account ids. A transaction naming an id NOT in the master list
  must be REJECTED — and this applies to EVERY operation, INCLUDING DEPOSIT: a `DEPOSIT` to an
  unknown account (e.g. `DEPOSIT A9999 5000` when accounts are A1001..A1014) is rejected, not
  applied, and MUST appear in `rejected.txt`. Do NOT store balances in a `defaultdict` or otherwise
  auto-create an account on first reference: auto-vivifying an unknown id both (a) fails to reject
  that line and (b) gives the phantom account a balance, so later `WITHDRAW`/`TRANSFER` lines that
  name it are then wrongly APPLIED instead of rejected — one missing existence check cascades into
  several missed rejections. Instead, initialize your balances dict with EXACTLY the ids from the
  master file, and for every transaction FIRST verify that all ids it names are present in that dict
  (reject if any is absent) before you run the balance/self-transfer checks or apply anything.
- For tasks that ask you to IMPLEMENT/EDIT a stub file so that a PROVIDED TEST SUITE passes (e.g.
  "implement your solution by editing X.py", "all tests in X_test.py must pass", "make pytest
  pass"), the task is NOT complete until you have (a) replaced the stub with a full working
  implementation via a real Write/Edit tool call, and (b) actually RUN the tests
  (`python3 -m pytest -q`) and seen them all pass. Reading the stub and the test file is NOT
  progress toward completion — it produces nothing. A stub left with `pass`/`raise
  NotImplementedError`/`return None` is a total failure even though the file "exists". So: NEVER
  end your turn immediately after Read-ing the files. After you have read the stub and the tests,
  your NEXT action MUST be a Write/Edit tool call that supplies the real implementation, followed
  by a pytest run. If any test fails, fix the code and re-run until every test passes; only then
  may you finish. If you find yourself about to stop without having written code and seen a green
  pytest run, do not stop — write the implementation and run the tests.
- When the task specifies an EXACT output-line format (especially when it gives an example line
  like `2024-02.log:317 WITHDRAW` or `A1005 erin $7983.83`), your output must match that example
  field-for-field: the SAME number of fields, the same separators, and the same KIND of value in
  each position — no extra trailing fields and no substituting one value for another. Emit ONLY the
  fields the format names, in that order. If the format is `FILENAME:LINE OP`, write just the
  operation word (`DEPOSIT`), NOT the whole transaction line with its account/amount arguments.
  CRITICAL for that same `FILENAME:LINE OP` format: FILENAME must be the file's BASE NAME only
  (`2024-01.log`, `02.wal`) — NEVER include the directory you read it from. The input logs live in
  a subdirectory (`txns/`, `wal/`), so the path you opened is `txns/2024-01.log`, but the spec's
  example (`2024-02.log:317 WITHDRAW`) has NO `txns/`/`wal/` prefix. Emitting `txns/2024-01.log:611`
  instead of `2024-01.log:611` fails EVERY line of rejected.txt. Take the base name explicitly with
  `os.path.basename(path)` (or `os.listdir(dir)` which already yields base names) when you build each
  output line — do not reuse the joined path. Before finishing, confirm the first field of every line
  in rejected.txt has NO `/` in it. If a
  position names a field like `OWNER`, put that literal string from the input there (e.g. the owner
  name `erin`), never a number such as a balance or a cents value. Before finishing, print the first
  2-3 lines of each output file (`head -n 3 <file>`) and check each field position against the
  spec's example line — mismatched field count or a number where a name belongs means your writer is
  wrong; fix it and re-run before you stop.
