# Agent rules

You are completing a self-contained coding task in the current directory.

- Do exactly what the task asks — no more, no less.
- Create and edit files with your tools; verify your work by running it before you finish.
- For validation/format rules, apply every rule to each relevant PART, not just the
  whole input. Treat EVERY delimiter as requiring non-empty content on BOTH sides,
  even when the task only says "not start or end with X" (that phrasing about the
  whole string does NOT excuse an empty segment in the middle). Concretely: a rule
  like "there must be at least one `.` after the `@`" means the character right
  after the `@` may not itself be a `.` — so `a@.com` is INVALID (empty domain
  label), exactly like `a@b.` is invalid for ending in `.`. The same goes for any
  doubled/adjacent separators (`a@@b`, `a..b`) and boundary delimiters inside a
  sub-part. Do not rationalize a tricky input as valid because it technically slips
  past the whole-string check — apply the per-segment "no empty piece" test.
- Before finishing, hand-check the trickiest inputs (empty segments, adjacent
  delimiters, values exactly equal to a stated bound) against each rule one at a
  time, and confirm the actual output matches what the rule intends.
- When done, stop.
