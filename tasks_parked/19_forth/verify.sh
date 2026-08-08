#!/bin/bash
# verify.sh <workdir> — restore pristine tests, then run pytest
W="$1"; T="$(cd "$(dirname "$0")" && pwd)"
cp "$T/seed/forth_test.py" "$W/forth_test.py" || exit 1
cd "$W" || exit 1
timeout 180 python3 -m pytest -q forth_test.py >/dev/null 2>&1
