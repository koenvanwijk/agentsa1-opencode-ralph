#!/bin/bash
# verify.sh <workdir> — independently exercise the Stack API
W="$1"
[ -f "$W/stack.py" ] || { echo "no stack.py"; exit 1; }
python3 - "$W" << 'PY'
import sys, importlib.util
w=sys.argv[1]
spec=importlib.util.spec_from_file_location("stack", f"{w}/stack.py")
m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
s=m.Stack()
assert s.is_empty() is True
s.push(1); s.push(2); s.push(3)
assert len(s)==3 and s.peek()==3 and s.is_empty() is False
assert s.pop()==3 and s.pop()==2 and len(s)==1 and s.pop()==1 and s.is_empty() is True
print("ok")
PY
