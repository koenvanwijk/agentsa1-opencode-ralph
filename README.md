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

Within a normal trial, the runner gives an incomplete solution up to three
fresh-context OpenCode turns in the same workdir. It runs the task's deterministic
`verify.sh` after every turn, stops immediately on success, and feeds a compact
verifier failure into the next turn. Configure this with `OC_MAX_TURNS` and
`OC_TURN_TIMEOUT` (defaults: `3` and `900` seconds). Full turn transcripts live
outside the candidate snapshot under `runs/transcripts/`, so whole-tree verifiers
cannot mistake harness chatter for task artifacts.

## Loop map (visual docs)
[`docs/loops.html`](docs/loops.html) is a self-contained visual map of the whole
project framed as a **feedback control loop** — setpoint, controller (the
proposer), plant (the model under OpenCode), sensor (verify + score), feedforward
(learned rules + DSL cheatsheet), and the loops nested inside each other
(cascade). It also covers the adaptive proposer, the fan-out, the per-DSL builder
loop, where learning happens, the score-over-iterations curve, the model swap,
deterministic vs stochastic evaluation, and the DSL plugin model. Open it in a
browser. Keep it in sync when the loop architecture changes.

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

## Cohabitation & path ownership
The loop runs autonomously and **auto-commits + pushes every round** to `master`.
To let development happen in the same checkout while the loop runs, edits must
respect a path-ownership boundary. Both auto-commit sites — `ralph.sh` `commit()`
and `scripts/import_bench.sh` — stage **only loop-owned paths** (`ralph.sh`
`LOOP_PATHS`), never a bare `git add -A`, so in-progress work is not swept into a
proposer-labelled commit.

**Loop-owned** — the loop writes and auto-commits these; do **not** hand-edit
them while the loop runs, or your change races the proposer's rollback:
- `oc_profile/` — the tuned profile (`AGENTS.md` + `opencode.json`)
- `RESULTS.md` — the keep/rollback ledger
- `tasks/`, `bench_pool/` — the task set and the escalation pool

**Dev-owned** — safe to edit and hand-commit in small scoped commits; the loop
never auto-commits these:
- `tools/` — `dslc`, `fanout`, and other tooling
- `ralph.sh`, `scripts/`, `local_propose.py`, `proposer/` — loop infra. Edits
  take effect on the **next loop restart** (the running bash has already parsed
  the current script).
- `README.md` and other docs

**Ephemeral / untracked** (git-ignored, never committed): `runs/`, `ralph.log`,
`.opencode/`, `.fanout/`, `.experiment/`.

Practical rule: keep off the loop-owned paths, commit dev work in small scoped
commits (e.g. `git add tools/dslc && git commit`), and remember infra edits land
at the next restart. A separate `git worktree` also works but is not required.

## Run
```bash
TRIALS=3 ./ralph.sh 30     # 30 iterations, 3 trials/task (detached for overnight)
```

## GPU measurements
Every `run_all.sh` evaluation records GPU telemetry under
`runs/metrics/<timestamp>-<label>-p<parallelism>/` (git-ignored):
- `nvidia-smi.csv` spans the complete evaluation; its JSON summary contains
  mean/p50/p95/max utilization, memory activity, power, clocks, and temperature.
- `nsys.nsys-rep` captures the first 300 seconds by default with device-level
  DRAM, SM, Tensor, issue, and occupancy counters. When supported,
  `nsys-summary/` contains the automatic GPU-metric utilization summary.
- `run.env` records the label, model, task/trial counts, parallelism, duration,
  and exit status. `runs/metrics/latest` points at the newest evaluation.

The monitor is best-effort: missing Nsight, unsupported counters, or insufficient
profiler permissions never stop Ralph. Nsight uses passwordless `sudo` when it
is available; otherwise it tries the current user's profiler permissions and
falls back to the lightweight stream. Set `GPU_METRICS=off` to disable all
sampling or `GPU_METRICS=smi` to skip only Nsight. Sampling controls are
`GPU_METRICS_INTERVAL_MS` (default 1000), `GPU_METRICS_NSYS_HZ` (100), and
`GPU_METRICS_NSYS_SECONDS` (300).

These are device-level counters from the machine running `run_all.sh`. Run the
loop on spark-480b, alongside ds4-server, so they describe the serving GPU rather
than a remote OpenCode client. A controlled P=1/P=3 comparison can be collected
with:

```bash
PARALLEL_JOBS=1 RALPH_RUN_LABEL=p1 bash scripts/run_all.sh
PARALLEL_JOBS=3 RALPH_RUN_LABEL=p3 bash scripts/run_all.sh
```

Use aggregate task throughput together with the Nsight DRAM and Tensor/SM
counters. The `nvidia-smi` memory percentage is activity time, not achieved
memory bandwidth, so it cannot by itself prove that decode is memory-bound.

## Setup
- Agents-A1 served OpenAI-compatible at `http://192.168.86.32:8000/v1` (DGX Spark spark-480b).
- `opencode` CLI installed (`~/.local/bin/opencode`).
- `claude` CLI authenticated — used as the autonomous proposer.
