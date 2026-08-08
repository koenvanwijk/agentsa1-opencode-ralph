# fanout — tier-B deterministic subagent fan-out

Solve a multi-part task by running one opencode subagent per part, each in an
isolated workdir with only that part's files + a shared spec, so every subagent
has a small context. Reliability does not depend on the model orchestrating
delegation (that is tier A).

## Use

```bash
# offline: prove each subagent's context is small (no model call)
python3 tools/fanout/fanout.py --task tasks/26_flag_cleanup --work /tmp/w --dry-run

# real: run the model per part, merge edits back into --work
python3 tools/fanout/fanout.py --task tasks/26_flag_cleanup --work /tmp/w
python3 tools/fanout/fanout.py --task tasks/26_flag_cleanup --work /tmp/w --only c
```

## Manifest (`<task_dir>/subagents.json`)

```json
{
  "spec": "shared instruction every subagent gets",
  "subagents": [
    {"name": "python", "files": ["features.py", "app.py"], "hint": "..."}
  ]
}
```

Reuse for a new multi-language/DSL task = drop a `subagents.json` in its task
dir. Env: `OC_MODEL` (default `agentsa1/Agents-A1`), `FANOUT_TIMEOUT` (600s).
