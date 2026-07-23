#!/bin/bash
# verify.sh <workdir> — correctness AND the no-regex constraint
W="$1"
[ -f "$W/validate.py" ] || { echo "no validate.py"; exit 1; }
grep -qE '(^|[^a-zA-Z_])import[[:space:]]+re([^a-zA-Z_]|$)|from[[:space:]]+re[[:space:]]+import|\bre\.' "$W/validate.py" && { echo "uses re"; exit 1; }
python3 - "$W" << 'PY'
import sys, importlib.util
w=sys.argv[1]
spec=importlib.util.spec_from_file_location("validate", f"{w}/validate.py")
m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
T=["x@y.com","a.b@c.d.com","user@host.co"]
F=["x@ycom","x y@z.com","@y.com","xy.com","a@@b.com","a@b.","a@.com",".a@b.com",""]
for s in T: assert m.is_valid_email(s) is True, f"expected True: {s!r}"
for s in F: assert m.is_valid_email(s) is False, f"expected False: {s!r}"
print("ok")
PY
