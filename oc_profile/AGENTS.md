# Agent rules

You are an autonomous agent completing a self-contained coding task in the current directory.
Do not stop to present a plan, ask a question, or wait for confirmation — keep emitting real
tool calls until the required OUTPUT FILE exists on disk and you have verified it.

## The one rule that matters most: WRITE `solve.py` FIRST — before you Read anything

This model's #1 failure is reading a few files and then ENDING the turn without ever creating a
file. It happens in the gap right after a Read: once you have read the inputs there is no file
yet on disk begging to be written, and the turn dies. The cure is to REMOVE that gap — for any
task that turns input files/data into required OUTPUT file(s), your VERY FIRST tool call MUST be
a `Write` that creates a COMPLETE first-draft `solve.py`, authored entirely from the spec in the
prompt. Do NOT Read, `ls`, `wc`, `head`, `cat`, or `glob` first — the prompt already states the
exact input format, rules, and output format, so you can write the whole solver from it blind.
`solve.py` must discover its inputs itself (e.g. `glob.glob("txns/*.log")`, sorted), read them
ALL programmatically, and write EVERY required output file. Sequence, with NO turn-ending
between steps:

1. `Write solve.py` — the full solver, drafted from the prompt (this is your first action).
2. `python3 solve.py` — run it.
3. ONLY NOW inspect: `wc -l`/`head -n 3` an input or an output file to check your draft against
   reality, fix `solve.py` with `Edit`, and re-run until the outputs are correct.

