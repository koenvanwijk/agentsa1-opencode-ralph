#!/bin/bash
# verify.sh <workdir> — exit 0 = pass. FULLY DETERMINISTIC by default (fast, no
# LLM), so it costs the loop nothing.
#
# The same set of feature flags is declared in Python, C, Java and a DSL. To
# pass, a candidate must:
#   1. keep all four languages compiling/parsing (the DSL via tools/dslc — the
#      "compile step" for the DSL), and
#   2. remove the two dead flags (LEGACY_EXPORT, OLD_BILLING) from EVERY file,
#      including the prose/comments in app.py and docs/FLAGS.md, while
#   3. preserving the three kept flags (DARK_MODE, BETA_SEARCH, MULTI_REGION)
#      in every declaration file.
#
# OPT-IN LLM JUDGE: set JUDGE=llm to additionally run judge.py (scores the
# subjective residue). Off by default so the ralph loop stays fast+deterministic;
# use it to experiment with LLM-as-judge by hand.
set -u
W="$1"
T="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$T/../.." && pwd)"
cd "$W" || exit 1
mkdir -p build

fail() { echo "GATE-FAIL: $*" >&2; exit 1; }

REMOVED=(LEGACY_EXPORT OLD_BILLING)
KEPT=(DARK_MODE BETA_SEARCH MULTI_REGION)
DECL=(features.py features.h features.c Feature.java FeatureRegistry.java features.flags)
RESIDUE=(app.py docs/FLAGS.md)   # prose/comments must be cleaned too

# 1. compile / parse each language -------------------------------------------
python3 -c "import features, app" 2>build/py.err \
    || fail "python import failed:$(printf '\n%s' "$(cat build/py.err)")"
gcc -std=c11 -Wall -c features.c -o build/features.o 2>build/c.err \
    || fail "C compile failed:$(printf '\n%s' "$(cat build/c.err)")"
javac -d build Feature.java FeatureRegistry.java 2>build/java.err \
    || fail "Java compile failed:$(printf '\n%s' "$(cat build/java.err)")"
python3 "$REPO/tools/dslc/dslc.py" check features.flags 2>build/flags.err \
    || fail "DSL compile failed:$(printf '\n%s' "$(cat build/flags.err)")"

# 2. dead flags gone from EVERY file (declarations + prose/comments) ----------
for name in "${REMOVED[@]}"; do
    for f in "${DECL[@]}" "${RESIDUE[@]}"; do
        if [ -f "$f" ] && grep -q "$name" "$f"; then
            fail "removed flag $name still present in $f"
        fi
    done
done

# 3. kept flags survive in every declaration file ----------------------------
for name in "${KEPT[@]}"; do
    for f in "${DECL[@]}"; do
        [ -f "$f" ] || fail "declaration file $f is missing"
        grep -q "$name" "$f" || fail "kept flag $name missing from $f"
    done
done

echo "GATE-PASS: compiles + dead flags gone everywhere + kept flags intact" >&2

# 4. OPT-IN LLM judge (hands-on LLM-as-judge; off by default) -----------------
if [ "${JUDGE:-}" = llm ]; then
    python3 "$T/judge.py" --seed "$T/seed" --work "$W" || exit 1
fi
exit 0
