#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"
python3 "$root/tools/metagen.py" "$root/metadata.yaml" --out "$root/generated"

