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
OC_MAX_TURNS="${OC_MAX_TURNS:-3}"
OC_TURN_TIMEOUT="${OC_TURN_TIMEOUT:-900}"
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
  printf 'oc_max_turns=%q\n' "$OC_MAX_TURNS"
  printf 'oc_turn_timeout=%q\n' "$OC_TURN_TIMEOUT"
  printf 'task_count=%q\n' "$(find "$REPO/tasks" -mindepth 1 -maxdepth 1 -type d | wc -l)"
} > "$METRICS_DIR/run.env"

run_one(){
  local t="$1" k="$2"
  local name; name=$(basename "$t")
  local out="$REPO/runs/current/$name/trial$k"
  local transcript_dir="$REPO/runs/transcripts/$RUN_ID/$name/trial$k"
  rm -rf "$out"; mkdir -p "$out"
  mkdir -p "$transcript_dir"
  [ -d "$t/seed" ] && cp -a "$t/seed/." "$out/" 2>/dev/null || true
  if [ -f "$t/solve.sh" ]; then
    # per-task solver OVERRIDE (e.g. tier-B subagent fan-out). It manages its own
    # harness profile(s) per subagent, so no top-level profile is injected here.
    timeout 1800 bash "$t/solve.sh" "$out" > "$out/_oc_stdout.txt" 2>&1
  else
    # Give an incomplete solution bounded follow-up turns in the same workdir.
    # Every opencode invocation starts with fresh context; the files on disk and
    # the deterministic verifier output carry progress between turns.
    local prompt turn turn_rc verify_rc verify_excerpt
    prompt=$(cat "$t/prompt.txt")
    verify_rc=1
    for turn in $(seq 1 "$OC_MAX_TURNS"); do
      cp "$REPO/oc_profile/opencode.json" "$out/opencode.json"
      cp "$REPO/oc_profile/AGENTS.md" "$out/AGENTS.md"
      timeout "$OC_TURN_TIMEOUT" opencode run --dir "$out" -m "$MODEL" "$prompt" \
        > "$transcript_dir/turn$turn.txt" 2>&1
      turn_rc=$?

      # Profile and transcript files are harness state, not candidate artifacts.
      # Keep transcripts outside the workdir while verify.sh scans the snapshot.
      rm -f "$out/opencode.json" "$out/AGENTS.md" "$out/_oc_stdout.txt"
      bash "$t/verify.sh" "$out" > "$transcript_dir/verify$turn.txt" 2>&1
      verify_rc=$?
      if [ "$verify_rc" -eq 0 ]; then
        verify_rc=0
        : > "$out/_oc_stdout.txt"
        break
      fi

      verify_excerpt=$(tail -c 6000 "$transcript_dir/verify$turn.txt" 2>/dev/null)
      prompt=$(printf '%s\n\n%s\n%s\n%s\n' \
        'Continue the existing implementation in this same working directory.' \
        'The previous turn did not pass the deterministic verifier. Inspect the files already changed, fix the remaining issues, and run the required checks. Do not merely summarize or ask for clarification.' \
        "Previous OpenCode exit status: $turn_rc. Verifier output:" \
        "$verify_excerpt")
    done

    # Failed trajectories remain available at the historical path used by both
    # proposers. Successful snapshots keep this file empty so whole-tree gates
    # judge task artifacts rather than harness chatter; full logs stay archived.
    if [ "$verify_rc" -ne 0 ]; then
      {
        for turn in $(seq 1 "$OC_MAX_TURNS"); do
          [ -f "$transcript_dir/turn$turn.txt" ] || continue
          printf '\n===== OpenCode turn %s =====\n' "$turn"
          cat "$transcript_dir/turn$turn.txt"
          printf '\n===== verifier after turn %s =====\n' "$turn"
          cat "$transcript_dir/verify$turn.txt" 2>/dev/null || true
        done
      } > "$out/_oc_stdout.txt"
    fi
  fi
  echo "done $name trial$k"
}
export -f run_one
export REPO MODEL RUN_ID OC_MAX_TURNS OC_TURN_TIMEOUT

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
