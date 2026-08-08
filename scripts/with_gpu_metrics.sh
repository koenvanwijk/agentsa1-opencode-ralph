#!/bin/bash
# Run a command while sampling the GPU. The lightweight nvidia-smi stream spans
# the complete command. Nsight Systems captures a bounded, low-overhead window
# with device-level DRAM/SM/Tensor/occupancy counters when it is available.
#
# Usage: bash scripts/with_gpu_metrics.sh OUTPUT_DIR -- command [args...]

set -u

if [ "$#" -lt 3 ] || [ "$2" != "--" ]; then
  echo "usage: $0 OUTPUT_DIR -- command [args...]" >&2
  exit 2
fi

OUT_DIR="$1"
shift 2
mkdir -p "$OUT_DIR"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GPU_METRICS_MODE="${GPU_METRICS:-auto}"
SMI_INTERVAL_MS="${GPU_METRICS_INTERVAL_MS:-1000}"
NSYS_FREQUENCY_HZ="${GPU_METRICS_NSYS_HZ:-100}"
NSYS_SECONDS="${GPU_METRICS_NSYS_SECONDS:-300}"

smi_pid=""
nsys_pid=""
nsys_session=""
NSYS_BIN=""
nsys_runner=()
cleaned=0
started_at="$(date -Is)"
started_epoch="$(date +%s)"

log(){
  printf '[gpu-metrics] %s\n' "$*" | tee -a "$OUT_DIR/monitor.log" >&2
}

launch_isolated(){
  if command -v setsid >/dev/null 2>&1; then
    setsid "$@" &
  else
    "$@" &
  fi
  launched_pid=$!
}

background_running(){
  local pid="$1"
  kill -0 "$pid" 2>/dev/null || return 1
  jobs -pr | grep -qx "$pid"
}

stop_background(){
  local pid="$1" signal="$2" max_wait="$3" elapsed=0
  [ -n "$pid" ] || return 0
  background_running "$pid" || { wait "$pid" 2>/dev/null || true; return 0; }

  if command -v setsid >/dev/null 2>&1; then
    kill -"$signal" -- "-$pid" 2>/dev/null || kill -"$signal" "$pid" 2>/dev/null || true
  else
    kill -"$signal" "$pid" 2>/dev/null || true
  fi

  while background_running "$pid" && [ "$elapsed" -lt "$max_wait" ]; do
    sleep 1
    elapsed=$((elapsed + 1))
  done
  if background_running "$pid"; then
    if command -v setsid >/dev/null 2>&1; then
      kill -TERM -- "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
    else
      kill -TERM "$pid" 2>/dev/null || true
    fi
  fi
  wait "$pid" 2>/dev/null || true
}

summarize(){
  if command -v python3 >/dev/null 2>&1 && [ -s "$OUT_DIR/nvidia-smi.csv" ]; then
    python3 "$SCRIPT_DIR/summarize_gpu_metrics.py" \
      "$OUT_DIR/nvidia-smi.csv" "$OUT_DIR/nvidia-smi-summary.json" \
      >> "$OUT_DIR/monitor.log" 2>&1 || log "could not summarize nvidia-smi samples"
  fi

  local report=""
  report=$(find "$OUT_DIR" -maxdepth 1 -name '*.nsys-rep' -print -quit 2>/dev/null || true)
  if [ -n "$report" ] && command -v nsys >/dev/null 2>&1 \
      && nsys recipe gpu_metric_util_sum --help >/dev/null 2>&1; then
    nsys recipe gpu_metric_util_sum \
      --input "$report" \
      --output "$OUT_DIR/nsys-summary" \
      --force-overwrite --csv \
      >> "$OUT_DIR/nsys-analysis.log" 2>&1 \
      || log "Nsight report saved, but automatic summary recipe failed"
  fi
}

