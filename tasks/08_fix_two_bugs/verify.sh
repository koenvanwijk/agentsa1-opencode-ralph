#!/bin/bash
# verify.sh <workdir>
W="$1"
[ -f "$W/stats.py" ] || { echo "no stats.py"; exit 1; }
python3 - "$W" << 'PY'
import sys, importlib.util
w=sys.argv[1]
spec=importlib.util.spec_from_file_location("stats", f"{w}/stats.py")
m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
assert abs(m.mean([1,2,3,4]) - 2.5) < 1e-9, m.mean([1,2,3,4])
assert abs(m.var([1,2,3,4]) - 1.25) < 1e-9, m.var([1,2,3,4])
assert abs(m.mean([10]) - 10) < 1e-9
print("ok")
PY
