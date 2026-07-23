#!/bin/bash
# Run every task through OpenCode TRIALS times (default 3) in isolated workdirs.
# Each workdir gets the tunable oc_profile/ (opencode.json + AGENTS.md) so the
# harness config and injected rules are exactly what the proposer is tuning.
REPO="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"
TRIALS="${TRIALS:-3}"
MODEL="${OC_MODEL:-agentsa1/Agents-A1}"
for t in "$REPO"/tasks/*/; do
  name=$(basename "$t")
  for k in $(seq 1 "$TRIALS"); do
    out="$REPO/runs/current/$name/trial$k"
    rm -rf "$out"; mkdir -p "$out"
    [ -d "$t/seed" ] && cp -a "$t/seed/." "$out/" 2>/dev/null || true
    # inject the tuned profile into the workdir (project-local opencode config)
    cp "$REPO/oc_profile/opencode.json" "$out/opencode.json"
    cp "$REPO/oc_profile/AGENTS.md" "$out/AGENTS.md"
    timeout 900 opencode run --dir "$out" -m "$MODEL" "$(cat "$t/prompt.txt")" \
      > "$out/_oc_stdout.txt" 2>&1
    # remove profile files so verify.sh only sees task artifacts
    rm -f "$out/opencode.json" "$out/AGENTS.md"
  done
  echo "ran $name x$TRIALS"
done
