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

## Which Installation Method Should I Use?

| Situation | Recommended method |
|-----------|--------------------|
| Starting a brand-new project | **GitHub Template** (this guide) |
| Adding AI Toolbox to an existing repo | **Clone + bootstrap** → [INSTALL.md](INSTALL.md) |
| Just want to try it quickly | **Clone + bootstrap** → [QUICKSTART.md](QUICKSTART.md) |
| Contributing to AI Toolbox itself | **Fork** the repository |

---

## Step-by-Step: GitHub Template Flow

### Step 1 — Create your repository from the template

1. Open the AI Toolbox repository on GitHub
2. Click the green **"Use this template"** button (top right, next to the star button)
3. Select **"Create a new repository"** from the dropdown

> **Note:** "Open in a codespace" is a different option — skip it for local development.

### Step 2 — Fill in your repository details

On the "Create a new repository" page:

| Field | What to enter |
|-------|--------------|
| **Owner** | Your GitHub username or organization |
| **Repository name** | Your project name (e.g. `my-app`, `backend-service`) |
| **Description** | Optional — describe your project |
| **Visibility** | Public or Private — your choice |
| **Include all branches** | Leave unchecked — you only need `main` |

Click **"Create repository"**.

GitHub creates your new repo as a clean copy of AI Toolbox. It has no git history from
`mrAibo/AI_Toolbox` and no upstream connection.

### Step 3 — Clone your new repository locally

Copy the clone URL from your new repository page (green "Code" button → HTTPS or SSH).

```bash
# Linux / macOS — HTTPS
git clone https://github.com/YOUR-ORG/YOUR-REPO.git
cd YOUR-REPO

# Linux / macOS — SSH (if you have SSH keys configured)
git clone git@github.com:YOUR-ORG/YOUR-REPO.git
cd YOUR-REPO
```

```powershell
# Windows — HTTPS
git clone https://github.com/YOUR-ORG/YOUR-REPO.git
cd YOUR-REPO
```

### Step 4 — Run setup

Setup is an interactive wizard. It detects your AI clients, installs optional tools, and
configures hooks automatically.

```bash
# Linux / macOS
bash .agent/scripts/setup.sh
```

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File .agent\scripts\setup.ps1
```

Setup will:
- Detect which AI clients you have installed (Claude Code, Qwen Code, Cursor, etc.)
- Ask which AI client is your primary one
- Run `bootstrap.sh` / `.ps1` silently (creates router files, memory structure, Git hooks)
- Offer to install optional tools: **rtk** (token optimization) and **Beads** (task tracking)
- Configure MCP servers for your primary client

A numbered **Next Steps** checklist is printed at the end — only when manual action is needed.

### Step 5 — Verify the installation

```bash
# Linux / macOS
bash .agent/scripts/doctor.sh
```

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File .agent\scripts\doctor.ps1
```

Doctor checks router files, memory files, hook scripts, cache-prefix markers, and audit log.
All items should show ✅. Fix any ⚠️ items following the printed instructions.

### Step 6 — Open your AI client

Open your AI client in the project root directory. It reads its router file automatically:

| Client | Router file read automatically |
|--------|-------------------------------|
| Claude Code (`claude`) | `CLAUDE.md` |
| Qwen Code (`qwen`) | `QWEN.md` |
| Codex CLI (`codex`) | `CODERULES.md` (via `AGENTS.md`) |
| OpenCode (`opencode`) | `OPENCODERULES.md` |
| Cursor | `.cursorrules` |
| RooCode / Cline | `.clinerules` |
| Windsurf | `.windsurfrules` |
| Gemini CLI (`gemini`) | `GEMINI.md` |
| Aider (`aider`) | `CONVENTIONS.md` |
| Pi (pi.ai) | `PI.md` — paste manually into chat |

### Step 7 — Start your first session

Tell your AI client:

> *"Execute your Boot Sequence, read our memories and sync tasks, then help me set up this project."*

The AI will:
1. Read `AGENT.md` (Boot Sequence)
2. Run `sync-task.sh` / `.ps1` to load task state
3. Read `session-handover.md` for any unfinished work
4. Be ready to start

---

## After the First Session

At the start of **every subsequent session**, your AI client runs the Boot Sequence
automatically (Full-Tier clients via hooks) or on the prompt above (Standard/Basic clients).

Session state persists in `.agent/memory/`:

| File | What it contains |
|------|-----------------|
| `current-task.md` | Active task synced from Beads |
| `session-handover.md` | Unfinished work from the last session |
| `architecture-decisions.md` | Long-term ADRs |
| `integration-contracts.md` | API / schema contracts |
| `memory-index.md` | Boot entry point — lists all memory files |

---

## What Your New Repository Contains

After cloning and running setup, your project structure looks like this:

```
YOUR-REPO/
├── AGENT.md                        ← AI master execution contract
├── CLAUDE.md / QWEN.md / ...       ← Router files (one per detected client)
├── .agent/
│   ├── memory/                     ← Project memory (most files gitignored)
│   │   ├── memory-index.md         ← Boot entry point
│   │   ├── architecture-decisions.md
│   │   └── integration-contracts.md
│   ├── rules/                      ← 21 execution rules
│   ├── scripts/                    ← Setup, bootstrap, doctor, hooks
│   └── workflows/                  ← 12 workflow guides
├── .ai-toolbox/
│   └── config.json                 ← Client registry
└── docs/                           ← Setup guides per client
```

Files that are **gitignored** and not included in the template output:
- `.agent/memory/session-handover.md`
- `.agent/memory/current-task.md`
- `.agent/memory/audit.log`
- `.beads/`
- `.claude/` (local Claude Code settings)

---

## Template vs Clone vs Fork

| | GitHub Template | Clone | Fork |
|--|----------------|-------|------|
| Your own repo on GitHub | ✅ | ✅ manual push | ✅ |
| Clean git history | ✅ | ✅ | ❌ (shares history) |
| Upstream connection | ❌ none | ❌ none | ✅ can PR back |
| Receives AI Toolbox updates | ❌ manual | ❌ manual | ✅ via sync |
| Best for | New projects | Local use / CI | Contributing |

---

## Client-Specific Setup Guides

After setup, check the guide for your primary AI client:

| Client | Guide |
|--------|-------|
| Claude Code | [docs/setup-claude.md](docs/setup-claude.md) |
| OpenCode | [docs/setup-opencode.md](docs/setup-opencode.md) |
| Codex CLI | [docs/setup-codex.md](docs/setup-codex.md) |
| Pi (Inflection AI) | [docs/setup-pi.md](docs/setup-pi.md) |
| All clients — MCP servers | [docs/mcp-guide.md](docs/mcp-guide.md) |
| Linux/macOS specifics | [docs/setup-linux.md](docs/setup-linux.md) |
| Windows specifics | [docs/setup-windows.md](docs/setup-windows.md) |

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
| Full installation guide (all methods) | [INSTALL.md](INSTALL.md) |
| 5-minute quick start | [QUICKSTART.md](QUICKSTART.md) |
| Architecture overview | [README.md](README.md) |
| Contribution guide | [CONTRIBUTING.md](CONTRIBUTING.md) |
| Release history | [CHANGELOG.md](CHANGELOG.md) |
