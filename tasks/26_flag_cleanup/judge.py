#!/usr/bin/env python3
"""LLM-as-judge for the feature-flag-cleanup task.

The deterministic gate in verify.sh already guarantees the hard invariants
(everything compiles, the two dead enum members are gone from every declaration
file, the three kept ones survive). This judge scores the SUBJECTIVE residue a
compiler cannot see: were the dead flags also cleaned out of prose/docs/comments,
is the result idiomatic and consistent, and was anything unrelated damaged?

It POSTs to an OpenAI-compatible /chat/completions endpoint (dependency-free —
just urllib, no `openai` package) for a strict-JSON verdict, votes over
JUDGE_VOTES independent samples (to average out judge nondeterminism), and exits
0 (pass) / 1 (fail) / 2 (infrastructure error).

Config (env):
    JUDGE_URL        default http://192.168.86.32:8000/v1
    JUDGE_MODEL      default deepseek-v4-flash  (raw model id on the endpoint,
                     not the opencode 'Agents-A1' alias)
    JUDGE_API_KEY    default EMPTY  (sent as Bearer only when != EMPTY)
    JUDGE_VOTES      default 3     (majority decides pass/fail)
    JUDGE_MIN_SCORE  default 0.6   (mean criterion score must also clear this)
    JUDGE_TEMP       default 0.3

Point it at a stronger/different grader (e.g. Claude via a gateway) by setting
JUDGE_URL/JUDGE_MODEL/JUDGE_API_KEY — nothing else changes.
"""
import argparse
import difflib
import json
import os
import pathlib
import re
import sys
import urllib.error
import urllib.request

# Files whose *quality* the judge inspects (superset of the gate's decl files:
# app.py + docs/FLAGS.md carry residue the gate deliberately does not grep).
FILES = [
    "features.py", "features.h", "features.c",
    "Feature.java", "FeatureRegistry.java",
    "features.flags", "app.py", "docs/FLAGS.md",
]

DEFAULT_RUBRIC = """\
You are grading a code-cleanup change. Two feature flags (LEGACY_EXPORT and
OLD_BILLING) were meant to be removed completely; three others (DARK_MODE,
BETA_SEARCH, MULTI_REGION) must be preserved unchanged. A deterministic gate
already confirmed it compiles and the declarations are consistent; grade the
residue a compiler cannot see.

Score each 0.0..1.0: completeness (all traces of the two dead flags gone,
including comments/docstrings/docs), preservation (three kept flags intact),
no_collateral (nothing unrelated changed), idiomatic (edits read naturally).

Return ONLY minified JSON:
{"criteria":{"completeness":0.0,"preservation":0.0,"no_collateral":0.0,"idiomatic":0.0},"pass":true,"reasons":"..."}
Set "pass" false if completeness < 0.8 or preservation < 1.0.
"""


def read(path):
    try:
        return pathlib.Path(path).read_text()
    except OSError:
        return None


def build_evidence(seed_dir, work_dir):
    blocks = []
    for rel in FILES:
        before = read(os.path.join(seed_dir, rel))
        after = read(os.path.join(work_dir, rel))
        if before is None and after is None:
            continue
        if after is None:
            blocks.append(f"### {rel}\n(candidate DELETED this file)\n")
            continue
        diff = "".join(
            difflib.unified_diff(
                (before or "").splitlines(keepends=True),
                after.splitlines(keepends=True),
                fromfile=f"a/{rel}",
                tofile=f"b/{rel}",
            )
        )
        blocks.append(f"### {rel}\n```diff\n{diff or '(unchanged)'}\n```\n")
    return "\n".join(blocks)


def extract_json(text):
    m = re.search(r"\{.*\}", text or "", re.S)
    if not m:
        return None
    try:
        return json.loads(m.group(0))
    except json.JSONDecodeError:
        return None


def mean_of(verdict):
    crit = verdict.get("criteria", {}) or {}
    vals = [v for v in crit.values() if isinstance(v, (int, float))]
    return sum(vals) / len(vals) if vals else 0.0


def chat(url, model, key, temp, system, user):
    """POST one chat completion to an OpenAI-compatible endpoint; return text."""
    body = json.dumps(
        {
            "model": model,
            "temperature": temp,
            "max_tokens": 800,
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
        }
    ).encode()
    headers = {"Content-Type": "application/json"}
    if key and key != "EMPTY":
        headers["Authorization"] = f"Bearer {key}"
    req = urllib.request.Request(
        url.rstrip("/") + "/chat/completions", data=body, headers=headers
    )
    with urllib.request.urlopen(req, timeout=300) as resp:
        payload = json.loads(resp.read().decode())
    return payload["choices"][0]["message"]["content"] or ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seed", required=True)
    ap.add_argument("--work", required=True)
    args = ap.parse_args()

    task_dir = pathlib.Path(__file__).resolve().parent
    rubric = read(task_dir / "rubric.md") or DEFAULT_RUBRIC
    evidence = build_evidence(args.seed, args.work)

    url = os.environ.get("JUDGE_URL", "http://192.168.86.32:8000/v1")
    model = os.environ.get("JUDGE_MODEL", "deepseek-v4-flash")
    key = os.environ.get("JUDGE_API_KEY", "EMPTY")
    votes = int(os.environ.get("JUDGE_VOTES", "3"))
    min_score = float(os.environ.get("JUDGE_MIN_SCORE", "0.6"))
    temp = float(os.environ.get("JUDGE_TEMP", "0.3"))

    user_msg = "Candidate's cleanup as unified diffs vs the original. Grade it.\n\n" + evidence

    verdicts = []
    for v in range(votes):
        try:
            text = chat(url, model, key, temp, rubric, user_msg)
        except (urllib.error.URLError, KeyError, ValueError, TimeoutError) as exc:
            print(f"JUDGE-ERROR: model call failed: {exc}", file=sys.stderr)
            return 2
        j = extract_json(text)
        if not j or "pass" not in j:
            print(f"  vote {v + 1}: unparseable verdict -> counted as FAIL", file=sys.stderr)
            verdicts.append({"pass": False, "criteria": {}, "reasons": "unparseable"})
            continue
        verdicts.append(j)
        print(
            f"  vote {v + 1}: pass={bool(j.get('pass'))} mean={mean_of(j):.2f} "
            f":: {j.get('reasons', '')}",
            file=sys.stderr,
        )

    n_pass = sum(1 for j in verdicts if j.get("pass"))
    overall = sum(mean_of(j) for j in verdicts) / len(verdicts) if verdicts else 0.0
    decision = (n_pass > votes / 2) and (overall >= min_score)

    print(
        f"JUDGE: {n_pass}/{votes} pass-votes, mean {overall:.2f} "
        f"(need majority AND mean>={min_score}) -> {'PASS' if decision else 'FAIL'}",
        file=sys.stderr,
    )
    return 0 if decision else 1


if __name__ == "__main__":
    sys.exit(main())
