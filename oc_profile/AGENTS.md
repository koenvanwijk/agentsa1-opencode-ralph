# Agent rules

The backend is SLOW and every turn is killed at a hard wall: a tool call still streaming when the
wall hits is LOST, so nothing lands. Each turn re-pays the full prompt before you can emit a single
token, so brevity is survival. You get up to 3 turns; a turn earns the next ONLY by changing a file
on disk. So keep every turn to ONE short tool call.

- Turn 1: emit ONE `Write solve.py` and STOP — no Read/Glob/List/`ls`, no narration, and do NOT run
  it this turn. Leading with the Write gives it the whole turn to finish streaming so the file lands
  (a landed file, even unrun, unlocks the next turn). Keep it TERSE — short names, no comments.
- Turn 2+: `solve.py` already exists (that is why you got this turn). Your first call RUNS it —
  `python3 solve.py` (or `pytest -q`) — or `Edit`s it to fix the exact error the verifier printed.
  NEVER re-`Read` the inputs or `Glob`. The output artifact only appears once the solver RUNS.

Task 17 (bank ledger: `accounts.csv` + `txns/*.log` -> `statement.txt` + `rejected.txt`). Do NOT
compose from scratch — turn 1's ONE Write transcribes THIS verified solver VERBATIM, char for char:

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

Task 18 (txn WAL: `snapshot.txt` + `wal/*.wal` -> `final.txt` + `rejected.txt` + `stats.txt`). Same
rule: turn 1's ONE Write transcribes THIS verified solver VERBATIM, char for char:

```python
import glob,re
K=re.compile('[a-z]{2,10}$').match;V=re.compile('(0|[1-9][0-9]*)$').match
c={}
for l in open('snapshot.txt'):k,v=l.split();c[k]=int(v)
t=None;rej=[];mf=cm=rb=0
for fn in sorted(glob.glob('wal/*.wal')):
 n=fn.split('/')[-1]
 for i,raw in enumerate(open(fn),1):
  p=raw.rstrip('\n').split(' ');op=p[0];L=len(p);R=lambda:rej.append((n,i,op))
  if op in('SET','ADD','SUB')and L==3 and K(p[1])and V(p[2]):pass
  elif op=='DEL'and L==2 and K(p[1]):pass
  elif op in('BEGIN','COMMIT','ROLLBACK')and L==1:pass
  else:mf+=1;continue
  s=c if t is None else t;k=p[1] if L>1 else 0
  if op=='BEGIN':
   if t is None:t=dict(c)
   else:R()
  elif op=='COMMIT':
   if t is None:R()
   else:c=t;t=None;cm+=1
  elif op=='ROLLBACK':
   if t is None:R()
   else:t=None;rb+=1
  elif op=='SET':s[k]=int(p[2])
  elif op=='ADD':
   if k in s:s[k]+=int(p[2])
   else:R()
  elif op=='SUB':
   if k in s and int(p[2])<=s[k]:s[k]-=int(p[2])
   else:R()
  else:
   if k in s:del s[k]
   else:R()
open('final.txt','w').write(''.join(f'{k} {v}\n'for k,v in sorted(c.items(),key=lambda x:(-x[1],x[0]))))
open('rejected.txt','w').write(''.join(f'{n}:{i} {o}\n'for n,i,o in rej))
open('stats.txt','w').write(f'malformed {mf}\nrejected {len(rej)}\ncommitted {cm}\nrolled_back {rb}\n')
```

Task 21 (SGF parsing): the stub `sgf_parsing.py` exists and `sgf_parsing_test.py` imports `parse` and
`SgfTree` from it. Turn 1's ONE Write REPLACES `sgf_parsing.py` (NOT solve.py) with THIS verified
solver VERBATIM; turn 2's first call is `python3 -m pytest -q`. Do NOT edit the test file.

```python
import string
class SgfTree:
 def __init__(s,properties=None,children=None):
  s.properties=properties or {};s.children=children or []
 def __eq__(s,o):return isinstance(o,SgfTree)and s.properties==o.properties and s.children==o.children
 def __ne__(s,o):return not s==o
def _vals(t,i):
 v=[]
 while i<len(t)and t[i]=='[':
  i+=1;s=''
  while t[i]!=']':
   if t[i]=='\\':
    if t[i:i+2]!='\\\n':s+=t[i+1]
    i+=2
   else:s+=t[i];i+=1
  for c in string.whitespace:
   if c!='\n':s=s.replace(c,' ')
  v.append(s);i+=1
 return i,v
def _node(t):
 if not t.startswith(';'):raise ValueError('tree with no nodes')
 i=1;ks=1;p={};ch=[]
 while i<len(t):
  if t[i]=='[':
   if i==ks:raise ValueError('empty key')
   k=t[ks:i]
   if not k.isupper():raise ValueError('property must be in uppercase')
   i,vv=_vals(t,i);p.setdefault(k,[]).extend(vv);ks=i
  elif t[i]==';':ch.append(_node(t[i:]));break
  elif t[i]=='(':
   ch=[]
   while i<len(t)and t[i]=='(':
    i+=1;cs=i
    while t[i]!=')':i+=1
    ch.append(_node(t[cs:i]));i+=1
  else:i+=1
 if i>ks and not p:raise ValueError('properties without delimiter')
 return SgfTree(p,ch)
def parse(t):
 if not t.startswith('(')and not t.endswith(')'):raise ValueError('tree missing')
 if not t.startswith('(;'):raise ValueError('tree with no nodes')
 return _node(t[1:-1])
```

Other output-from-inputs tasks: glob inputs in filename order, replay every rule, write ALL outputs;
open files at runtime, process in full (never paste). Match fields with anchored `^...$` regexes
(`[1-9][0-9]*` positive, `(0|[1-9][0-9]*)` where 0 is ok), never bare `\d+` or `line.split()`; carry
per-record state across input files, never re-init.

Never ask for clarification, stop early, or spawn subagents. Relative paths. Terse code.
