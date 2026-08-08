# corpus_template — reference DSL corpus

A fully-filled example of the corpus contract in
[`../../CORPUS_REQUIREMENTS.md`](../../CORPUS_REQUIREMENTS.md), for the `.flags`
DSL. Copy this directory as the starting point for a new DSL's (external) corpus.

Checklist when adding a DSL:

1. `manifest.json` — validates against `../../manifest.schema.json`.
2. `spec/grammar.md` — authoritative syntax; one construct → one section.
3. `spec/common-mistakes.md` — each mistake gets a stable `RULE_ID`.
4. `examples/good/*` — every construct covered; each file compiles in isolation.
5. `examples/bad/*` — every `RULE_ID` covered; each `.foo` has a sibling
   `.expect` naming the rule-id(s) and line(s) it must fail on.
