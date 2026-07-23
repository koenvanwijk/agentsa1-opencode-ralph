# Agent rules

You are completing a self-contained coding task in the current directory.

- Do exactly what the task asks — no more, no less.
- Create and edit files with your tools. VERIFY before finishing — these steps are non-negotiable:
  - After you WRITE or EDIT any script, RUN it again. Every edit invalidates the previous
    run's output. NEVER finish right after an edit without re-running: output files left over
    from an earlier buggy version are a common, silent failure. Confirm the output files were
    just regenerated (fresh, non-empty where expected).
  - Actually READ the contents of every file the task asks you to produce and check each line
    against the task's format and rules. Hand-check the tricky edge cases the task calls out —
    e.g. a value at a boundary (an account drained to exactly 0), a minimal input (a single-digit
    amount like `1`, which is valid), and an id/name that is absent or malformed.
  - If you write a sentence like "the next step is to verify/fix ...", you MUST do it before
    stopping. Do not end your turn describing verification or fixes you have not actually run.
- CONTAINS-a-delimiter rules are NOT satisfied by mere presence. When a rule says a
  part must CONTAIN a character `C` (e.g. "at least one `.` after the `@`"), the
  correct, strict check is: `C` appears AND the part does not start or end with `C`
  AND `C` is never adjacent to another `C`. Equivalently: every piece of
  `part.split(C)` must be non-empty. Do NOT write `C in part` alone — that wrongly
  accepts empty segments. Use this exact pattern:
      ok = (C in part) and not part.startswith(C) and not part.endswith(C) and (C+C) not in part
  This makes `a@.com` INVALID (domain `.com` starts with `.`), just like `a@b.` and
  `a..b` are invalid. Apply the same per-segment "no empty piece" test to every
  delimiter (`@`, `.`, `,`, `/`, etc.), even one inside a sub-part.
- Before finishing, build a test list that includes an input with a delimiter at the
  very start/end of a sub-part (e.g. `a@.com`) and one with doubled delimiters
  (e.g. `a..b@c.com`), and confirm your function returns False for them. If your
  own test prints True for such an input, that is a BUG to fix, not an acceptable
  result.
- When done, stop.
