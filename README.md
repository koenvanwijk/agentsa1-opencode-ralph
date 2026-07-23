# agentsa1-opencode-ralph

A **Ralph loop** that automatically improves the agentic-coding performance of
**Agents-A1** (InternScience 35B MoE, served locally via vLLM on an NVIDIA DGX
Spark) as driven by the **[OpenCode CLI](https://github.com/sst/opencode)**.

Sibling of `mistral-vibe-ralph` (Mistral Medium 3.5 + Mistral Vibe). Same
tasks, same loop, different target model and harness:
- target model: **Agents-A1** on spark-480b (`http://192.168.86.32:8000/v1`);
- harness: **OpenCode** — steering lives in OpenCode's own knobs
  (`AGENTS.md` + `opencode.json`), no cloud required.

## How it works

```
baseline: run every task/ through OpenCode TRIALS times (default 3) -> majority score
loop:
  1. proposer reads failing tasks + trajectories, makes ONE change to oc_profile/
  2. apply oc_profile/ into each task workdir, re-run all tasks (3 trials), re-score
  3. score didn't drop?  keep + git commit + push   :   roll back the change
  4. saturated 2 rounds? import a harder benchmark task and re-baseline
```

Each task runs 3 times; it passes if a **majority** of trials pass. Scoring is
pass/total — fully local, no LLM judge.

## The tunable surface: `oc_profile/`
OpenCode injects `AGENTS.md` from the project root into the system prompt every
turn and reads `opencode.json` for harness behaviour, so those two files are
the harness profile (copied into each task workdir by `run_all.sh`):
- **`oc_profile/AGENTS.md`** — the always-injected rules (primary steering).
- **`oc_profile/opencode.json`** — provider wiring + harness knobs (`permission`,
  model `options`, `limit`). The proposer must not touch the provider baseURL.

## Adaptive proposer
Preferably headless **Claude Code** (`claude -p`). On Claude quota-out the loop
switches to a **local proposer** (`local_propose.py`) driven by Agents-A1
itself, and probes Claude each round to switch back. The loop never stalls.

## Benchmark tasks
Tasks 01–18 are shared with `mistral-vibe-ralph` (18 hand-written + auto-gen
agentic coding jobs). On saturation the escalator imports from `bench_pool/`,
the Python subset of the [aider polyglot benchmark](https://github.com/Aider-AI/polyglot-benchmark)
(34 Exercism exercises), hardest-first per `bench_pool/ORDER.txt`.

## Run
```bash
TRIALS=3 ./ralph.sh 30     # 30 iterations, 3 trials/task (detached for overnight)
```

## Setup
- Agents-A1 served OpenAI-compatible at `http://192.168.86.32:8000/v1` (DGX Spark spark-480b).
- `opencode` CLI installed (`~/.local/bin/opencode`).
- `claude` CLI authenticated — used as the autonomous proposer.
