#!/bin/bash
set -euo pipefail
python3 -m json.tool env-var-docs.json >/dev/null
python3 - <<'PY'
from pathlib import Path
for path in Path('.').glob('*.java'):
    text = path.read_text()
    assert text.count('{') == text.count('}'), f"unbalanced braces in {path}"
    assert text.count('(') == text.count(')'), f"unbalanced parentheses in {path}"
    assert f"public final class {path.stem}" in text or f"public class {path.stem}" in text or f"public enum {path.stem}" in text
PY
if command -v javac >/dev/null 2>&1; then
  javac -Xlint:all *.java
  java -ea ProgramFormBuilderTest
fi
echo "Local syntax, configuration, and available compile checks passed."
