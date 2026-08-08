#!/bin/bash
# Run every task through OpenCode TRIALS times (default 3) in isolated workdirs.
# Each workdir gets the tunable oc_profile/ (opencode.json + AGENTS.md) so the
# harness config and injected rules are exactly what the proposer is tuning.
# Task x trial jobs run PARALLEL_JOBS at a time. TUNABLE via the env var.
REPO="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"
TRIALS="${TRIALS:-3}"
MODEL="${OC_MODEL:-agentsa1/Agents-A1}"
PARALLEL_JOBS="${PARALLEL_JOBS:-2}"
RUN_LABEL="${RALPH_RUN_LABEL:-manual}"
safe_label=$(printf '%s' "$RUN_LABEL" | tr -cs '[:alnum:]_.-' '-')
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-${safe_label}-p${PARALLEL_JOBS}-$$"
METRICS_ROOT="${GPU_METRICS_ROOT:-$REPO/runs/metrics}"
METRICS_DIR="$METRICS_ROOT/$RUN_ID"
RUN_STARTED_EPOCH=$(date +%s)
mkdir -p "$METRICS_DIR"

{
  printf 'run_id=%q\n' "$RUN_ID"
  printf 'label=%q\n' "$RUN_LABEL"
  printf 'started_at=%q\n' "$(date -Is)"
  printf 'parallel_jobs=%q\n' "$PARALLEL_JOBS"
  printf 'trials=%q\n' "$TRIALS"
  printf 'model=%q\n' "$MODEL"
  printf 'task_count=%q\n' "$(find "$REPO/tasks" -mindepth 1 -maxdepth 1 -type d | wc -l)"
} > "$METRICS_DIR/run.env"

run_one(){
  local t="$1" k="$2"
  local name; name=$(basename "$t")
  local out="$REPO/runs/current/$name/trial$k"
  rm -rf "$out"; mkdir -p "$out"
  [ -d "$t/seed" ] && cp -a "$t/seed/." "$out/" 2>/dev/null || true
  if [ -f "$t/solve.sh" ]; then
    # per-task solver OVERRIDE (e.g. tier-B subagent fan-out). It manages its own
    # harness profile(s) per subagent, so no top-level profile is injected here.
    timeout 1800 bash "$t/solve.sh" "$out" > "$out/_oc_stdout.txt" 2>&1
  else
    # default: one opencode run over the whole task with the tuned profile
    cp "$REPO/oc_profile/opencode.json" "$out/opencode.json"
    cp "$REPO/oc_profile/AGENTS.md" "$out/AGENTS.md"
    timeout 900 opencode run --dir "$out" -m "$MODEL" "$(cat "$t/prompt.txt")" \
      > "$out/_oc_stdout.txt" 2>&1
    # remove profile files so verify.sh only sees task artifacts
    rm -f "$out/opencode.json" "$out/AGENTS.md"
  fi
  echo "done $name trial$k"
}
export -f run_one
export REPO MODEL

jobs_file=$(mktemp)
trap 'rm -f "$jobs_file"' EXIT
for t in "$REPO"/tasks/*/; do
  for k in $(seq 1 "$TRIALS"); do
    printf '%s\t%s\n' "$t" "$k" >> "$jobs_file"
  done
done

bash "$REPO/scripts/with_gpu_metrics.sh" "$METRICS_DIR" -- \
  xargs -a "$jobs_file" -P "$PARALLEL_JOBS" -L 1 bash -c 'run_one "$0" "$1"'
run_rc=$?
rm -f "$jobs_file"
trap - EXIT

{
  printf 'finished_at=%q\n' "$(date -Is)"
  printf 'duration_seconds=%q\n' "$(( $(date +%s) - RUN_STARTED_EPOCH ))"
  printf 'command_exit_code=%q\n' "$run_rc"
} >> "$METRICS_DIR/run.env"
ln -sfn "$RUN_ID" "$METRICS_ROOT/latest"

for t in "$REPO"/tasks/*/; do
  name=$(basename "$t")
  echo "ran $name x$TRIALS"
done
echo "gpu metrics: $METRICS_DIR"
exit "$run_rc"

