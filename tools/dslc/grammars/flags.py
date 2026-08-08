"""Grammar for `.flags` — a minimal feature-flag DSL.

    # comments start with '#'
    feature NAME {
        default on|off         # required
        owner   <ident>        # required
        description "<text>"   # optional
    }

Feature names must be UPPER_SNAKE_CASE (enum-like), unique. Compiles to a list
of {name, default, owner, description} dicts.

This module is the reference example for adding a grammar to dslc: expose
EXTENSIONS and a compile(text) -> (ok, errors, artifact) function.

Every diagnostic is tagged with a STABLE rule-id in `[BRACKETS]` (see
spec/common-mistakes.md). The rule-ids are the contract shared by the linter,
the cheatsheet, the `.expect` sidecars, and the mutation operators — so the
`dslc selftest` gate can check that a mutant fails with exactly the expected id.
Error strings have the shape `"<line>: [<RULE_ID>] <message>"`.
"""
import re

EXTENSIONS = [".flags"]

# The authoritative fault catalogue this linter can emit. Ids that also appear
# in spec/common-mistakes.md are the ones the mutators exercise; the remainder
# are structural diagnostics with no single-edit mutation.
RULE_IDS = [
    "EXPECTED_FEATURE",
    "NAME_NOT_UPPER_SNAKE",
    "DUPLICATE_FEATURE",
    "UNKNOWN_FIELD",
    "BAD_DEFAULT",
    "DUPLICATE_FIELD",
    "MISSING_REQUIRED_FIELD",
    "UNTERMINATED_FEATURE",
    # structural (not mutation-derived):
    "EXPECTED_NAME",
    "EXPECTED_BRACE",
    "BAD_OWNER",
    "BAD_DESCRIPTION",
]

_TOKEN = re.compile(
    r"""
      (?P<WS>[ \t\r]+)
    | (?P<NL>\n)
    | (?P<COMMENT>\#[^\n]*)
    | (?P<LBRACE>\{)
    | (?P<RBRACE>\})
    | (?P<STRING>"(?:\\.|[^"\\])*")
    | (?P<IDENT>[A-Za-z_][A-Za-z0-9_]*)
    | (?P<OTHER>.)
    """,
    re.VERBOSE,
)

_NAME_RE = re.compile(r"^[A-Z][A-Z0-9_]*$")
_FIELDS = {"default", "owner", "description"}


def _tokenize(text):
    toks, line = [], 1
    for m in _TOKEN.finditer(text):
        kind, val = m.lastgroup, m.group()
        if kind == "NL":
            line += 1
            continue
        if kind in ("WS", "COMMENT"):
            continue
        toks.append((kind, val, line))
    toks.append(("EOF", "", line))
    return toks


def compile(text):
    errors = []
    toks = _tokenize(text)
    i = 0
    features = []
    seen = {}

    def err(tok, rule, msg):
        # rule is a stable id from RULE_IDS; keep it machine-parseable.
        errors.append(f"{tok[2]}: [{rule}] {msg}")

    while toks[i][0] != "EOF":
        kind, val, _ = toks[i]
        if not (kind == "IDENT" and val == "feature"):
            err(toks[i], "EXPECTED_FEATURE", f"expected 'feature', found {val!r}")
            # error recovery: skip to the next 'feature' keyword or EOF
            i += 1
            while toks[i][0] != "EOF" and not (
                toks[i][0] == "IDENT" and toks[i][1] == "feature"
            ):
                i += 1
            continue
        i += 1

        if toks[i][0] != "IDENT":
            err(toks[i], "EXPECTED_NAME", f"expected feature name, found {toks[i][1]!r}")
            break
        name_tok = toks[i]
        name = name_tok[1]
        if not _NAME_RE.match(name):
            err(name_tok, "NAME_NOT_UPPER_SNAKE", f"feature name {name!r} must be UPPER_SNAKE_CASE")
        if name in seen:
            err(name_tok, "DUPLICATE_FEATURE", f"duplicate feature {name!r} (first defined on line {seen[name]})")
        seen[name] = name_tok[2]
        i += 1

        if toks[i][0] != "LBRACE":
            err(toks[i], "EXPECTED_BRACE", f"expected '{{' after feature {name}, found {toks[i][1]!r}")
            break
        i += 1

        fields = {}
        while toks[i][0] not in ("RBRACE", "EOF"):
            ktok = toks[i]
            if ktok[0] != "IDENT" or ktok[1] not in _FIELDS:
                err(ktok, "UNKNOWN_FIELD", f"unknown field {ktok[1]!r} (expected one of {sorted(_FIELDS)})")
                i += 1
                continue
            key = ktok[1]
            i += 1
            vtok = toks[i]
            if key == "default":
                if not (vtok[0] == "IDENT" and vtok[1] in ("on", "off")):
                    err(vtok, "BAD_DEFAULT", f"default must be 'on' or 'off', found {vtok[1]!r}")
                    value = None
                else:
                    value = vtok[1]
            elif key == "owner":
                if vtok[0] != "IDENT":
                    err(vtok, "BAD_OWNER", f"owner must be an identifier, found {vtok[1]!r}")
                    value = None
                else:
                    value = vtok[1]
            else:  # description
                if vtok[0] != "STRING":
                    err(vtok, "BAD_DESCRIPTION", f"description must be a quoted string, found {vtok[1]!r}")
                    value = None
                else:
                    value = vtok[1][1:-1]
            if key in fields:
                err(ktok, "DUPLICATE_FIELD", f"duplicate field {key!r} in feature {name}")
            fields[key] = value
            i += 1

        if toks[i][0] == "EOF":
            err(name_tok, "UNTERMINATED_FEATURE", f"unterminated feature {name} (missing '}}')")
            break
        i += 1  # consume '}'

        for req in ("default", "owner"):
            if req not in fields:
                err(name_tok, "MISSING_REQUIRED_FIELD", f"feature {name} is missing required field '{req}'")

        features.append(
            {
                "name": name,
                "default": fields.get("default"),
                "owner": fields.get("owner"),
                "description": fields.get("description"),
            }
        )

    return (len(errors) == 0, errors, features)
