#!/bin/bash
# verify.sh <workdir> — restore pristine tests, then run pytest
W="$1"; T="$(cd "$(dirname "$0")" && pwd)"
cp "$T/seed/list_ops_test.py" "$W/list_ops_test.py" || exit 1
cd "$W" || exit 1
timeout 180 python3 -m pytest -q list_ops_test.py >/dev/null 2>&1
