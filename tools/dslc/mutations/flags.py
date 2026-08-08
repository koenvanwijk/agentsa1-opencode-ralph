"""Mutation operators for the `.flags` DSL — the TRUSTED half of the selftest.

Per CORPUS_REQUIREMENTS.md §4, the bad examples are not hand-authored and not
freely invented by an LLM; they are DERIVED deterministically from the curated
good examples by breaking one on exactly one axis. Each operator here owns one
stable rule-id (matching spec/common-mistakes.md and grammars/flags.py) and, by
construction, injects exactly that one fault into an otherwise-valid file.

Living in `mutations/` — separate from the linter in `grammars/` — is deliberate:
the test set that judges the linter must be independent of the (LLM-authored)
linter. These operators are small enough to review by hand.

Contract per operator:

    fn(good_text: str) -> (mutant_text: str, line: int) | None

`line` is the 1-based line at which the linter is expected to report the fault
(so the `.expect` sidecar and the selftest can check it). `None` means the
operator does not apply to this particular good file (e.g. no `default` line to
break) — the selftest simply skips that (good, operator) pair.
"""
import re

NAME = "flags"

_FEATURE_RE = re.compile(r"^(\s*)feature(\s+)([A-Za-z_][A-Za-z0-9_]*)(.*)$")
_DEFAULT_RE = re.compile(r"^(\s*)default(\s+)(on|off)\b(.*)$")


def _feature_lines(lines):
    """Indices of every line that opens a `feature NAME` block."""
    return [i for i, ln in enumerate(lines) if _FEATURE_RE.match(ln)]


def _brace_close_lines(lines):
    """Indices of every line that is a bare closing brace."""
    return [i for i, ln in enumerate(lines) if ln.strip() == "}"]


def _first_block_span(lines):
    """(feature_idx, close_idx) of the first block, or None."""
    feats = _feature_lines(lines)
    if not feats:
        return None
    f = feats[0]
    for j in range(f, len(lines)):
        if lines[j].strip() == "}":
            return f, j
    return None


def expected_feature(good):
    """EXPECTED_FEATURE — replace the `feature` keyword with a non-keyword."""
    lines = good.split("\n")
    feats = _feature_lines(lines)
    if not feats:
        return None
    f = feats[0]
    lines[f] = _FEATURE_RE.sub(r"\1flag\2\3\4", lines[f], count=1)
    return "\n".join(lines), f + 1


def name_not_upper_snake(good):
    """NAME_NOT_UPPER_SNAKE — lowercase the first feature's name."""
    lines = good.split("\n")
    feats = _feature_lines(lines)
    if not feats:
        return None
    f = feats[0]
    m = _FEATURE_RE.match(lines[f])
    bad = m.group(3).lower()
    if bad == m.group(3):  # already not upper — nothing to break
        return None
    lines[f] = f"{m.group(1)}feature{m.group(2)}{bad}{m.group(4)}"
    return "\n".join(lines), f + 1


def duplicate_feature(good):
    """DUPLICATE_FEATURE — append a verbatim copy of the first block."""
    lines = good.split("\n")
    span = _first_block_span(lines)
    if span is None:
        return None
    f, b = span
    block = "\n".join(lines[f:b + 1])
    base = good.rstrip("\n")
    base_lines = base.count("\n") + 1
    mutant = base + "\n\n" + block + "\n"
    # the duplicate's `feature NAME {` sits one blank line after the base
    return mutant, base_lines + 2


def unknown_field(good):
    """UNKNOWN_FIELD — insert a bogus field into the first block."""
    lines = good.split("\n")
    feats = _feature_lines(lines)
    if not feats:
        return None
    f = feats[0]
    lines.insert(f + 1, "    color blue")
    return "\n".join(lines), f + 2


def bad_default(good):
    """BAD_DEFAULT — replace an `on`/`off` default with an invalid value."""
    lines = good.split("\n")
    for i, ln in enumerate(lines):
        m = _DEFAULT_RE.match(ln)
        if m:
            lines[i] = f"{m.group(1)}default{m.group(2)}yes{m.group(4)}"
            return "\n".join(lines), i + 1
    return None


def duplicate_field(good):
    """DUPLICATE_FIELD — insert a second `owner` line in the first block."""
    lines = good.split("\n")
    span = _first_block_span(lines)
    if span is None:
        return None
    f, b = span
    for i in range(f + 1, b):
        if lines[i].strip().startswith("owner"):
            lines.insert(i + 1, lines[i])  # duplicate it verbatim
            return "\n".join(lines), i + 2
    return None


def missing_required_field(good):
    """MISSING_REQUIRED_FIELD — drop the `default` line from the first block."""
    lines = good.split("\n")
    span = _first_block_span(lines)
    if span is None:
        return None
    f, b = span
    for i in range(f + 1, b):
        if lines[i].strip().startswith("default"):
            del lines[i]
            return "\n".join(lines), f + 1  # reported at the feature line
    return None


def unterminated_feature(good):
    """UNTERMINATED_FEATURE — remove the last block's closing brace."""
    lines = good.split("\n")
    closes = _brace_close_lines(lines)
    feats = _feature_lines(lines)
    if not closes or not feats:
        return None
    b = closes[-1]
    opener = max((f for f in feats if f <= b), default=None)
    if opener is None:
        return None
    del lines[b]
    return "\n".join(lines), opener + 1


# rule-id -> operator. One entry per mutation-derivable rule-id in
# spec/common-mistakes.md. `dslc selftest` checks this set covers the catalogue.
MUTATORS = {
    "EXPECTED_FEATURE": expected_feature,
    "NAME_NOT_UPPER_SNAKE": name_not_upper_snake,
    "DUPLICATE_FEATURE": duplicate_feature,
    "UNKNOWN_FIELD": unknown_field,
    "BAD_DEFAULT": bad_default,
    "DUPLICATE_FIELD": duplicate_field,
    "MISSING_REQUIRED_FIELD": missing_required_field,
    "UNTERMINATED_FEATURE": unterminated_feature,
}
