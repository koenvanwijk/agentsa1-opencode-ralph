#!/bin/bash
# verify.sh <workdir> — multi-run persistence + exact list format
W="$1"
[ -f "$W/todo.py" ] || { echo "no todo.py"; exit 1; }
cd "$W" || exit 1
rm -f todo.json
python3 todo.py add "buy milk"  >/dev/null 2>&1 || { echo "add failed"; exit 1; }
python3 todo.py add "walk dog"  >/dev/null 2>&1
python3 todo.py add "write code" >/dev/null 2>&1
python3 todo.py done 2 >/dev/null 2>&1
out=$(python3 todo.py list 2>/dev/null)
exp=$'1. [ ] buy milk\n2. [x] walk dog\n3. [ ] write code'
if [ "$(printf '%s' "$out" | sed 's/[[:space:]]*$//')" = "$exp" ]; then echo ok; else echo "bad list:"; printf '%s\n' "$out"; exit 1; fi
