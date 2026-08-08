#!/bin/bash
# Compare three cleanup strategies on task 26, each in a fresh workdir, then
# score with the deterministic gate (verify.sh). Runs the model, so it is SLOW —
# run it when the backend is free (e.g. when the ralph loop is not running).
#
#   monolith : one opencode run over the whole task (current baseline)
#   tierB    : deterministic fan-out — one opencode run per language/DSL,
#              each with a small isolated context (tools/fanout/fanout.py)
#   tierA    : one opencode run where the model self-delegates to per-language
#              subagents via opencode's task tool (tierA/ profile)
#
# Usage: ./experiment.sh [monolith|tierB|tierA ...]   (default: all three)
set -u
T="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$T/../.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"
MODEL="${OC_MODEL:-agentsa1/Agents-A1}"
OUT="${OUT:-$T/.experiment}"; mkdir -p "$OUT"

seed(){ local w="$1"; rm -rf "$w"; mkdir -p "$w"; cp -a "$T/seed/." "$w/"; }

run_monolith(){
  local w="$OUT/monolith"; seed "$w"
  cp "$REPO/oc_profile/opencode.json" "$w/"; cp "$REPO/oc_profile/AGENTS.md" "$w/"
  timeout 900 opencode run --dir "$w" -m "$MODEL" "$(cat "$T/prompt.txt")" >"$w/_oc.txt" 2>&1
  rm -f "$w/opencode.json" "$w/AGENTS.md"
}
run_tierB(){
  local w="$OUT/tierB"; seed "$w"
  python3 "$REPO/tools/fanout/fanout.py" --task "$T" --work "$w" >"$w/_fanout.txt" 2>&1
}
run_tierA(){
  local w="$OUT/tierA"; seed "$w"
  cp "$T/tierA/opencode.json" "$w/"; cp "$T/tierA/AGENTS.md" "$w/"
  timeout 900 opencode run --dir "$w" -m "$MODEL" "$(cat "$T/tierA/PROMPT.txt")" >"$w/_oc.txt" 2>&1
  rm -f "$w/opencode.json" "$w/AGENTS.md"
}

tiers=("$@"); [ ${#tiers[@]} -eq 0 ] && tiers=(monolith tierB tierA)
echo "tier      result  time"
for tier in "${tiers[@]}"; do
  t0=$SECONDS
  "run_$tier"
  dur=$((SECONDS - t0))
  if bash "$T/verify.sh" "$OUT/$tier" >/dev/null 2>&1; then res=PASS; else res=FAIL; fi
  printf "%-9s %-7s %ss\n" "$tier" "$res" "$dur"
done
echo "workdirs + logs under: $OUT"
