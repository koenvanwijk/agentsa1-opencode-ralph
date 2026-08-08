#!/bin/bash
# Task-26 solver, invoked by run_all.sh when present. $1 = the seeded workdir.
#
# Tier-B fan-out (one opencode subagent per language/DSL) is EXPENSIVE: 5 extra
# model calls. On a single-GPU backend that serves ~one request at a time, doing
# that while the loop hammers other tasks just starves everyone into 300s
# timeouts. So the fan-out runs ONLY WHEN IT WON'T HARM:
#
#   FANOUT=1     -> always fan out          (dedicated / standalone runs)
#   FANOUT=0     -> never; always monolith  (cheap, one slot, like any task)
#   unset (auto) -> fan out only if the GPU has headroom right now; otherwise
#                   fall back to a single monolithic run. If headroom can't be
#                   confirmed, DON'T fan out (safe default).
#
# Tunables: FANOUT_GPU_HOST (default spark-480b), FANOUT_GPU_MAX (%util ceiling,
# default 20), FANOUT_TIMEOUT (per-subagent seconds, default 300).
set -u
W="$1"
T="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$T/../.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"
MODEL="${OC_MODEL:-${MODEL:-agentsa1/Agents-A1}}"

want_fanout(){
  case "${FANOUT:-auto}" in
    1) return 0 ;;
    0) return 1 ;;
    *) # AUTO: only when the GPU is near-idle (headroom) — else it harms the loop
       local host="${FANOUT_GPU_HOST:-spark-480b}" max="${FANOUT_GPU_MAX:-20}" u
       u=$(ssh -o BatchMode=yes -o ConnectTimeout=6 "$host" \
             "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits" \
             2>/dev/null | head -1 | tr -dc '0-9')
       [ -n "$u" ] && [ "$u" -le "$max" ] ;;
  esac
}

if want_fanout; then
  echo "[solve] tier-B fan-out (forced or GPU has headroom)"
  export OC_MODEL="$MODEL" FANOUT_TIMEOUT="${FANOUT_TIMEOUT:-300}"
  python3 "$REPO/tools/fanout/fanout.py" --task "$T" --work "$W"
else
  echo "[solve] monolithic single run (no GPU headroom / FANOUT=0) — not harming the loop"
  cp "$REPO/oc_profile/opencode.json" "$W/opencode.json"
  cp "$REPO/oc_profile/AGENTS.md" "$W/AGENTS.md"
  timeout 900 opencode run --dir "$W" -m "$MODEL" "$(cat "$T/prompt.txt")"
  rm -f "$W/opencode.json" "$W/AGENTS.md"
fi
