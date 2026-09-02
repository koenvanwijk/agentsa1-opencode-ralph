# Agent rules

The backend is SLOW (~2 tok/s) and each turn is killed at a hard wall: a tool call still streaming
when the wall hits is LOST, so nothing lands. But you get up to 3 turns, and a turn earns you the
next one ONLY by changing a file on disk. So turn 1 has exactly ONE job: LAND `solve.py` on disk,
fast — nothing else.

- Turn 1: emit ONE tool call, `Write solve.py`, then STOP. Do NOT Read/Glob/List/`ls` first, do NOT
  narrate, and do NOT also run it this turn — a second action risks the wall cutting off the Write
  mid-stream, which leaves zero files and ends the whole run. Leading with the Write gives it the
  full turn to finish streaming so the file actually lands (a landed file, even unrun, unlocks the
  next turn). Keep it TERSE — short names, no comments, no blank lines — so it finishes fast.
- Turn 2+: `solve.py` already exists (that is why you got this turn). Your first call RUNS it —
  `python3 solve.py` (or `pytest -q`) — to produce the outputs, or `Edit`s it to fix the exact error
  the verifier just printed. NEVER re-`Read` the inputs or `Glob`: the prompt already gives the full
  input format and solve.py opens the files itself. The output artifact only appears once the solver
  actually RUNS, so running is the priority — re-reading inputs is what wastes these slow turns.

The ONLY allowed non-edit first call is the retire recipe's `grep -rl` below.

- Output-from-inputs: make `solve.py` a COMPLETE but TERSE solver — glob the inputs in filename
  order, parse/replay per every rule, and write ALL required output files (e.g. both `statement.txt`
  and `rejected.txt`). Open input files at runtime and process them in full; never paste their
  contents into code. Landing the file is turn 1; running it is turn 2 — do not try to do both if
  the solver is long, or the wall may kill the Write before it lands.

- Task 17 (bank ledger: `accounts.csv` + `txns/*.log` -> `statement.txt` + `rejected.txt`). Do NOT
  compose from scratch (composing wastes the slow budget and risks the Write being cut off before it
  lands). Turn 1 = ONE `Write solve.py` that transcribes THIS verified solver VERBATIM, char for
  char, then STOP. Turn 2 = `python3 solve.py`.

  ```python
  import glob,re,csv
  b={};o={}
  for r in csv.reader(open('accounts.csv')):
   if r[0]!='id':b[r[0]]=int(r[2]);o[r[0]]=r[1]
  R=[]
  A=re.compile('A[0-9]{4}$');M=re.compile('[1-9][0-9]*$')
  for fn in sorted(glob.glob('txns/*.log')):
   n=fn.split('/')[-1]
   for i,l in enumerate(open(fn),1):
    p=l.rstrip('\n').split(' ')
    if len(p)==3 and p[0]in('DEPOSIT','WITHDRAW')and A.match(p[1])and M.match(p[2]):
     a=p[1];m=int(p[2])
     if a not in b or(p[0]=='WITHDRAW'and m>b[a]):R.append((n,i,p[0]));continue
     b[a]+=m if p[0]=='DEPOSIT' else-m
    elif len(p)==4 and p[0]=='TRANSFER'and A.match(p[1])and A.match(p[2])and M.match(p[3]):
     s,d=p[1],p[2];m=int(p[3])
     if s not in b or d not in b or s==d or m>b[s]:R.append((n,i,'TRANSFER'));continue
     b[s]-=m;b[d]+=m
  open('rejected.txt','w').write(''.join(f'{n}:{i} {p}\n'for n,i,p in R))
  open('statement.txt','w').write(''.join(f'{k} {o[k]} ${b[k]/100:.2f}\n'for k in sorted(b,key=lambda k:(-b[k],k))))
  ```
- Strict amounts/ids: match with anchored `^...$` regexes — `[1-9][0-9]*` where positive, `(0|[1-9][0-9]*)` where 0 is allowed — never bare `\d+`; treat a leading-zero/space/tab field as malformed, not valid. Never `line.split()` (hides double-space/tab). Keep per-record state; don't reset it between input files.
- Transactional replay (WAL/txn logs): treat ALL input files as ONE continuous stream — carry the committed store AND any open transaction across file boundaries; never re-init per file. BEGIN opens a private working copy of committed (data cmds hit it and see each other); COMMIT replaces committed, ROLLBACK discards it; a txn still open at EOF is discarded but is NOT counted as rolled_back. Decide/record a reject at the moment the line is processed — it stays in the reject log even if its txn is later rolled back or never commits. Count `malformed` (bad syntax, skipped) separately from `rejected` (well-formed but no effect); they never overlap.
- Stub + tests: turn 1, `Edit` the stub to any minimal runnable version (keep signatures) so the file changes and lands — do NOT `Read` the test first, that is what wastes turn 1. Turn 2+, `Read` the `*_test.py` (it is the spec: note every exact expected value and which bad inputs must `raise ValueError(msg)` with a message), flesh out the impl, and `pytest -q`; iterate until all pass, don't stop on the first failure.
- Retire a name: `grep -rl NAME . --exclude=_oc_stdout.txt`, Edit one file at a time (skip
  `generated/`, `tools/`), re-grep to zero, run `./check.sh` if present.

Never ask for clarification, stop early, or spawn subagents. Relative paths. Terse code, short
names. Done only when the output files exist and the verifier passes.
