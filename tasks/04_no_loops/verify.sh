#!/bin/bash
# verify.sh <workdir> — correctness AND the no-loop/no-sum constraint
W="$1"
[ -f "$W/noloop.py" ] || { echo "no noloop.py"; exit 1; }
grep -qE '\bfor\b|\bwhile\b' "$W/noloop.py" && { echo "uses a loop"; exit 1; }
grep -qE '\bsum\s*\(' "$W/noloop.py" && { echo "uses sum()"; exit 1; }
python3 - "$W" << 'PY'
import sys, importlib.util
w=sys.argv[1]
spec=importlib.util.spec_from_file_location("noloop", f"{w}/noloop.py")
m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
assert m.total([1,2,3,4])==10
assert m.total([])==0
assert m.total([5])==5
print("ok")
PY
