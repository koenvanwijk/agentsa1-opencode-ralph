#!/bin/bash
# Ralph loop for tuning Agents-A1 (spark-480b) via the OpenCode CLI.
#
#   baseline -> N rounds of (proposer edits oc_profile/ -> re-score (3 trials/task)
#               -> keep if score didn't drop, else roll back), commit+push each round.
#
# ADAPTIVE PROPOSER: prefer headless Claude Code. When Claude hits its session/
# quota limit, switch to the LOCAL proposer (Agents-A1 itself via
# local_propose.py) and probe Claude each round to switch back. Never stalls.
#
# Usage: ./ralph.sh [iterations]        (default 30)
REPO="$(cd "$(dirname "$0")" && pwd)"; cd "$REPO"
N="${1:-30}"
export PATH="$HOME/.local/bin:$PATH"
export TRIALS="${TRIALS:-3}"
PROP_PY="${PROP_PY:-$HOME/.openclaw/workspace/agents-a1-repro/.venv/bin/python}"
# PROPOSER=local forces the local (Agents-A1) proposer and NEVER invokes
# `claude -p` — no Claude usage credits are consumed. Default 'claude' keeps the
# adaptive behaviour (Claude primary, local fallback).
PROPOSER="${PROPOSER:-claude}"
log(){ echo "[$(date -Is)] $*" | tee -a "$REPO/ralph.log"; }

# Model-server health gate: no tuning signal exists when the backend is down.
MODEL_URL="$(python3 -c "import json;print(json.load(open('oc_profile/opencode.json'))['provider']['agentsa1']['options']['baseURL'])" 2>/dev/null)"
HEALTH_INTERVAL="${HEALTH_INTERVAL:-60}"
model_up(){ [ -n "$MODEL_URL" ] && curl -sf -m 10 "${MODEL_URL%/}/models" >/dev/null 2>&1; }
wait_for_model(){
  model_up && return 0
  log "model server ${MODEL_URL:-<unset>} unreachable — pausing round (retry every ${HEALTH_INTERVAL}s)"
  local waited=0
  until model_up; do
    sleep "$HEALTH_INTERVAL"; waited=$((waited+HEALTH_INTERVAL))
    [ $((waited % 600)) -eq 0 ] && log "still waiting for model server (${waited}s elapsed)"
  done
  log "model server recovered after ${waited}s — resuming"
}

claude_up(){ timeout 90 claude -p "reply with exactly OK" --dangerously-skip-permissions 2>/dev/null | grep -q OK; }

copilot_up(){ timeout 120 hermes -m "${HERMES_ALIAS:-ghe-copilot}" -z "reply with exactly OK" 2>/dev/null | grep -q OK; }

# A proposer log is a VALID proposal only if its first PROPOSAL line is not a
# parenthesised sentinel like "PROPOSAL: (copilot error)" / "(... no-op ...)".
proposal_valid(){
  case "$(grep -m1 '^PROPOSAL:' "$1" 2>/dev/null)" in
    "PROPOSAL: ("*|"") return 1;;
    "PROPOSAL: "*)     return 0;;
    *)                 return 1;;
  esac
}

propose_claude(){  # $1=iter ; returns 0 ok, 1 quota/failure
  local logf="runs/proposer_$1.log"
  timeout 900 claude -p "$(cat proposer/PROPOSER.md)" \
    --dangerously-skip-permissions --add-dir "$REPO" > "$logf" 2>&1
  local rc=$?
  grep -qiE "session limit|usage limit|spend limit|monthly spend|credit balance|rate.?limit|invalid api key|please run /login|quota" "$logf" && return 1
  [ $rc -eq 0 ] && [ -s "$logf" ]
}

propose_local(){  # $1=iter ; uses Agents-A1 itself
  "$PROP_PY" local_propose.py > "runs/proposer_$1.log" 2>&1 || echo "PROPOSAL: (local error)" >> "runs/proposer_$1.log"
}

propose_copilot(){  # $1=iter ; Claude Sonnet 5 via Copilot. Returns 0 iff a valid proposal was produced.
  local logf="runs/proposer_$1.log"
  PROPOSER_ENGINE=copilot HERMES_ALIAS="${HERMES_ALIAS:-ghe-copilot}" \
    "$PROP_PY" local_propose.py > "$logf" 2>&1 \
    || echo "PROPOSAL: (copilot error)" >> "$logf"
  proposal_valid "$logf"
}

commit(){ git add -A && git commit -q -m "$1" && git push -q 2>/dev/null || true; }

log "=== ralph start (opencode/Agents-A1): up to $N iterations, TRIALS=$TRIALS ==="
wait_for_model
bash scripts/apply_profile.sh
bash scripts/run_all.sh | tee -a "$REPO/ralph.log"
bash scripts/score.sh
best=$(cat runs/current/SCORE_NUM.txt 2>/dev/null || echo 0)
# `bar` is the DECAYING high-water mark the loop must beat. A keep raises it to
# the achieved score; every rollback pulls it toward the just-observed score by
# an EMA (DECAY), so a lucky one-off peak erodes over a few rounds instead of
# blocking all future progress — while a reproducible high keeps re-matching the
# bar and never decays. Comparison is on the rounded bar.
DECAY="${DECAY:-0.7}"
bar="$best"
round(){ awk -v x="$1" 'BEGIN{printf "%d",(x<0?x-0.5:x+0.5)}'; }
log "baseline score=$best (bar=$bar, DECAY=$DECAY)"
echo "## $(date -Is) baseline score=$best" >> RESULTS.md
commit "baseline score=$best"

