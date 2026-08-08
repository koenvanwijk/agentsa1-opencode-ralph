#!/bin/bash
# verify.sh <workdir> — the secret is near the END, testing full-file read
W="$1"
[ -f "$W/answer.txt" ] || { echo "no answer.txt"; exit 1; }
got=$(tr -dc '0-9' < "$W/answer.txt")
[ "$got" = "80475" ] || { echo "answer=$got expected 80475"; exit 1; }
echo "ok"
