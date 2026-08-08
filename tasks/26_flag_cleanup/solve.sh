#!/bin/bash
# Tier-B fan-out solver for task 26. Picked up automatically by run_all.sh when
# present (its per-task solver override). $1 = the already-seeded workdir.
#
# Instead of one opencode run over Python+C+Java+DSL+docs at once, run ONE
# opencode subagent per language/DSL, each in an isolated workdir with only that
# part's files + a shared spec (small context), then merge the edits back.
# verify.sh then scores the merged result with the deterministic gate.
set -u
W="$1"
T="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$T/../.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"
export OC_MODEL="${OC_MODEL:-${MODEL:-agentsa1/Agents-A1}}"
export FANOUT_TIMEOUT="${FANOUT_TIMEOUT:-300}"   # per-subagent cap; 5 parts < outer 1800s
python3 "$REPO/tools/fanout/fanout.py" --task "$T" --work "$W"
