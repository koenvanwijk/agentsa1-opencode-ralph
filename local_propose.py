#!/usr/bin/env python3
"""Local (Claude-free) Ralph proposer for the OpenCode / Agents-A1 loop.

Uses the local model (Agents-A1 on spark-480b) to propose ONE edit to
oc_profile/. Constrained output protocol keeps it reliable:

    PROPOSAL: <one line>
    TARGET: oc_profile/<path>
    ```
    <full new file content>
    ```

Applies the edit (guarded: path under oc_profile/; opencode.json must stay
valid JSON and keep the provider wiring) and prints the PROPOSAL line. On any
parse/guard failure it prints "PROPOSAL: (local proposer no-op)" and changes
nothing.
"""
import os, re, json, glob, shutil, subprocess, pathlib

REPO = pathlib.Path(__file__).resolve().parent
# ENGINE: "openai" -> local Agents-A1 via OpenAI SDK (no credits, weaker);
#         "copilot" -> Claude Sonnet 5 via GitHub Copilot through `hermes -z`
#         (real Claude, billed to the org Copilot subscription, NOT Anthropic usage credits).
ENGINE = os.environ.get("PROPOSER_ENGINE", "openai")
PROP_URL = os.environ.get("PROPOSER_URL", "http://192.168.86.32:8000/v1")
PROP_MODEL = os.environ.get("PROPOSER_MODEL", "Agents-A1")
HERMES_ALIAS = os.environ.get("HERMES_ALIAS", "ghe-copilot")
WIRING = "192.168.86.32:8000"  # provider baseURL must survive any opencode.json edit


def complete(system, user):
    """Return the proposer model's raw text via the selected engine."""
    if ENGINE == "copilot":
        hermes = shutil.which("hermes") or os.path.expanduser("~/.local/bin/hermes")
        prompt = system + "\n\n=== EVIDENCE ===\n\n" + user
        r = subprocess.run([hermes, "-m", HERMES_ALIAS, "-z", prompt],
                           capture_output=True, text=True, timeout=1200)
        return r.stdout or ""
    from openai import OpenAI
    client = OpenAI(base_url=PROP_URL, api_key="none", timeout=1200)
    r = client.chat.completions.create(
        model=PROP_MODEL, temperature=0.4, max_tokens=4000,
        messages=[{"role": "system", "content": system},
                  {"role": "user", "content": user}])
    return r.choices[0].message.content or ""

def read(p, n=2500):
    try:
        return pathlib.Path(p).read_text()[:n]
    except Exception:
        return ""

def gather():
    score = read(REPO / "runs/current/SCORE.txt")
    ctx = ["## SCORE\n" + score]
    for task in sorted(glob.glob(str(REPO / "tasks/*/"))):
        name = os.path.basename(task.rstrip("/"))
        if f"FAIL {name}" not in score:
            continue
        ctx.append(f"\n## FAILING TASK {name}\nPROMPT: {read(task+'prompt.txt',400)}")
        ctx.append("VERIFY: " + read(task + "verify.sh", 500))
        traj = read(str(REPO / f"runs/current/{name}/trial1/_oc_stdout.txt"), 1400)
        ctx.append("TRIAL1 OUTPUT (tail):\n" + traj[-1100:])
    ctx.append("\n## CURRENT oc_profile/AGENTS.md\n" + read(REPO / "oc_profile/AGENTS.md"))
    ctx.append("\n## CURRENT oc_profile/opencode.json\n" + read(REPO / "oc_profile/opencode.json"))
    return "\n".join(ctx)

def main():
    instructions = read(REPO / "proposer/PROPOSER.md", 4000)
    protocol = (
        "\n\nOutput EXACTLY in this format and nothing else:\n"
        "PROPOSAL: <one line>\nTARGET: oc_profile/<relative path>\n"
        "```\n<full new content of that ONE file>\n```\n"
        "Prefer editing oc_profile/AGENTS.md. If editing opencode.json, keep the "
        "provider block (baseURL http://192.168.86.32:8000/v1) intact."
    )
    try:
        out = complete(instructions + protocol, gather())
    except Exception as e:
        print(f"PROPOSAL: (local proposer error: {e})"); return

    prop = next((l for l in out.splitlines() if l.strip().startswith("PROPOSAL:")), "PROPOSAL: (none)")
    mt = re.search(r"TARGET:\s*(oc_profile/[^\s`]+)", out)
    mc = re.search(r"```[a-zA-Z]*\n(.*?)```", out, re.S)
    if not (mt and mc):
        print("PROPOSAL: (local proposer no-op — unparseable)"); return
    rel = mt.group(1).strip()
    if ".." in rel or not rel.startswith("oc_profile/"):
        print("PROPOSAL: (local proposer no-op — bad path)"); return
    content = mc.group(1)
    if rel.endswith("opencode.json"):
        try:
            j = json.loads(content)
            assert WIRING in json.dumps(j)
        except Exception:
            print("PROPOSAL: (local proposer no-op — opencode.json invalid or dropped wiring)"); return
    dest = REPO / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(content)
    print(prop if prop.startswith("PROPOSAL:") else "PROPOSAL: " + prop)

if __name__ == "__main__":
    main()
