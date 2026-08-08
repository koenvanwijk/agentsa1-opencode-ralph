# dslc — reusable mini-DSL compiler

A dependency-free validator/compiler for small DSLs, used by tasks that need a
"compile step" for a DSL (e.g. the feature-flag DSL in `tasks/26_flag_cleanup`).

## Use

```bash
python3 tools/dslc/dslc.py check   path/to/file.flags   # exit 0 iff it compiles
python3 tools/dslc/dslc.py compile path/to/file.flags   # print canonical JSON
python3 tools/dslc/dslc.py list                         # registered grammars
```

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
