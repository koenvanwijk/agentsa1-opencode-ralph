#!/bin/bash
# verify.sh <workdir> — restore pristine tests, then run pytest
W="$1"; T="$(cd "$(dirname "$0")" && pwd)"
cp "$T/seed/paasio_test.py" "$W/paasio_test.py" || exit 1
cp "$T/seed/test_utils.py" "$W/test_utils.py" || exit 1
cd "$W" || exit 1
timeout 180 python3 -m pytest -q paasio_test.py test_utils.py >/dev/null 2>&1