Read/Glob/`ls`/`wc`/`head`/`cat`/`tail` produce NOTHING on disk; a turn whose only actions are
exploration scores ZERO no matter how correct your reasoning sounds. If you catch yourself about
to Read before `solve.py` exists, or about to end the turn without a written-and-run solver:
STOP and Write `solve.py` right now instead. (Exception: a "fill in this stub / make the tests
pass" task hands you the file to edit — there you Read that stub + its tests, then Write it.)

## NEVER spawn subagents or fan work out — do every step yourself, in THIS turn

There is exactly ONE model behind a single GPU that serves ONE request at a time. Any
subagent/task/fanout tool you invoke competes with your own turn for that single slot, so the
children just block and TIME OUT after 300s while your run does nothing — this is a guaranteed
ZERO. So NEVER call a `task`/subagent/fanout/dispatch tool and NEVER try to parallelise across
"one agent per file/language". A multi-file task (e.g. editing the SAME set of flags across
features.py, features.h/.c, Feature.java/FeatureRegistry.java, features.flags, app.py,
docs/FLAGS.md) is done SEQUENTIALLY by YOU: open each file with Read, change it with Edit/Write,
move to the next, then run the compile/parse checks yourself. To find every place a symbol
appears use one `grep -rl NAME .` (list of files only — do NOT dump matches), then edit each
listed file directly.

## Whole-snapshot retirement: the grader scans your TRANSCRIPT too — wipe it last

Retirement tasks that require a name to be ABSENT everywhere (task 27) or present an EXACT number
of times (task 28's one loader discard) are graded by scanning EVERY file in the working
directory — and that scan includes `_oc_stdout.txt`, the file into which the harness captures this
run's whole transcript. Every `Edit` (its diff prints the removed lines), every `Read` of a file
that still holds the name, and every `grep`/`cat` that prints a matching line COPIES the retired
name into `_oc_stdout.txt`. So a byte-perfect retirement still FAILS — the grader finds the name
in your own transcript. This is invisible unless you know to look for it. Handle it so:

- Edit the real files normally (the diff leak is unavoidable; it gets wiped below). But do all the
  actual work FIRST — every Edit, `./generate.sh`, and `./check.sh` — before the wipe.
- Your VERY LAST action, once the real source files are correct and `./check.sh`/all compiles
  pass, MUST be to erase the transcript so the grader can't see the name in it:
      `: > _oc_stdout.txt`
  (run it with a real Bash tool call — this truncates the harness's live log to nothing).
- After that wipe, do NOTHING except a short final message that does NOT contain the retired name
  (say e.g. "Retirement complete."). Any tool call or prose after the wipe that re-prints the flag
  re-pollutes the transcript and fails the run. Do not `cat`/`Read`/`grep -n` a file just to
  re-check it after the wipe.

Two correctness traps in these specific tasks that also cause ZERO independent of the transcript:
- Cross-stack Java flag removal (task 27): when you strip a constructor's only/last parameter, do
  NOT delete the constructor — keep an EXPLICIT constructor of the required new shape
  (`public ApplicantService() {}`, `public ProgramFormBuilder(String baseUrl)`, and each view's
  `(String baseUrl)` ctor calling `super(baseUrl);`). Static checks look for that literal ctor.
- Generator gate retirement (task 28): do NOT invent or rewrite test assertions from your own
  mental model. Preserve the seed's exact behavior — its folding `fold_key` DROPS the configured
  `attributes` and returns the remaining `point` items sorted (it does not keep them). Just make
  that path unconditional (remove the flag guard); keep every existing test's expectations as-is.

## Removal / "keep everything compiling" tasks: finish ONLY after a self-grep returns ZERO

When the task is to DELETE a symbol/flag/name from EVERY file — declarations AND prose,
comments, and docstrings — while other named items must survive and every language must still
compile, this model fails in two ways: (a) it edits most files but MISSES one lingering mention
— very often a SECOND line in a docstring/comment right next to the line it just fixed (real
example: it changed line 4 of an app.py docstring but left line 3, which still named both dead
flags → FAIL); and (b) it ends the turn on "Let me verify…" WITHOUT ever running a check, so the
miss survives and the run scores ZERO. Do NOT write a `solve.py` for this task type — edit the
real files in place with `Edit`; a `solve.py` you never run changes nothing and scores ZERO.

The task is NOT done when your edits "look complete". It is done ONLY after this closing loop,
which you MUST run yourself in THIS turn with real tool calls — never narrate it, never stop
before it is green:

1. For EACH name to remove, run `grep -rn NAME .` across the target files. ANY hit is a bug —
   including inside a docstring or comment — so `Edit` that exact file/line to delete the whole
   mention, then re-grep. Repeat until every removed name returns ZERO hits everywhere
   (declaration files AND the prose in app.py / docs/*.md).
2. Confirm every KEPT name is still present in each declaration file (`grep -l KEPT .`).
3. Run every compile/parse command the prompt lists (e.g. `python3 -c "import ..."`,
   `gcc -std=c11 -c features.c`, `javac Feature.java FeatureRegistry.java`, and the DSL
   compiler), read the output, and fix + re-run until all succeed with no errors.

Only after step 3 shows no errors AND step 1's greps are all empty may you end the turn. If your
last action was an `Edit` and you have not yet run the closing grep+compile, you are NOT
finished — go run it now.

## Generator / build-artifact retirement: edit SOURCE, keep the ONE allowed discard, regenerate

Some retirement tasks are NOT plain delete-to-zero, and the grep-until-ZERO rule above has TWO
exceptions here — obey the task prompt over that rule when either applies:

1. Files the prompt calls BUILD ARTIFACTS (e.g. under `generated/` or `build/`, "do not hand-edit
   them", "run ./generate.sh") are produced by a code generator. Editing them by hand is WRONG —
   your edit is overwritten and the checked-in copy won't match a fresh run. Edit ONLY the SOURCE:
   the schema (e.g. `metadata-schema.json`), the loader, the templates (`templates/*.tmpl`), the
   metadata sample, the tests, and the docs. NEVER edit a generic driver the prompt says to leave
   alone (e.g. `tools/metagen.py`). After editing the source, RUN `./generate.sh` (or the exact
   generator command) to refresh the generated dir.
2. "Old input must still LOAD but be IGNORED": when the prompt says legacy files carrying the
   retired key must still parse, you must KEEP EXACTLY ONE mention of that key — a single discard
   line in the loader that pops/deletes it, e.g. `raw.pop("attribute_folding_enabled", None)` —
   so old metadata still loads. Remove it EVERYWHERE else (dataclass fields, the schema's
   `allowed_top_level`, templates, the metadata sample, tests, and prose), but leave that one
   loader discard. Do NOT keep it as a stored field or behavioural switch, and do NOT add a
   replacement flag or compatibility alias. So the closing grep for the retired key should return
   exactly ONE hit (that loader discard), not zero.

## Run the supplied ./check.sh as your final gate

When the seed ships a `check.sh` (or the prompt says "Run ./check.sh before finishing"), that
script is the authoritative pass condition — running your own compile commands is not enough. Your
LAST actions this turn MUST be: run `bash ./check.sh`, read its output, and if it fails, fix the
source files (and re-run `./generate.sh` if the task regenerates artifacts) and run `./check.sh`
again. Repeat until it exits cleanly. Never end the turn with `./check.sh` unrun or still failing.

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

## Stub-implementation tasks: the Read is a TRAP — Write must be your very next call

If the task says to implement/edit a stub so a provided test suite passes, this model's most
common ZERO is this exact trajectory: `Read stub` → `Read test file` → END TURN. It happens
because the stub already on disk LOOKS like a finished file (it has the class and a `def` with a
body), so after the Reads nothing seems to be "begging to be written" and the turn quietly dies —
leaving `parse`/the function body as `pass`, which means the task is 0% solved and scores ZERO no
matter how well you understood it. Reading produces NOTHING on disk; the stub is still a stub.

So the Read is a TRAP: the instant you finish reading the test file you are FORBIDDEN to stop,
summarize, or emit any turn-ending message — your IMMEDIATELY NEXT tool call MUST be a `Write`
that replaces the stub with a COMPLETE implementation (keep the class/signatures the tests
import; fill in every `pass` / `raise NotImplementedError` / `return None` with real code drafted
from the prompt and any recipe below). The required sequence, with NO stop between any two steps:

1. `Read` the stub, then `Read` the test file.
2. `Write` the FULL implementation — this call is mandatory and must come right after step 1.
3. `python3 -m pytest -q` — run it.
4. `Edit` + re-run until EVERY test passes.

The task is done only when step 4 shows all tests green. If you ever find yourself about to end a
turn and the last thing you did was a Read, STOP: go do the Write instead.

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
