#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
python3 "$root/tools/metagen.py" "$root/metadata.yaml" --out "$tmp"
diff -ru --exclude=__pycache__ --exclude='*.pyc' "$root/generated" "$tmp"
python3 -m pytest -q "$root/test_generated.py"
