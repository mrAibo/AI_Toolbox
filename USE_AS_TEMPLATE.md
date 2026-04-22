# Using AI Toolbox as a GitHub Template

AI Toolbox can be used as a **GitHub Template Repository** — a one-click starting point for
new projects that gets you a clean copy of the full structure without fork history.

---

## Three Things That Are Often Confused

| Mechanism | Where it runs | What it does |
|-----------|---------------|--------------|
| **GitHub Template** | GitHub website, once | Creates a new remote repository from this structure |
| **`setup.sh` / `setup.ps1`** | Locally, after cloning | Interactive wizard: detects AI clients, installs tools (rtk, Beads), configures MCP |
| **`bootstrap.sh` / `.ps1`** | Locally, silent + idempotent | Creates router files, memory structure, and Git hooks — no interactive prompts |
| **`sync-task.sh` / `.ps1`** | Locally, each AI session | Syncs task state from Beads into `.agent/memory/current-task.md` |

**The template is not a replacement for setup or bootstrap.** GitHub Template only creates
the remote repository. You still need to run `setup.sh` or `bootstrap.sh` locally after cloning.

---

## Recommended New-User Flow

```text
1. GitHub   →  click "Use this template" on https://github.com/mrAibo/AI_Toolbox
                (or navigate to https://github.com/mrAibo/AI_Toolbox/generate)
2. Terminal →  git clone https://github.com/YOUR-ORG/YOUR-REPO.git
3.             cd YOUR-REPO
4.             bash .agent/scripts/setup.sh          # Linux/macOS — interactive
               # or
               powershell -ExecutionPolicy Bypass -File .agent\scripts\setup.ps1   # Windows
5. Open your AI client in the project directory — it will auto-read AGENT.md
6. Each new session: run sync-task.sh / .ps1 to keep task state current
```

### What setup does (step 4)

- Detects which AI clients you have installed
- Runs `bootstrap.sh` silently (router files, memory structure, Git hooks)
- Offers to install optional tools: rtk (token optimization) and Beads (task tracking)
- Configures MCP servers for your primary client

---

## The `/generate` Flow on GitHub

GitHub's template feature is available at:

```
https://github.com/mrAibo/AI_Toolbox/generate
```

Or via the **"Use this template"** button on the repository home page.

After generation your new repository:
- Is a clean copy with no upstream connection to `mrAibo/AI_Toolbox`
- Contains all tracked files in their seed state — ready for `setup.sh`
- Has no `.claude/`, `.beads/`, or session-specific memory (all gitignored)

The AI client router files (`CLAUDE.md`, `QWEN.md`, etc.) in your copy still reference
`mrAibo/AI_Toolbox` in documentation links — that is intentional; they point to the
original source for ongoing reference.

---

## Template Suitability Notes

The following was verified when preparing this template:

| Area | Status | Notes |
|------|--------|-------|
| `mrAibo/AI_Toolbox` URLs in docs | OK | Documentation/source references — correct for a template |
| `.agent/memory/session-handover.md` | Gitignored | Not included in template output |
| `.agent/memory/current-task.md` | Gitignored | Not included in template output |
| `.beads/` | Gitignored | Not included in template output |
| `.claude/` local settings | Gitignored | Not included in template output |
| Tracked memory files | OK | Generic seed content only — appropriate starting state |
| Secrets in tracked files | None found | CI validates this on every push |

---

## Note for Existing Users

**You do not need the GitHub Template feature.** If you already cloned or forked this
repository and ran `setup.sh` / `bootstrap.sh`, your setup is complete.

The template exists only for users who want to **start a new project from scratch**
using AI Toolbox as the base structure.

For existing repos, continue using the normal flow:
- `sync-task.sh` / `.ps1` — at each session start
- `setup.sh` / `.ps1` — to re-configure after adding new AI clients
- `bootstrap.sh` / `.ps1` — to re-initialize silently (CI-friendly)
- `doctor.sh` / `.ps1` — to verify your current setup is healthy

---

## Further Reading

| Topic | File |
|-------|------|
| Full installation guide | [INSTALL.md](INSTALL.md) |
| 5-minute quick start | [QUICKSTART.md](QUICKSTART.md) |
| Architecture overview | [README.md](README.md) |
| Contribution guide | [CONTRIBUTING.md](CONTRIBUTING.md) |
