#!/bin/bash
# Run every task through OpenCode TRIALS times (default 3) in isolated workdirs.
# Each workdir gets the tunable oc_profile/ (opencode.json + AGENTS.md) so the
# harness config and injected rules are exactly what the proposer is tuning.
# Task x trial jobs run PARALLEL_JOBS at a time (default 4) since the DeepSeek
# backend supports continuous batching and multiple in-flight requests scale
# throughput well beyond one-at-a-time.
REPO="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"
TRIALS="${TRIALS:-3}"
MODEL="${OC_MODEL:-agentsa1/Agents-A1}"
PARALLEL_JOBS="${PARALLEL_JOBS:-4}"

run_one(){
  local t="$1" k="$2"
  local name; name=$(basename "$t")
  local out="$REPO/runs/current/$name/trial$k"
  rm -rf "$out"; mkdir -p "$out"
  [ -d "$t/seed" ] && cp -a "$t/seed/." "$out/" 2>/dev/null || true
  # inject the tuned profile into the workdir (project-local opencode config)
  cp "$REPO/oc_profile/opencode.json" "$out/opencode.json"
  cp "$REPO/oc_profile/AGENTS.md" "$out/AGENTS.md"
  timeout 900 opencode run --dir "$out" -m "$MODEL" "$(cat "$t/prompt.txt")" \
    > "$out/_oc_stdout.txt" 2>&1
  # remove profile files so verify.sh only sees task artifacts
  rm -f "$out/opencode.json" "$out/AGENTS.md"
  echo "done $name trial$k"
}
export -f run_one
export REPO MODEL

jobs_file=$(mktemp)
for t in "$REPO"/tasks/*/; do
  for k in $(seq 1 "$TRIALS"); do
    printf '%s\t%s\n' "$t" "$k" >> "$jobs_file"
  done
done

xargs -a "$jobs_file" -P "$PARALLEL_JOBS" -L 1 bash -c 'run_one "$0" "$1"'
rm -f "$jobs_file"

for t in "$REPO"/tasks/*/; do
  name=$(basename "$t")
  echo "ran $name x$TRIALS"
done
