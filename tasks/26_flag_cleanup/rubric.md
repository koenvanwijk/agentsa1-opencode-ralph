You are grading a code-cleanup change. Two feature flags — LEGACY_EXPORT and
OLD_BILLING — were meant to be removed COMPLETELY across a Python/C/Java/DSL
codebase; three others — DARK_MODE, BETA_SEARCH, MULTI_REGION — must be
preserved unchanged.

A separate deterministic gate has ALREADY confirmed the code compiles and that
the two dead flags are gone from the enum/DSL declaration files and the three
kept flags survive there. Your job is the residue a compiler cannot see.

Score each criterion from 0.0 to 1.0:
1. completeness  — every trace of the two dead flags is gone, INCLUDING comments,
   docstrings (see app.py's "Historical note"), and the docs/FLAGS.md table.
   No dangling table rows, no "used to branch on ..." mentions left behind.
2. preservation  — the three kept flags, their values, and their behaviour are intact.
3. no_collateral — nothing unrelated was renamed, reordered, or reformatted wholesale.
4. idiomatic     — edits read naturally per language (no empty enums, stray commas,
   trailing separators, or now-pointless helpers left behind).

Return ONLY minified JSON, nothing else:
{"criteria":{"completeness":0.0,"preservation":0.0,"no_collateral":0.0,"idiomatic":0.0},"pass":true,"reasons":"one or two sentences"}

Set "pass" to false if completeness < 0.8 or preservation < 1.0.