mode="$PROPOSER"
case "$PROPOSER" in
  local)   log "PROPOSER=local: Agents-A1 proposer only (no Claude, no credits)";;
  copilot) log "PROPOSER=copilot: Claude Sonnet 5 via GitHub Copilot (no Anthropic usage credits)";;
esac
for i in $(seq 1 "$N"); do
  wait_for_model
  # adaptive recovery: when we've fallen back to local, probe the preferred
  # proposer each round and switch back as soon as it works again.
  if [ "$mode" = local ]; then
    if [ "$PROPOSER" = claude ] && claude_up; then mode=claude; log "Claude quota recovered -> back to Claude"; fi
    if [ "$PROPOSER" = copilot ] && copilot_up; then mode=copilot; log "Copilot recovered -> back to Copilot"; fi
  fi

  case "$mode" in
    claude)
      if propose_claude "$i"; then :; else
        mode=local; log "Claude exhausted -> falling back to LOCAL proposer (Agents-A1)"
        propose_local "$i"
      fi ;;
    copilot)
      if propose_copilot "$i"; then :; else
        mode=local; log "Copilot proposer unavailable -> falling back to LOCAL proposer (Agents-A1)"
        propose_local "$i"
      fi ;;
    local)   propose_local "$i" ;;
  esac
  prop=$(grep -m1 '^PROPOSAL:' "runs/proposer_$i.log" 2>/dev/null || echo "PROPOSAL: (none)")
  log "--- iter $i [$mode] $prop"

  if ! bash scripts/apply_profile.sh; then
    log "iter $i: profile invalid — rolling back proposer edit"
    git checkout -- oc_profile/ 2>/dev/null || true
    git clean -fdq oc_profile/ 2>/dev/null || true
    commit "iter $i [$mode] rollback (invalid profile)"
    continue
  fi
  bash scripts/run_all.sh | tee -a "$REPO/ralph.log"
  bash scripts/score.sh
  new=$(cat runs/current/SCORE_NUM.txt 2>/dev/null || echo 0)
  thr=$(round "$bar")
  log "iter $i score=$new (bar=$(printf '%.2f' "$bar") -> need >=$thr)"
  if [ "${new:-0}" -ge "${thr:-0}" ]; then
    # keep: ratchet the bar up to the achieved score (never lower it on a keep)
    bar=$(awk -v b="$bar" -v n="$new" 'BEGIN{print (n>b)?n:b}')
    best=$(round "$bar")
    echo "## $(date -Is) iter $i [$mode] KEEP score=$new (bar->$(printf '%.2f' "$bar")) — $prop" >> RESULTS.md
    commit "iter $i [$mode] keep score=$new — $prop"
  else
    # rollback the edit, and decay the bar toward the observed score (EMA)
    bar=$(awk -v b="$bar" -v n="$new" -v d="$DECAY" 'BEGIN{printf "%.4f", d*b+(1-d)*n}')
    best=$(round "$bar")
    echo "## $(date -Is) iter $i [$mode] ROLLBACK score=$new<$thr (bar decays ->$(printf '%.2f' "$bar")) — $prop" >> RESULTS.md
    git checkout -- oc_profile/ 2>/dev/null || true
    git clean -fdq oc_profile/ 2>/dev/null || true
    commit "iter $i [$mode] rollback (score $new<$thr, bar->$(printf '%.2f' "$bar"))"
  fi

  # Auto-escalate: when saturated (all tasks pass) for 2 rounds, import a harder
  # benchmark task (aider polyglot) and re-baseline so there is always headroom.
  ntasks=$(ls -d tasks/*/ 2>/dev/null | wc -l)
  if [ "${new:-0}" -eq "$ntasks" ]; then sat=$((sat+1)); else sat=0; fi
  if [ "$sat" -ge 2 ]; then
    log "saturated ($new/$ntasks) x$sat — importing a harder benchmark task"
    if bash scripts/import_bench.sh; then
      sat=0
      wait_for_model
      bash scripts/apply_profile.sh
      bash scripts/run_all.sh | tee -a "$REPO/ralph.log"
      bash scripts/score.sh
      best=$(cat runs/current/SCORE_NUM.txt 2>/dev/null || echo 0)
      bar="$best"   # reset the decaying bar to the new (larger) task set's baseline
      nt=$(ls -d tasks/*/ 2>/dev/null | wc -l)
      log "re-baseline after escalation: best=$best/$nt (bar reset)"
      echo "## $(date -Is) re-baseline after escalation: $best/$nt tasks" >> RESULTS.md
      commit "re-baseline after escalation: best=$best/$nt"
    fi
  fi
done
log "=== ralph done, best=$best ==="
