#!/bin/bash
set -euo pipefail
W="$1"
T="$(cd "$(dirname "$0")" && pwd)"
fail() { echo "GATE-FAIL: $*" >&2; exit 1; }

required=(metadata-schema.json metadata.yaml loader.py render.py README.md generate.sh check.sh test_generated.py tools/metagen.py templates/config.py.tmpl templates/runtime.py.tmpl generated/config.py generated/runtime.py)
for f in "${required[@]}"; do [ -f "$W/$f" ] || fail "required file missing: $f"; done
[ ! -e "$W/.git" ] || fail "trial must remain history-free"

# The generic driver is trusted infrastructure, not task solution surface.
cmp -s "$W/tools/metagen.py" "$T/seed/tools/metagen.py" \
  || fail "generic generator driver was modified"

# The retired key is allowed exactly once: an explicit loader discard for old input.
python3 - "$W" <<'PY' || fail "retired gate cleanup is incomplete"
from pathlib import Path
import re, sys
w = Path(sys.argv[1])
needle = "attribute_folding_enabled"
hits = []
for path in w.rglob("*"):
    if not path.is_file() or "__pycache__" in path.parts:
        continue
    try:
        text = path.read_text()
    except UnicodeDecodeError:
        continue
    for line_no, line in enumerate(text.splitlines(), 1):
        if needle in line:
            hits.append((path.relative_to(w).as_posix(), line_no, line.strip()))
assert len(hits) == 1, hits
path, _, line = hits[0]
assert path == "loader.py", hits
assert re.search(r'(pop|del)\s*\(?["\']attribute_folding_enabled["\']', line), hits

loader = (w / "loader.py").read_text()
assert "attribute_folding_enabled:" not in loader
assert "Metadata(" in loader and "signals=raw[\"signals\"]" in loader
schema = __import__("json").loads((w / "metadata-schema.json").read_text())
assert "attribute_folding_enabled" not in schema["allowed_top_level"]
PY

# Regeneration must be reproducible, using the candidate sources and untouched driver.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
python3 "$W/tools/metagen.py" "$W/metadata.yaml" --out "$tmp/generated" \
  || fail "generator failed"
diff -ru --exclude=__pycache__ --exclude='*.pyc' "$W/generated" "$tmp/generated" >/dev/null \
  || fail "checked-in generated files differ from a fresh generator run"

# Legacy true/false keys must be accepted but ignored. Generate three variants and
# demand byte-identical output.
python3 - "$W/metadata.yaml" "$tmp" <<'PY'
from pathlib import Path
import yaml, sys
src = yaml.safe_load(Path(sys.argv[1]).read_text())
root = Path(sys.argv[2])
for name, value in (("modern", None), ("legacy_true", True), ("legacy_false", False)):
    data = dict(src)
    if value is not None:
        data["attribute_folding_enabled"] = value
    (root / f"{name}.yaml").write_text(yaml.safe_dump(data, sort_keys=False))
PY
for variant in modern legacy_true legacy_false; do
  python3 "$W/tools/metagen.py" "$tmp/$variant.yaml" --out "$tmp/$variant" \
    || fail "generator rejected $variant metadata"
done
diff -ru --exclude=__pycache__ --exclude='*.pyc' "$tmp/modern" "$tmp/legacy_true" >/dev/null \
  || fail "legacy true key still changes generated output"
diff -ru --exclude=__pycache__ --exclude='*.pyc' "$tmp/modern" "$tmp/legacy_false" >/dev/null \
  || fail "legacy false key still changes generated output"

# Hidden runtime checks exercise the permanently enabled generated path.
PYTHONPATH="$W" python3 - <<'PY' || fail "generated runtime behaviour is incorrect"
from generated.config import ActiveWorkersConfig, RequestDurationConfig, SignalsConfig
from generated.runtime import ActiveWorkersRuntime, RequestDurationRuntime

cfg = SignalsConfig()
assert isinstance(cfg.request_duration, RequestDurationConfig)
assert isinstance(cfg.active_workers, ActiveWorkersConfig)
assert cfg.request_duration.enabled is True
assert cfg.active_workers.enabled is False
cfg.request_duration.attributes = ("method", "status")
runtime = RequestDurationRuntime(cfg.request_duration)
assert runtime.fold_key({"method": "GET", "status": "200", "zone": "west"}) == (("zone", "west"),)
assert ActiveWorkersRuntime(cfg.active_workers).fold_key({"pool": "main"}) == (("pool", "main"),)
PY

(cd "$W" && bash ./check.sh) >/dev/null || fail "visible checks failed"
echo "GATE-PASS: generator-driven gate retirement is reproducible and compatible" >&2