cleanup(){
  [ "$cleaned" -eq 0 ] || return 0
  cleaned=1
  stop_background "$smi_pid" TERM 5
  if [ -n "$nsys_session" ] && [ -n "$NSYS_BIN" ] && background_running "$nsys_pid"; then
    timeout 60 "${nsys_runner[@]}" "$NSYS_BIN" stop --session="$nsys_session" \
      >> "$OUT_DIR/nsys.log" 2>&1 \
      || log "Nsight session did not stop cleanly"
    nsys_session=""
  elif [ -n "$nsys_pid" ]; then
    wait "$nsys_pid" 2>/dev/null || true
    nsys_session=""
  fi
  stop_background "$nsys_pid" TERM 10
  summarize
  {
    printf 'finished_at=%q\n' "$(date -Is)"
    printf 'duration_seconds=%q\n' "$(( $(date +%s) - started_epoch ))"
  } >> "$OUT_DIR/monitor.env"
}

on_signal(){
  local signal="$1" code="$2"
  log "received $signal; stopping profilers"
  cleanup
  trap - EXIT
  exit "$code"
}

trap cleanup EXIT
trap 'on_signal INT 130' INT
trap 'on_signal TERM 143' TERM
trap 'on_signal HUP 129' HUP

{
  printf 'started_at=%q\n' "$started_at"
  printf 'hostname=%q\n' "$(hostname)"
  printf 'mode=%q\n' "$GPU_METRICS_MODE"
  printf 'nvidia_smi_interval_ms=%q\n' "$SMI_INTERVAL_MS"
  printf 'nsys_frequency_hz=%q\n' "$NSYS_FREQUENCY_HZ"
  printf 'nsys_window_seconds=%q\n' "$NSYS_SECONDS"
} > "$OUT_DIR/monitor.env"

if [ "$GPU_METRICS_MODE" != "off" ] && command -v nvidia-smi >/dev/null 2>&1; then
  printf '%s\n' 'timestamp,index,gpu_util_pct,memory_io_busy_pct,memory_used_mib,memory_total_mib,power_w,sm_clock_mhz,memory_clock_mhz,temperature_c' \
    > "$OUT_DIR/nvidia-smi.csv"
  launch_isolated nvidia-smi \
    --query-gpu=timestamp,index,utilization.gpu,utilization.memory,memory.used,memory.total,power.draw,clocks.sm,clocks.mem,temperature.gpu \
    --format=csv,noheader,nounits --loop-ms="$SMI_INTERVAL_MS" \
    >> "$OUT_DIR/nvidia-smi.csv" 2>> "$OUT_DIR/monitor.log"
  smi_pid="$launched_pid"
  log "nvidia-smi sampling started (pid=$smi_pid)"
else
  log "nvidia-smi sampling unavailable or disabled"
fi

if [ "$GPU_METRICS_MODE" != "off" ] && [ "$GPU_METRICS_MODE" != "smi" ] \
    && command -v nsys >/dev/null 2>&1; then
  NSYS_BIN="$(command -v nsys)"
  if nsys start --help 2>&1 | grep -q -- '--gpu-metrics-devices'; then
    NSYS_DEVICE_OPT="--gpu-metrics-devices=all"
  else
    NSYS_DEVICE_OPT="--gpu-metrics-device=all"
  fi

  if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    nsys_runner=(sudo -n)
  fi

  if nsys start --help 2>&1 | grep -q -- '--session-new'; then
    nsys_session="ralphgpu$$_$(date +%s)"
    launch_isolated "${nsys_runner[@]}" "$NSYS_BIN" start \
      --session-new="$nsys_session" \
      --duration="$NSYS_SECONDS" \
      --sample=none --trace=none \
      "$NSYS_DEVICE_OPT" \
      --gpu-metrics-frequency="$NSYS_FREQUENCY_HZ" \
      --output="$OUT_DIR/nsys" \
      >> "$OUT_DIR/nsys.log" 2>&1
    nsys_pid="$launched_pid"
    sleep 1
  fi
  if [ -n "$nsys_pid" ] && background_running "$nsys_pid"; then
    log "Nsight GPU-metric window started (session=$nsys_session, ${NSYS_SECONDS}s)"
  else
    [ -n "$nsys_pid" ] && wait "$nsys_pid" 2>/dev/null || true
    nsys_pid=""
    nsys_session=""
    log "interactive Nsight GPU metrics unavailable; see nsys.log (Ralph continues)"
  fi
else
  log "Nsight sampling unavailable or disabled; lightweight samples continue"
fi

"$@"
command_rc=$?
cleanup
trap - EXIT INT TERM HUP
exit "$command_rc"
