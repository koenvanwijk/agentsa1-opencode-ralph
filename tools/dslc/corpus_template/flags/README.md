# corpus_template — reference DSL corpus

A fully-filled example of the corpus contract in
[`../../CORPUS_REQUIREMENTS.md`](../../CORPUS_REQUIREMENTS.md), for the `.flags`
DSL. Copy this directory as the starting point for a new DSL's (external) corpus.

Checklist when adding a DSL (the **external** deliverable — good examples only):

1. `manifest.json` — validates against `../../manifest.schema.json`.
2. `spec/grammar.md` — authoritative syntax; one construct → one section.
3. `spec/common-mistakes.md` — each mistake gets a stable `RULE_ID`.
4. `examples/good/*` — every construct covered; each file compiles in isolation.
   Fine to pull these from an existing archive.

`examples/bad/` here is **illustrative**: it shows what the loop's per-rule-id
mutation operators produce from the good examples (see
[`../../CORPUS_REQUIREMENTS.md`](../../CORPUS_REQUIREMENTS.md) §4). You do NOT
hand-author the bad set for a real corpus — the loop derives it, keeping the
test set independent of the LLM-generated linter. Only genuinely
un-mutatable edge cases get a reviewed hand-written `bad/` example.
