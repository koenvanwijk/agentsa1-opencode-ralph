#!/bin/bash
# verify.sh <workdir> — exact output (sort desc + 2-decimal rounding)
W="$1"
[ -f "$W/report.txt" ] || { echo "no report.txt"; exit 1; }
exp=$'Gadget: $20.00\nDoohickey: $12.00\nWidget: $9.50\nGizmo: $3.20\nTOTAL: $44.70'
got=$(sed 's/[[:space:]]*$//' "$W/report.txt" | sed -e :a -e '/^\n*$/{$d;N;ba}')
if [ "$got" = "$exp" ]; then echo ok; else echo "mismatch. got:"; printf '%s\n' "$got"; exit 1; fi
