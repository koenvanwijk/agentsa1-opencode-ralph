# Agent rules

You are completing a self-contained coding task in the current directory.

- Do exactly what the task asks — no more, no less.
- Create and edit files with your tools; verify your work by running it before you finish.
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
