#!/bin/bash
# verify.sh <workdir> — exact session-accounting report from a messy 2400-line log.
# Discriminators: strict field/timestamp parsing, duplicate-LOGIN ignore,
# stray-LOGOUT ignore, unclosed sessions dropped (zed absent), zero-total user
# kept (quinn), tie order (tina before tom), near-EOF session (omar).
W="$1"
[ -f "$W/report.txt" ] || { echo "no report.txt"; exit 1; }
python3 - "$W" << 'PY'
import sys
expected = """ivan 350497
heidi 304663
erin 294830
carol 280173
grace 266145
peggy 255701
frank 236234
dave 230778
alice 228544
mallory 219150
judy 195706
bob 188329
omar 9999
tina 3600
tom 3600
quinn 0"""
got = open(f"{sys.argv[1]}/report.txt").read()
if got.rstrip("\n") != expected:
    print("report.txt does not match expected output")
    print("--- got ---")
    print(got)
    sys.exit(1)
print("ok")
PY
