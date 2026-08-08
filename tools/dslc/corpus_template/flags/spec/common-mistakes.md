# `.flags` — common mistakes (fault catalogue)

Stable rule-ids used by the linter, the cheatsheet, and the `.expect` sidecars.

## `EXPECTED_FEATURE`
Top-level content that is not a `feature` block.

```
# wrong
flag DARK_MODE { default on owner ui }
# right
feature DARK_MODE { default on owner ui }
```

## `NAME_NOT_UPPER_SNAKE`
Feature name is not `UPPER_SNAKE_CASE`.

```
# wrong
feature darkMode { default on owner ui }
# right
feature DARK_MODE { default on owner ui }
```

## `DUPLICATE_FEATURE`
Same feature name defined twice in one file.

```
# wrong
feature DARK_MODE { default on owner ui }
feature DARK_MODE { default off owner ui }
# right — pick one definition
feature DARK_MODE { default on owner ui }
```

## `UNKNOWN_FIELD`
A field other than `default` / `owner` / `description`.

```
# wrong
feature DARK_MODE { default on owner ui color blue }
# right
feature DARK_MODE { default on owner ui }
```

## `BAD_DEFAULT`
`default` value is not `on` or `off`.

```
# wrong
feature DARK_MODE { default yes owner ui }
# right
feature DARK_MODE { default on owner ui }
```

## `DUPLICATE_FIELD`
A field appears more than once in one block.

```
# wrong
feature DARK_MODE { default on default off owner ui }
# right
feature DARK_MODE { default on owner ui }
```

## `MISSING_REQUIRED_FIELD`
`default` and/or `owner` missing.

```
# wrong
feature DARK_MODE { owner ui }
# right
feature DARK_MODE { default on owner ui }
```

## `UNTERMINATED_FEATURE`
Block not closed with `}`.

```
# wrong
feature DARK_MODE { default on owner ui
# right
feature DARK_MODE { default on owner ui }
```
