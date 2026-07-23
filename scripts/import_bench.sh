#!/bin/bash
# Import the next benchmark task from bench_pool/ (aider polyglot, hard-first
# per ORDER.txt) into tasks/, re-validating it like gen_task.sh does.
# Exit 0 = a task was imported; exit 1 = pool empty / task invalid.
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO"
log(){ echo "[$(date -Is)] [bench] $*" | tee -a "$REPO/ralph.log"; }

next=""
while read -r cand; do
  [ -n "$cand" ] && [ -d "bench_pool/$cand" ] && { next="$cand"; break; }
done < bench_pool/ORDER.txt 2>/dev/null
[ -z "$next" ] && { log "bench pool empty — nothing to import"; exit 1; }

src="bench_pool/$next"
wref=$(mktemp -d); wemp=$(mktemp -d)
cp -a "$src/seed/." "$wref/"; cp -a "$src/seed/." "$wemp/"
cp -a "$src/_reference/." "$wref/"
bash "$src/verify.sh" "$wref" >/dev/null 2>&1; refok=$?
bash "$src/verify.sh" "$wemp" >/dev/null 2>&1; empok=$?
rm -rf "$wref" "$wemp"
if [ "$refok" -ne 0 ] || [ "$empok" -eq 0 ]; then
  log "pool task $next invalid (ref=$refok seed=$empok) — dropped from pool"
  rm -rf "$src"; exit 1
fi

num=$(printf "%02d" $(( $(ls -d tasks/*/ 2>/dev/null | wc -l) + 1 )))
dest="tasks/${num}_${next}"
mv "$src" "$dest"
log "imported benchmark task $dest (aider polyglot)"
git add -A && git commit -q -m "escalate: import benchmark task ${num}_${next} (aider polyglot)" && git push -q 2>/dev/null || true
exit 0
