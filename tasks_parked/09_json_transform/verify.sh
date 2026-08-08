#!/bin/bash
# verify.sh <workdir>
W="$1"
[ -f "$W/output.json" ] || { echo "no output.json"; exit 1; }
python3 - "$W" << 'PY'
import sys, json
w=sys.argv[1]
got=json.load(open(f"{w}/output.json"))
exp=[{"name":"ALICE","age":31},{"name":"BOB","age":26},{"name":"CAROL","age":42}]
assert got==exp, got
print("ok")
PY
