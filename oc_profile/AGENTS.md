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
- EMAIL / "a `.` after the `@`" VALIDATION — this is stricter than a literal reading
  of the prompt, and this rule OVERRIDES that literal reading. "At least one `.`
  somewhere after the `@`" and "does not start or end with `.`" must be checked on the
  DOMAIN part (everything after the `@`) BY ITSELF, not only on the whole string. So the
  domain must NOT start with `.` and must NOT end with `.`. Consequence: `a@.com` (same
  as `user@.com`) is INVALID even though the full string does not start with `.`, because
  its domain `.com` starts with `.`. Likewise `a@b.` is invalid (domain ends with `.`).
  The simplest correct domain test is: `dom` contains `.` AND `not dom.startswith('.')`
  AND `not dom.endswith('.')` — do NOT use `'.' in dom` alone. Your own test list MUST
  include `a@.com` asserted to return False; if your test claims it is True, that is a
  BUG to fix, not a valid case.
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
- SPACE-SEPARATED RECORD rules (log/command lines like `WITHDRAW A1001 500` or
  `SET key 12`, where fields are separated by SINGLE spaces and ANY deviation is
  MALFORMED and must be silently ignored — not rejected). Validate EXACTLY like this
  and treat a line as malformed the moment any check fails:
  - Split on a single space ONLY: `parts = line.split(' ')`. Do NOT use `.split()`
    with no argument (it collapses runs of whitespace and hides double spaces/tabs)
    and do NOT `.strip()` the line first (that hides leading/trailing spaces).
  - Require the EXACT field count for that operation, AND require `'' not in parts`.
    A blank field means a leading space, trailing space, or a double space — all
    malformed. A field containing a tab or other whitespace fails its regex below.
  - Match the operation word with `==` against the EXACT uppercase spelling. NEVER
    call `.upper()`/`.lower()`/`.casefold()` on it — lowercase or mixed-case ops
    (`deposit`, `Set`) are malformed, not valid.
  - Validate every remaining field with `re.fullmatch` (NOT `re.match`, which allows
    trailing junk): an integer amount with no leading zeros/sign/decimal is
    `[1-9][0-9]*` when it must be positive, or `0|[1-9][0-9]*` when `0` is allowed
    (so `0500`, `00`, `-5`, `+5`, `12.50`, `0x10` are all malformed). Ids/keys use
    their own exact pattern, e.g. `A[0-9]{4}` or `[a-z]{2,10}`.
  - MALFORMED (bad syntax) is silently dropped and NEVER written to rejected output;
    REJECTED (well-formed but not allowed, e.g. overdraft, unknown/duplicate,
    self-transfer, txn-state violation) IS recorded. Keep these two paths separate.
  - Process files in ascending filename order (`sorted(...)`), read EVERY line of
    EVERY file programmatically, and carry all mutable state (balances, the store,
    any open transaction) across file boundaries. Comparisons like overdraft/SUB use
    `>` so draining to exactly 0 is allowed; check existence against the CURRENT view
    (the transaction's working copy when one is open, else the committed store).
- OUTPUT-FORMAT FIDELITY — every output line must contain EXACTLY the fields the
  task names, in the exact spelling/shape shown, and nothing else. Two mistakes
  seen repeatedly:
  - CENTS vs DOLLARS. When a value is described as an integer number of cents and
    the output must be dollars with two decimals, you MUST divide by 100 — never
    print the raw cents. Format with integer arithmetic so it never drifts:
        dollars = f"${cents // 100}.{cents % 100:02d}"
    (798383 cents -> `$7983.83`; 0 cents -> `$0.00`; 123456 -> `$1234.56`). Printing
    `$798383` or `$798383.00` is WRONG. The stored/working balance stays in integer
    cents; only the final formatting divides.
  - RECORD lines carry ONLY the named fields. If the spec says a line is
    `FILENAME:LINE OP`, emit exactly those three tokens (e.g. `2024-01.log:611 DEPOSIT`)
    — do NOT append the rest of the source line's arguments (`... A9999 5000`). Build
    the output string from the specific pieces the format lists, never by echoing the
    whole input line you parsed.
- Before finishing, build a test list that includes an input with a delimiter at the
  very start/end of a sub-part (e.g. `a@.com`) and one with doubled delimiters
  (e.g. `a..b@c.com`), and confirm your function returns False for them. If your
  own test prints True for such an input, that is a BUG to fix, not an acceptable
  result.
- When done, stop.
