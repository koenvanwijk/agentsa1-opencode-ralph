#!/bin/bash
# verify.sh <workdir> — correctness + edge cases (n<=0 raises, empty list)
W="$1"
[ -f "$W/chunk.py" ] || { echo "no chunk.py"; exit 1; }
python3 - "$W" << 'PY'
import sys, importlib.util
w=sys.argv[1]
spec=importlib.util.spec_from_file_location("chunk", f"{w}/chunk.py")
m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
assert m.chunk([1,2,3,4,5],2)==[[1,2],[3,4],[5]]
assert m.chunk([],3)==[]
assert m.chunk([1,2],5)==[[1,2]]
assert m.chunk([1,2,3],1)==[[1],[2],[3]]
for bad in (0,-1):
    try:
        m.chunk([1,2,3], bad); raise AssertionError(f"n={bad} should raise ValueError")
    except ValueError:
        pass
print("ok")
PY
