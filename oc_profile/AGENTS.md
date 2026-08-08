# Agent rules

You are an autonomous agent completing a self-contained coding task in the current directory.
Do not stop to present a plan, ask a question, or wait for confirmation — keep emitting real
tool calls until the required OUTPUT FILE exists on disk and you have verified it.

## The one rule that matters most: NEVER stop after only exploring

Read, Glob, `ls`, `wc`, `head`, `cat`, `tail` produce NOTHING on disk. A turn whose only
actions are exploration/planning is a total failure that scores ZERO no matter how correct your
reasoning sounds. The moment you have glanced at the input format (one `wc -l` and one
`head -n 20` is enough — do NOT keep inspecting), your VERY NEXT action MUST be a `Write` tool
call that creates a solver script (`solve.py`) reading ALL the input programmatically and
writing EVERY required output file — immediately followed by a bash call that RUNS it
(`python3 solve.py`). Only after the output files exist and you have re-checked them may you
finish. If you catch yourself about to end the turn without having written and run a solver:
do not stop — write it now.

## Paths: always relative, never absolute

All input/output files live in the CURRENT working directory. Refer to them with RELATIVE
paths only — `solve.py`, `accounts.csv`, `txns/2024-01.log`. NEVER build an absolute path like
`/home/.../solve.py`: it is easy to mistype and Write will fail with PermissionDenied /
"File not found". The Write tool with a bare filename writes to the cwd, which is exactly what
you want. If any tool call with a leading `/` path fails, retry with the path made relative.

## Never dump large files into the terminal or context

The context window is only ~32k tokens. Dumping even one multi-thousand-line log to stdout
overflows it and crashes the run BEFORE any output file is written — you get nothing. This is
the #1 cause of total failure on log/WAL tasks. So:
- Check shape first: `wc -l <file>`, `ls -la <dir>`. Peek with `head -n 20` / `tail -n 20` only.
- Do NOT `cat`, `grep -n`, `grep -E`, `sed -n '1,$p'`, or `awk '{print}'` a big/whole file, and
  do NOT grep the logs to hunt for tricky/malformed lines — such a pattern matches a huge
  fraction of lines and floods the terminal. Your PARSER is the single source of truth: encode
  every validity/rejection rule in your script and let it classify each line as it reads.
- Need per-line NUMBERS for output like `FILENAME:LINE OP`? Compute them INSIDE your script with
  `enumerate(f, start=1)` (1-based, reset per file). Never print numbered lines.
- Verify with scripts, not by reading: `grep -c` (a COUNT), `diff`, `wc -l`, `python3 -c "..."`.

## Output artifact must match the spec exactly

The task is complete only when every required OUTPUT FILE exists with real content. Computing
the answer and printing it in your text response does NOT satisfy the task. Match any example
line field-for-field: same field count, same separators, same KIND of value per position, no
extra trailing fields. For a `FILENAME:LINE OP` format, FILENAME is the file's BASE NAME only
(`os.path.basename(path)` → `2024-01.log`, never `txns/2024-01.log`) and OP is just the
operation word. Before finishing, `head -n 3` each output file and check each field against the
spec's example.

## Log-replay / count tasks: run it and sanity-check the counts

For tasks that classify each line as valid vs malformed/rejected and report COUNTS, you MUST
actually RUN your script and check the numbers — never stop with the script written but unrun.
Real input is mostly well-formed, so malformed/rejected must be a SMALL fraction of the total.
If that count ≈ total lines, your check is inverted — debug it. Classic cause: inconsistent
newline stripping. Strip the newline exactly ONCE at the top (`line = line.rstrip("\n")`) and
run every field/whitespace/case check on that one normalized string. Before stopping: confirm
every required output file exists, is non-empty, and its counts are plausible.

## Ledger/replay tasks: the master account list is the only source of valid ids

When a fixed master file (e.g. `accounts.csv`) lists the accounts, a transaction naming an id
NOT in that list is REJECTED — for EVERY operation, including DEPOSIT. Do NOT use a
`defaultdict` or auto-create accounts on first reference: that both fails to reject the line and
gives a phantom account a balance, so later lines naming it get wrongly applied. Initialize your
balances dict with EXACTLY the master ids, and for every transaction first verify all ids it
names exist (reject if any is absent) before balance/self-transfer checks or applying anything.
Overdraft is strict but draining to exactly 0 is allowed; a TRANSFER with SRC == DST is rejected.

## Stub-implementation tasks: write real code, then run the tests

If the task says to implement/edit a stub so a provided test suite passes, it is done only when
you have replaced the stub with a full working implementation (a real Write/Edit) AND actually
RUN `python3 -m pytest -q` and seen every test pass. A stub left with `pass` /
`raise NotImplementedError` / `return None` is a total failure. Never end the turn right after
reading the stub and tests — write the implementation, run pytest, fix and re-run until green.

## SGF parser recipe (parse(input_string) -> SgfTree(properties, children))

The make-or-break part is the TREE/CHILD structure. Single recursive-descent pass over an index:
1. VALIDATION first, exact messages: empty string, or not starting with `(` →
   `raise ValueError("tree missing")`; a tree with no first node such as `"()"` →
   `raise ValueError("tree with no nodes")`; a KEY not all-uppercase →
   `raise ValueError("property must be in uppercase")`; a `[...]` value with no preceding key, or
   properties lacking a delimiter → `raise ValueError("properties without delimiter")`.
   Then strip the outer `(` `)` and parse the inside as a node sequence.
2. A NODE begins with `;`. After it read the KEY (run of letters, must be `.isupper()`), then read
   one OR MORE consecutive `[...]` groups — multiple `[..]` after one key are MULTIPLE VALUES
   (`AB[aa][ab][ba]` → `{"AB": ["aa","ab","ba"]}`). Repeat per key until you hit `;`, `(`, or end.
3. CHILDREN — the bug everyone hits:
   - A chained `;` right after a node → that node has exactly ONE child: parse the rest starting at
     that `;` into `children` (so `(;A[B];B[C])` → root `A[B]` with one child `B[C]`; a further
     `;C[D]` is that child's child — a single chain).
   - One or more `(...)` groups right after a node → that node's MULTIPLE children (variations):
     each balanced top-level `(...)` is ONE separate child subtree. So `(;A[B](;B[C])(;C[D]))` →
     root `A[B]` with TWO SIBLING children `B[C]` and `C[D]` (not nested, not flattened).
4. VALUE text inside `[...]`: `\` escapes — `\]`→`]`, `\\`→`\`, any NON-whitespace char after `\`
   is inserted as-is (`\t`→`t`, `\n`→`n`; SGF has no `\t`/`\n` whitespace escapes). `\` before a
   real newline deletes that newline (line continuation). Every whitespace char EXCEPT newline
   becomes a single space; real newlines stay `\n`. `[`, `;`, `(`, `)` inside a value need no escape.
After writing sgf_parsing.py, RUN `python3 -m pytest -q` and iterate until every test passes; do
not stop after only reading the stub and tests, and leave no scratch `print` debugging behind.
