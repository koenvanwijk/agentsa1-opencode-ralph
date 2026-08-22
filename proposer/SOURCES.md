# External inspiration sources for AGENTS.md proposals

The proposer may consult these BEFORE editing `oc_profile/AGENTS.md`, in
addition to the run evidence (`runs/current/SCORE.txt`, trial transcripts).
Use them when a failure has been stuck (same task failing / bar not rising)
for 2+ consecutive rounds — not every round, to avoid burning tokens/time on
research when the local evidence already points to a clear fix.

## How to use a source in a proposal
Cite it in the `PROPOSAL:` line, e.g.
`PROPOSAL: (via J-Space ledger pattern) added a checkpoint rule ... targets task 21`
This keeps RESULTS.md / git log traceable to why a rule was added, so a later
round can tell "our own evidence" apart from "borrowed idea that didn't pan
out" when deciding whether to roll back.

## Registered sources (edit this list as new ones are found)

1. **GitHub repos with agentic harness prompts** — search github.com or use
   `gh search repos "AGENTS.md" opencode` / "system prompt" "coding agent" for
   prior art. Known example already evaluated:
   `github.com/Tiger3807861189/J-Space-Cognition-Suite-V3.6` — ledger/
   checkpoint/recovery instruction blocks for multi-stage tasks. Verdict
   (2026-08-21 analysis): relevant for solver/retirement-style tasks, but
   prompt-heavy — measure token/latency cost before keeping.
2. **Anthropic / OpenAI prompt-engineering docs** — for concrete tool-use and
   "always emit a real tool call" phrasing patterns (this harness already hit
   the "model narrates instead of calling a tool" failure mode).
3. **opencode.ai docs / GitHub issues** (github.com/sst/opencode) — for
   `opencode.json` permission/tool-denial semantics; earlier iterations found
   a `bash` deny pattern was silently inert on this build — check open issues
   before re-attempting similar permission tricks.
4. **Confluence** — NOT yet wired up. If Koen provisions a Confluence MCP
   server (see skill `mcp:native-mcp`) with a space containing team AGENTS.md
   conventions/playbooks, add its query instructions here and the proposer
   can pull team-standard rules from it. Until then, skip this source.
5. **Local memory/skills** — `ralph-loop-ops` skill and its
   `references/agentsa1-opencode-ralph.md` already capture this repo's own
   hard-won lessons (subagent-fanout ban, transcript-wipe rule, nsys flag
   gotchas). Re-read these before assuming a "new" failure is actually new.

## Adding a new source
Append a numbered entry with: name, how to query it, and what kind of
AGENTS.md content it's good for (ledger/checkpoint style? tool-use phrasing?
permission semantics?). Keep entries short — this file is read every
iteration where research is triggered.
