# Metadata generator

`metadata.yaml` is the source of truth. Run `./generate.sh` after changing the
schema, metadata model, renderer, or templates. Files in `generated/` are committed
for consumers but must never be edited by hand.

By default, generated signal configuration supports attribute folding. Set
`attribute_folding_enabled: false` in metadata to generate the legacy configuration
containing only the `enabled` field.

Contributors must run `./generate.sh` followed by `./check.sh` and commit any
resulting generated-file changes.

