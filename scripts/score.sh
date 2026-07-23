#!/bin/bash
# Score all tasks over TRIALS runs. A task PASSES if a MAJORITY of trials pass.
# SCORE.txt also records per-task trial counts so the proposer sees flakiness.
REPO="$(cd "$(dirname "$0")/.." && pwd)"
TRIALS="${TRIALS:-3}"
need=$(( TRIALS/2 + 1 ))
pass=0; total=0; detail=""
for t in "$REPO"/tasks/*/; do
  name=$(basename "$t"); total=$((total+1)); tp=0
  for k in $(seq 1 "$TRIALS"); do
    bash "$t/verify.sh" "$REPO/runs/current/$name/trial$k" >/dev/null 2>&1 && tp=$((tp+1))
  done
  if [ "$tp" -ge "$need" ]; then v=PASS; pass=$((pass+1)); else v=FAIL; fi
  detail="${detail}${v} ${name} (${tp}/${TRIALS} trials)\n"
done
{ printf "SCORE: %d/%d  (task passes if >=%d of %d trials pass)\n" "$pass" "$total" "$need" "$TRIALS"; printf "%b" "$detail"; } | tee "$REPO/runs/current/SCORE.txt"
echo "$pass" > "$REPO/runs/current/SCORE_NUM.txt"
