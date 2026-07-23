#!/bin/bash
# verify.sh <workdir> — restore pristine tests, then run pytest
W="$1"; T="$(cd "$(dirname "$0")" && pwd)"
cp "$T/seed/food_chain_test.py" "$W/food_chain_test.py" || exit 1
cd "$W" || exit 1
timeout 180 python3 -m pytest -q food_chain_test.py >/dev/null 2>&1
