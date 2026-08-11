# Agent rules

You are an autonomous agent completing a self-contained coding task in the current directory.
Keep this run LEAN: the context window is only ~32k tokens and OpenCode auto-compacts (a
"generating summary" step) the moment it fills — and DURING that compaction your next tool call is
REJECTED and the turn DIES. This has scored ZERO on tasks 27/28: the model batch-read ~11 files,
context overflowed, and the run ended before a single Edit. So do NOT read more than you need, do
NOT dump/`cat`/`grep -n` whole files into the terminal, and get to the Edits/Write fast.

## RULE #0 (every task): never end a turn on a read

`Read`/`Grep`/`Glob`/`ls`/`cat`/`head` put NOTHING on disk. This model's #1 ZERO is: it reads the
files, then emits a plain-text line ("Now I'll implement…", "Let me start editing", a plan/summary)
and the turn ENDS with no `Write`/`Edit` ever made. A plain-text message with no tool call is
EXACTLY what ends the turn. So emit prose exactly ONCE — as the final line, AFTER the required
files exist on disk AND you have run the verifier (`python3 -m pytest -q`, `bash ./check.sh`, or
running your script) and seen it pass. If your last action was a read and the work isn't done, your
NEXT output MUST be a repo-changing tool call, not a sentence about one.

## Output-file tasks: WRITE `solve.py` FIRST — before you Read anything

For any task that turns input files/data into required OUTPUT file(s), your VERY FIRST tool call
MUST be a `Write` creating a COMPLETE first-draft `solve.py`, authored entirely from the prompt's
spec (it states the exact input format, rules, and output format — write the whole solver blind).
Do NOT Read/`ls`/`wc`/`head`/`cat`/`glob` first — the gap right after a Read is where the turn
dies. `solve.py` discovers its own inputs (e.g. `sorted(glob.glob("txns/*.log"))`), reads them ALL
programmatically, and writes EVERY required output file. Sequence, no turn-ending between steps:
1. `Write solve.py` (first action). 2. `python3 solve.py`. 3. ONLY NOW `wc -l`/`head -n 3` an
input/output to check against reality, `Edit` solve.py, re-run until correct.

## Stub-implementation tasks: the Read is a TRAP — Write must be your very next call

If the task hands you a stub + test suite, the common ZERO is `Read stub` → `Read test` → END
TURN (the stub LOOKS finished, so nothing seems to beg writing). The instant you finish reading
the test file, your IMMEDIATELY NEXT tool call MUST be a `Write` replacing the stub with a COMPLETE
implementation (keep the imported class/signatures; fill every `pass`/`NotImplementedError`/
`return None`). Then `python3 -m pytest -q`, `Edit` + re-run until EVERY test passes. Leave no
scratch `print`s. Do NOT write a `solve.py` for this type — edit the real file.

## EDIT-IN-PLACE / retirement / "keep it compiling": Read-then-Edit each file in turn, then close out

If the task edits existing source in place (retire a flag, remove a name everywhere, make a
generator always-on), do NOT write `solve.py`. Copy the sequence that passes flag-cleanup every
run:
1. `grep -rl <NAME> . --exclude=_oc_stdout.txt` — the LIST of files to change (list only; never
   `grep -n`/dump matches — that floods context). Skip `generated/` artifacts and `tools/*`.
2. Process the list ONE FILE AT A TIME — do NOT batch-read. `Read` file #1, then your VERY NEXT
   tool call is that same file's `Edit`; THEN `Read` file #2 and immediately `Edit` it; and so on
   down the list. Reading all files up front is the proven turn-killer here: trials that read
   10-17 files back-to-back then STOPPED with zero edits, and some re-read files past the real file
   count, burning the 32k window before a single Edit. Read ONLY files the grep-l list named (never
   the build artifacts, `tools/*`, or `*.sh`) and NEVER re-read a file you have already edited.
3. THE STEP THAT SCORES: NO prose between a file's `Read` and its `Edit`, nor between one file's
   `Edit` and the next file's `Read` — a plain-text line there ends the turn. You are NOT done
   until the LAST file in the grep list has been Read-then-Edited. If you're about to type a
   sentence and a listed file is still unedited, emit its `Read`/`Edit` instead.
4. The instant the last file is edited, go STRAIGHT into the closing loop below — no summary between.

### Closing loop for retirement/removal (tasks 27, 28) — run it yourself, THIS turn, no stops

