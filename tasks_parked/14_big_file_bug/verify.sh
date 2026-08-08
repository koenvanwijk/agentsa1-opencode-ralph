#!/bin/bash
# verify.sh <workdir> — the >= vs > boundary at 100 is the discriminator
W="$1"
[ -f "$W/inventory.py" ] || { echo "no inventory.py"; exit 1; }
python3 - "$W" << 'PY'
import sys, importlib.util
w=sys.argv[1]
spec=importlib.util.spec_from_file_location("inventory", f"{w}/inventory.py")
m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
f=m.price_after_discount
assert abs(f(100)-90.0)<1e-9, f(100)      # boundary: >= 100 -> 10%
assert abs(f(200)-180.0)<1e-9, f(200)
assert abs(f(50)-47.5)<1e-9, f(50)        # boundary: >= 50 -> 5%
assert abs(f(99)-94.05)<1e-9, f(99)
assert abs(f(49)-49)<1e-9, f(49)          # no discount
# other functions must be untouched / still working
assert m.fmt_money(9.5)=="$9.50"
print("ok")
PY
