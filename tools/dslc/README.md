# dslc — reusable mini-DSL compiler

A dependency-free validator/compiler for small DSLs, used by tasks that need a
"compile step" for a DSL (e.g. the feature-flag DSL in `tasks/26_flag_cleanup`).

## Use

```bash
python3 tools/dslc/dslc.py check   path/to/file.flags   # exit 0 iff it compiles
python3 tools/dslc/dslc.py compile path/to/file.flags   # print canonical JSON
python3 tools/dslc/dslc.py list                         # registered grammars
python3 tools/dslc/dslc.py selftest                     # golden gate for the flags corpus
python3 tools/dslc/dslc.py selftest <corpus_dir> --emit-bad out/   # + write derived bad/
```

Diagnostics carry a stable rule-id: `LINE: [RULE_ID] message` (ids listed in
`grammars/<name>.py:RULE_IDS` and `spec/common-mistakes.md`).

## selftest — the deterministic golden gate

`selftest` implements the CORPUS_REQUIREMENTS.md contract for a DSL, with **no
LLM**. For the corpus it:

1. compiles every `examples/good/*` — all must pass clean;
2. checks the mutators cover the fault catalogue (`spec/common-mistakes.md`);
3. for each good example × each rule-id, derives one bad example via
   `mutators/<name>.py` and asserts the linter rejects it with **exactly** that
   rule-id, at the **expected line**.

The bad set is *derived*, never hand-authored or LLM-invented, so the test that
judges the (possibly LLM-generated) linter is independent of it — see the trust
table in `CORPUS_REQUIREMENTS.md §4`. A catalogue id with no mutator, a good
example that fails to compile, or a mutant that trips the wrong id all make
`selftest` exit non-zero.

## Add / break a rule

A rule-id lives in four places that must agree: the linter diagnosis
(`grammars/<name>.py`), the cheatsheet + `spec/common-mistakes.md`, the `.expect`
sidecars, and one mutation operator in `mutators/<name>.py`. `selftest` is what
enforces that they agree.

## Add a new DSL (reuse)

Drop a module into `grammars/` — no change to `dslc.py` needed:

```python
# grammars/mydsl.py
EXTENSIONS = [".mydsl"]

def compile(text):
    errors = []
    # ...parse/validate...
    return (len(errors) == 0, errors, artifact)   # (ok, errors, JSON-able artifact)
```

`grammars/flags.py` is the reference implementation (tokenizer + recursive
descent + error recovery). The registry auto-discovers every `*.py` in
`grammars/` (files starting with `_` are skipped) and maps its `EXTENSIONS` to
it, so new DSLs plug in by extension.