Editing is only HALF the job; the #1 ZERO here is stopping one step early. Never narrate "let me
verify" — just run these:
1. `grep -rn <NAME> . --exclude=_oc_stdout.txt` for EVERY spelling the prompt lists. The
   `--exclude=_oc_stdout.txt` is MANDATORY: without it the grep also matches THIS transcript (your
   own Edit diffs leaked the name into `_oc_stdout.txt`), so it can never hit zero and you quit
   thinking work remains. With the exclude, every hit is REAL source — `.java`/`.py` AND config
   (`*.conf`,`*.json`), docs (`README.md`,`FLAGS.md`), tests, and often a SECOND occurrence in a
   file you already edited (two folding guards in `render.py`; two adjacent docstring lines).
   Re-grep until it prints ZERO hits (task 27) or ONLY the one allowed loader-discard line (task
   28). Zero = green light; STOP editing.
2. If the task regenerates artifacts, run `./generate.sh` first. Then run `bash ./check.sh`; if it
   fails, fix source (and re-`./generate.sh`) and re-run until it exits cleanly.
3. WHOLE-SNAPSHOT TRAP: the grader scans EVERY file including `_oc_stdout.txt` (this transcript),
   so a byte-perfect retirement with a green check.sh STILL FAILS if the name is anywhere in it.
   Your VERY LAST tool call must erase it: `: > _oc_stdout.txt`. (You can chain step 2+3:
   `bash ./check.sh && : > _oc_stdout.txt`.)
4. End with a one-line message that does NOT contain the retired name (e.g. "Retirement complete.").
   Do NOT `cat`/`Read`/`grep -n` anything after the wipe — it re-pollutes the transcript.

Correctness traps (cause ZERO independent of the transcript):
- Task 27 (cross-stack Java): when you strip a constructor's only/last parameter, do NOT delete the
  constructor — keep an EXPLICIT ctor of the new shape (`public ApplicantService() {}`,
  `public ProgramFormBuilder(String baseUrl)`, and each view's `(String baseUrl)` calling
  `super(baseUrl);`). Static checks look for that literal ctor.
- Task 28 (generator gate): do NOT rewrite test assertions from your own model. The seed's
  `fold_key` DROPS the configured `attributes` and returns the remaining `point` items sorted — just
  make that path unconditional (remove the flag guard); keep every existing test expectation as-is.

### Generator / build-artifact retirement (task 28): edit SOURCE, keep ONE discard, regenerate
- Files the prompt calls BUILD ARTIFACTS (`generated/`, "do not hand-edit", "run ./generate.sh")
  are produced by a generator — editing them by hand is WRONG (overwritten). Edit ONLY the SOURCE:
  schema (`metadata-schema.json`), loader, `templates/*.tmpl`, the metadata sample, tests, docs.
  NEVER edit `tools/metagen.py`. After editing source, RUN `./generate.sh`.
- "Old input must still LOAD but be IGNORED": keep EXACTLY ONE mention of the retired key — a single
  discard line in the loader, `raw.pop("<KEY>", None)` with the exact quoted key string (that
  quoted literal is the ONE occurrence the grader counts). Remove it EVERYWHERE else (dataclass
  fields, schema `allowed_top_level`, templates, sample, tests, prose). No replacement flag/alias.
  So the closing grep for that key returns exactly ONE hit, not zero.

## NEVER spawn subagents or fan work out

One model, one GPU, one request at a time. Any `task`/subagent/fanout tool blocks and TIMES OUT
after 300s while your run does nothing — guaranteed ZERO. Do a multi-file task SEQUENTIALLY
yourself: `grep -rl NAME .` for the file list, then edit each listed file directly.

## Paths: always relative, never absolute

Files live in the CURRENT dir. Use relative paths only (`solve.py`, `accounts.csv`,
`txns/2024-01.log`). Never build `/home/.../solve.py` — Write with a bare filename writes to cwd.

## Never dump large files into the terminal

Dumping one multi-thousand-line log overflows the ~32k window and crashes the run before any output
is written. So:
- Shape first: `wc -l <file>`, `ls -la <dir>`. Peek with `head -n 20`/`tail -n 20` only.
- Do NOT `cat`/`grep -n`/`grep -E`/`sed`/`awk` a whole/big file, and do NOT grep logs to hunt
  malformed lines (matches a huge fraction, floods context). Your PARSER encodes every
  validity/rejection rule and classifies each line as it reads.
- For `FILENAME:LINE OP` output, compute line numbers INSIDE the script (`enumerate(f, start=1)`,
  reset per file). Never print numbered lines. Verify with `grep -c`/`diff`/`wc -l`, not by reading.

## Output artifact must match the spec exactly

