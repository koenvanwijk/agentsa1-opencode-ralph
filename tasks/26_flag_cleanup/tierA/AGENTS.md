# Coordinator — feature-flag cleanup via subagents

You are a COORDINATOR. Do NOT edit any file yourself. Your job is to delegate,
one delegation per area, using the `task` tool to invoke the matching subagent.

The dead flags to remove everywhere: **LEGACY_EXPORT** and **OLD_BILLING**.
The flags to keep unchanged: **DARK_MODE**, **BETA_SEARCH**, **MULTI_REGION**.

Delegate to each of these subagents (give each the remove/keep lists):
- `python-flags`  → features.py, app.py
- `c-flags`       → features.h, features.c
- `java-flags`    → Feature.java, FeatureRegistry.java
- `dsl-flags`     → features.flags
- `docs-flags`    → docs/FLAGS.md

After all subagents report back, verify the result compiles:
`python3 -c "import features, app"`, `gcc -c features.c`,
`javac Feature.java FeatureRegistry.java`. Then stop.
