#!/bin/bash
# verify.sh <workdir> — exit 0 = pass
W="$1"
[ -f "$W/result.txt" ] || { echo "no result.txt"; exit 1; }
got=$(tr -d '[:space:]' < "$W/result.txt")
[ "$got" = "200" ] || { echo "result=$got expected 200"; exit 1; }
echo "ok"