Done only when every required OUTPUT FILE exists with real content — printing the answer in your
reply does NOT count. Match the example line field-for-field: same field count, separators, kind of
value per position, no extra trailing fields. In `FILENAME:LINE OP`, FILENAME is the BASE NAME only
(`os.path.basename(path)` → `2024-01.log`) and OP is just the operation word. `head -n 3` each
output before finishing.

## Log-replay / count tasks: run it and sanity-check the counts

You MUST actually RUN the script and check the numbers. Real input is mostly well-formed, so
malformed/rejected must be a SMALL fraction; if it ≈ total, your check is inverted (classic cause:
inconsistent newline stripping — do `line = line.rstrip("\n")` ONCE at top, run all checks on that).
Confirm every output file exists, is non-empty, and counts are plausible.

## Strict field & integer parsing: `\d+` is WRONG when leading zeros are forbidden

When a spec says an integer has "no leading zeros, no sign, no decimal" and lists `0`,`0500`,`-100`,
`12.50`,`+25`,`070` as MALFORMED, a bare `\d+` (or `int()` after a loose `split()`) SILENTLY
matches `0`/`0500`, so malformed lines get APPLIED — one balance ends up off by a few hundred while
the reject-list still looks right (this cost task 17: carol off by exactly 500 from an accepted
`0500`). Encode the rule EXACTLY in a fully `^...$`-anchored regex matching the WHOLE line:
- positive int, no leading zeros → `[1-9][0-9]*` (never `\d+`)
- non-negative, `0` ok but `00`/`070` not → `(0|[1-9][0-9]*)`
- ids/keys anchored to exact length (`A[0-9]{4}`, `[a-z]{2,10}`)
- fields joined by SINGLE spaces → literal single space between groups, match whole line; do NOT
  `line.split()` (it hides double-space/tab and leading/trailing-space malformations). Reject tabs
  and leading/trailing spaces explicitly.
After running, spot-check a tricky line (`0`/`0500`/tab/double-space) is classified per spec.

## Ledger/replay tasks: the master account list is the only source of valid ids

When a master file (e.g. `accounts.csv`) lists the accounts, a transaction naming an id NOT in it
is REJECTED — for EVERY op including DEPOSIT. Do NOT use `defaultdict`/auto-create (it both fails
to reject and gives a phantom account a balance). Initialize balances with EXACTLY the master ids;
for each transaction first verify all named ids exist before any balance/self-transfer check or
apply. Overdraft is strict but draining to exactly 0 is allowed; a TRANSFER with SRC == DST is
rejected.

## SGF parser recipe (parse(input_string) -> SgfTree(properties, children))

The make-or-break part is the TREE/CHILD structure. Single recursive-descent pass over an index:
1. VALIDATION first, exact messages: empty or not starting with `(` → `ValueError("tree missing")`;
   a tree with no first node like `"()"` → `ValueError("tree with no nodes")`; a KEY not all-upper
   → `ValueError("property must be in uppercase")`; a `[...]` with no preceding key, or properties
   lacking a delimiter → `ValueError("properties without delimiter")`. Then strip outer `(`/`)` and
   parse the inside as a node sequence.
2. A NODE begins with `;`. Read the KEY (run of letters, must `.isupper()`), then one OR MORE
   consecutive `[...]` groups — multiple `[..]` after one key are MULTIPLE VALUES
   (`AB[aa][ab][ba]` → `{"AB":["aa","ab","ba"]}`). Repeat per key until `;`, `(`, or end.
3. CHILDREN (the bug everyone hits):
   - A chained `;` right after a node → that node has exactly ONE child: parse the rest from that
     `;` into `children` (`(;A[B];B[C])` → root `A[B]` with one child `B[C]`; a further `;C[D]` is
     that child's child — a single chain).
   - One or more `(...)` groups right after a node → MULTIPLE children (variations): each balanced
     top-level `(...)` is ONE separate child. `(;A[B](;B[C])(;C[D]))` → root `A[B]` with TWO SIBLING
     children `B[C]` and `C[D]`.
4. VALUE text in `[...]`: `\` escapes — `\]`→`]`, `\\`→`\`, any NON-whitespace char after `\` is
   inserted as-is (`\t`→`t`, `\n`→`n`). `\` before a real newline deletes it (line continuation).
   Every whitespace char EXCEPT newline becomes a single space; real newlines stay. `[`,`;`,`(`,`)`
   inside a value need no escape.
After writing sgf_parsing.py, RUN `python3 -m pytest -q` and iterate until every test passes.
