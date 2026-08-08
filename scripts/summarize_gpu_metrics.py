#!/usr/bin/env python3
"""Summarize the lightweight nvidia-smi samples without third-party packages."""

from __future__ import annotations

import csv
import json
import math
import statistics
import sys
from pathlib import Path


def number(value: str) -> float | None:
    try:
        parsed = float(value.strip())
    except (TypeError, ValueError):
        return None
    return parsed if math.isfinite(parsed) else None


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    index = max(0, math.ceil(len(ordered) * fraction) - 1)
    return ordered[index]


def main() -> int:
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} INPUT.csv OUTPUT.json", file=sys.stderr)
        return 2

    source = Path(sys.argv[1])
    destination = Path(sys.argv[2])
    with source.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))

    metric_names = [
        "gpu_util_pct",
        "memory_io_busy_pct",
        "memory_used_mib",
        "memory_total_mib",
        "power_w",
        "sm_clock_mhz",
        "memory_clock_mhz",
        "temperature_c",
    ]
    metrics: dict[str, dict[str, float | int]] = {}
    for name in metric_names:
        values = [value for row in rows if (value := number(row.get(name, ""))) is not None]
        if not values:
            continue
        metrics[name] = {
            "samples": len(values),
            "mean": round(statistics.fmean(values), 3),
            "p50": round(statistics.median(values), 3),
            "p95": round(percentile(values, 0.95), 3),
            "max": round(max(values), 3),
        }

    summary = {
        "sample_count": len(rows),
        "first_timestamp": rows[0].get("timestamp", "").strip() if rows else None,
        "last_timestamp": rows[-1].get("timestamp", "").strip() if rows else None,
        "metrics": metrics,
        "note": (
            "memory_io_busy_pct is nvidia-smi activity time, not achieved DRAM bandwidth; "
            "use the adjacent Nsight report/summary to diagnose memory-vs-compute limits"
        ),
    }
    destination.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

