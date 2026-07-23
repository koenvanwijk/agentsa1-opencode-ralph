#!/bin/bash
# For OpenCode the tunable profile (opencode.json + AGENTS.md) is injected into
# each task workdir by run_all.sh, so there is nothing to sync globally here.
# This step just validates the profile so a malformed proposer edit fails loud
# instead of silently breaking all 54 trials.
REPO="$(cd "$(dirname "$0")/.." && pwd)"
python3 -c "import json,sys; json.load(open('$REPO/oc_profile/opencode.json'))" \
  || { echo "apply_profile: oc_profile/opencode.json is not valid JSON" >&2; exit 1; }
[ -f "$REPO/oc_profile/AGENTS.md" ] || { echo "apply_profile: AGENTS.md missing" >&2; exit 1; }
echo "profile OK"
