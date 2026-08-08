# `.flags` — grammar (reference corpus)

A minimal feature-flag DSL. A file is a sequence of `feature` blocks; blank
lines and `#`-comments are ignored.

## Structure

```
feature NAME {
    default on|off         # required
    owner   <ident>        # required
    description "<text>"   # optional
}
```

## Rules

- **feature keyword** — every block starts with the literal `feature`. Anything
  else at top level is an error (`EXPECTED_FEATURE`).
- **NAME** — `UPPER_SNAKE_CASE`: starts with an uppercase letter, then uppercase
  letters, digits, or `_`. Regex `^[A-Z][A-Z0-9_]*$`. Must be unique within the
  file.
- **Block body** — zero or more fields between `{` and `}`. Allowed fields:
  `default`, `owner`, `description`. Each field may appear at most once.
  - `default` — bare identifier `on` or `off`. Required.
  - `owner` — a bare identifier (team/handle). Required.
  - `description` — a double-quoted string (`"..."`, backslash-escapes allowed).
    Optional.
- **Termination** — the block must be closed with `}`.

## Tokens

- comments: `#` to end of line
- strings: `"(?:\\.|[^"\\])*"`
- identifiers: `[A-Za-z_][A-Za-z0-9_]*`
- braces: `{` `}`
- whitespace (incl. newlines) is insignificant except as a token separator

## Compiled artifact

A JSON list of `{ "name", "default", "owner", "description" }` objects, in source
order. `description` is `null` when omitted.
