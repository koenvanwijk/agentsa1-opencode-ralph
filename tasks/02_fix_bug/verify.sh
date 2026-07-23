#!/bin/bash
# verify.sh <workdir> — exit 0 = pass
W="$1"
python3 - "$W" << 'PY'
import sys, importlib.util
w = sys.argv[1]
spec = importlib.util.spec_from_file_location("dedup", f"{w}/dedup.py")
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
assert m.dedup([3,1,3,2,1,2]) == [3,1,2], m.dedup([3,1,3,2,1,2])
assert m.dedup([]) == []
assert m.dedup([5,5,5]) == [5]
print("ok")
PY
