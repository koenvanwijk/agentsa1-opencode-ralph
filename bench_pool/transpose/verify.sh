#!/bin/bash
# verify.sh <workdir> — restore pristine tests, then run pytest
W="$1"; T="$(cd "$(dirname "$0")" && pwd)"
cp "$T/seed/transpose_test.py" "$W/transpose_test.py" || exit 1
cd "$W" || exit 1
timeout 180 python3 -m pytest -q transpose_test.py >/dev/null 2>&1
