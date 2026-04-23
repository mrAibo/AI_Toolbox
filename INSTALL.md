# AI Toolbox Installation

## Which Method Should I Use?

| Situation | Method |
|-----------|--------|
| Starting a brand-new project | **[GitHub Template](#option-a-github-template-recommended-for-new-projects)** |
| Adding AI Toolbox to an existing repo | **[Git Clone + Bootstrap](#option-b-git-clone)** |
| Just want to try it quickly | **[Release Download](#option-c-release-download)** |
| Contributing to AI Toolbox | **Fork** the repository |

> Full GitHub Template walkthrough: [USE_AS_TEMPLATE.md](USE_AS_TEMPLATE.md)

---

## TL;DR — One-Command Setup

### Option A: GitHub Template (Recommended for new projects)

1. On the AI Toolbox repository page click **"Use this template" → "Create a new repository"**
2. Fill in your repo name and click **"Create repository"**
3. Clone and run setup:

```bash
# Linux / macOS
git clone https://github.com/YOUR-ORG/YOUR-REPO.git my-project
cd my-project
bash .agent/scripts/setup.sh
```

```powershell
# Windows
git clone https://github.com/YOUR-ORG/YOUR-REPO.git my-project
cd my-project
powershell -ExecutionPolicy Bypass -File .agent\scripts\setup.ps1
```

Full step-by-step guide: **[USE_AS_TEMPLATE.md](USE_AS_TEMPLATE.md)**

---

### Option B: Git Clone
```bash
git clone https://github.com/mrAibo/AI_Toolbox.git my-project
cd my-project
bash .agent/scripts/bootstrap.sh
```

### Option C: Release Download (Recommended for users)
Download the latest release from https://github.com/mrAibo/AI_Toolbox/releases, then extract and run bootstrap.

```bash
# Linux/macOS — replace X.Y.Z with the latest version
curl -sL https://github.com/mrAibo/AI_Toolbox/releases/download/vX.Y.Z/ai-toolbox-vX.Y.Z.tar.gz | tar xz
cd AI_Toolbox
bash .agent/scripts/bootstrap.sh

# Windows — download the .zip from the Releases page, extract, then:
cd AI_Toolbox
powershell -ExecutionPolicy Bypass -File .agent\scripts\bootstrap.ps1
```

That's it. Bootstrap detects your AI clients and configures everything automatically.

**Optional but recommended:**
```bash
cargo install --git https://github.com/rtk-ai/rtk && rtk init -g   # Token optimization (60-90% savings)
go install github.com/steveyegge/beads/cmd/bd@v0.63.3 && bd init      # Task tracking
```

---

## What Bootstrap Does

The bootstrap script (`.agent/scripts/bootstrap.sh` / `.ps1`) automatically:
- ✅ Detects installed AI clients (Qwen Code, Claude Code, Codex CLI, OpenCode, Cursor, Windsurf, RooCode/Cline, Gemini CLI, Aider)
- ✅ Creates router files (`CLAUDE.md`, `QWEN.md`, `CODERULES.md`, `OPENCODERULES.md`, etc.)
- ✅ Creates `.agent/memory/` structure with seed content
- ✅ Creates `.agent/rules/` with safety, testing, and TDD rules
- ✅ Sets up Git pre-commit hook via `verify-commit.sh/.ps1`
- ✅ Configures per-client hooks where supported (Claude Code, Qwen Code, Codex CLI)
- ✅ Updates `.gitignore` with AI Toolbox entries

No manual configuration needed for supported clients. Bootstrap handles it all.

---

## Manual Installation (Per Client)

### Qwen Code (Full Tier — Recommended)

Qwen Code gets the deepest integration: 6 hooks + 8 sub-agents.

1. **Clone + Bootstrap:**
   ```bash
   git clone https://github.com/mrAibo/AI_Toolbox.git my-project
   cd my-project
   bash .agent/scripts/bootstrap.sh
   ```
2. **Hooks are automatic** — bootstrap creates `.qwen/settings.json` with all 6 hooks.
3. **Sub-agents** — 8 agents in `.qwen/agents/` delegate automatically (reviewer, tester, frontend, backend, security, performance, documenter, handover).
4. **Start:** `qwen` — hooks activate on session start.

Full details: **[.agent/rules/qwen-code.md](.agent/rules/qwen-code.md)**

### Claude Code (Full Tier)

1. **Clone + Bootstrap** (as above).
2. **Hooks** — bootstrap configures `.claude.json` with pre-command and stop hooks.
3. **Agent Teams** — Claude Code's native multi-agent works with AI Toolbox workflows.
4. **Start:** `claude` — hooks run automatically.

### Codex CLI (Standard Tier)

1. **Clone + Bootstrap** (as above).
2. **Configure hooks:**
   ```bash
   cp .agent/templates/clients/.codex-hooks.json .codex/hooks.json
   ```
3. **Enable hooks** in `~/.codex/config.toml` or `.codex/config.toml`:
   ```toml
   [features]
   codex_hooks = true
   ```
4. **Optional:** Copy full config template:
   ```bash
   cp .agent/templates/clients/.codex-config.toml .codex/config.toml
   ```
5. **Start:** `codex` — reads `AGENTS.md` automatically.

Full guide: **[docs/setup-codex.md](docs/setup-codex.md)**

### OpenCode (Standard Tier)

1. **Clone + Bootstrap** (as above).
2. **Configure:**
   ```bash
   cp .agent/templates/clients/opencode-config.json opencode.json
   ```
3. **Edit** `opencode.json` to set your provider and model.
4. **Optional:** Copy skills:
   ```bash
   cp -r .agent/skills/* .opencode/skills/
   ```
5. **Start:** `opencode` — reads `AGENTS.md` automatically.

**Available commands:** `/boot`, `/sync`, `/handover`, `/templates`

Full guide: **[docs/setup-opencode.md](docs/setup-opencode.md)**

### Cursor (Standard Tier)

1. **Clone + Bootstrap** — creates `.cursorrules` automatically.
2. **Hooks** — bootstrap configures Cursor's hook system.
3. **Start:** Open project in Cursor.

### RooCode / Cline (Standard Tier)

1. **Clone + Bootstrap** — creates `.clinerules` automatically.
2. **Hooks** — available in v3.36+.
3. **Start:** Open project in RooCode/Cline.

### Windsurf (Standard Tier)

1. **Clone + Bootstrap** — creates `.windsurfrules` automatically.
2. **Hooks** — bootstrap configures Windsurf hooks.
3. **Start:** Open project in Windsurf.

### Gemini CLI (Basic Tier)

1. **Clone + Bootstrap** — creates `GEMINI.md` automatically.
2. **No hooks** — safety rules are enforced via file-based instructions.
3. **Manual sync:** Run `bash .agent/scripts/sync-task.sh` at session start.
4. **Start:** `gemini`.

### Aider (Basic Tier)

1. **Clone + Bootstrap** — creates `CONVENTIONS.md` and `.aider.conf.yml`.
2. **No hooks** — safety rules are soft reminders.
3. **Start:** `aider`.

### Pi — Inflection AI (Basic Tier)

1. **Clone + Bootstrap** — creates `PI.md` automatically.
2. **No CLI** — Pi is a web-only client at [pi.ai](https://pi.ai). No local installation needed.
3. **Manual context:** Paste `PI.md` (and relevant memory files) into the Pi chat at the start of each session.
4. **No hooks** — safety rules are soft reminders.

Full guide: **[docs/setup-pi.md](docs/setup-pi.md)**

### Antigravity (Full Tier)

1. **Clone + Bootstrap** — creates `SKILL.md`.
2. **Native slash commands:** `/start`, `/sync`, `/handover`.
3. **Artifact workflows** — premium agentic experience with native artifacts.

---

## Prerequisites

### Platform Prerequisites

**Windows users:** Before installing Rust tools, ensure you have a C++ linker:
- **Option A (Recommended):** Visual Studio Build Tools with "Desktop development with C++" workload (~2-3 GB)
  - Download: https://visualstudio.microsoft.com/downloads/
- **Option B (Lighter):** MinGW-w64 (~200-400 MB)
  - Download: https://www.mingw-w64.org/downloads/
- **Option C (Minimal):** During Rust installation, select option `3)` (GNU ABI) — works for most cases without extra tooling

**Linux/macOS:** No additional prerequisites needed beyond Rust and Go.

### Recommended Tools

#### rtk (Rust Token Killer)
Compresses test/build output by 60-90%, saving tokens and keeping the AI focused.
```bash
# ⚠️ IMPORTANT: Use --git flag! The crates.io "rtk" is a different project (Rust Type Kit).
cargo install --git https://github.com/rtk-ai/rtk
rtk init -g
```
- **Unix/macOS:** Installs pre-execution hooks for your AI client.
- **Windows:** Falls back to `--claude-md` mode (fully functional).
- **If Rust is NOT installed:** Install from https://rustup.rs/

#### Beads (Task Tracker)
Git-backed CLI task tracker for out-of-context planning.
```bash
go install github.com/steveyegge/beads/cmd/bd@v0.63.3
bd init
```
- **Alternative:** Download from https://github.com/steveyegge/beads/releases
- **If Go is NOT installed:** Install from https://go.dev/dl/

#### bat & rg (ripgrep)
Modern replacements for `cat` and `grep`:
```bash
cargo install bat ripgrep
# or: brew install bat ripgrep
```

---

## MCP Servers (Optional but Recommended)

MCP servers extend your AI with external resources (docs, web, GitHub, memory).

**Claude Code:**
```bash
claude mcp add context7 npx -y @upstash/context7-mcp
claude mcp add sequential-thinking npx -y @modelcontextprotocol/server-sequential-thinking
claude mcp add filesystem npx -y @modelcontextprotocol/server-filesystem .
claude mcp add fetch npx -y @modelcontextprotocol/server-fetch
```

**Other clients:** Copy the appropriate template from `.agent/templates/mcp/`:
- Qwen Code → `mcp-qwen.json`
- Cursor → `mcp-cursor.json`
- RooCode/Cline → `mcp-clinerules.json`
- Windsurf → `mcp-windsurf.json`
- Gemini CLI → `mcp-gemini.json`
- Aider → `mcp-aider.yml`

**Profiles:**
| Profile | Servers | When to Use |
|---------|---------|-------------|
| **minimal** | context7, sequential-thinking | Quick tasks |
| **developer** | + filesystem, fetch | Daily work (recommended) |
| **full** | + github, memory | Full project work |

Full guide with security rules and troubleshooting: **[docs/mcp-guide.md](docs/mcp-guide.md)**

---

## Verify `.gitignore`

Bootstrap handles this automatically. Verify these entries exist:
```text
# AI Toolbox specific
.beads/
.agent/memory/session-handover.md
.agent/memory/current-task.md
```

---

## For AI Agents

If you are an AI agent reading this file, follow these steps:

1. **Detect your environment** (OS, AI client identity, available tools).
2. **Download core files:**
   ```bash
   # Linux/macOS
   git clone https://github.com/mrAibo/AI_Toolbox.git /tmp/ai_toolbox_tmp
   cp -r /tmp/ai_toolbox_tmp/.agent .
   cp /tmp/ai_toolbox_tmp/AGENT.md .
   cp /tmp/ai_toolbox_tmp/SKILL.md .
   rm -rf /tmp/ai_toolbox_tmp

   # Windows (PowerShell)
   git clone https://github.com/mrAibo/AI_Toolbox.git $env:TEMP\ai_toolbox_tmp
   Copy-Item -Path "$env:TEMP\ai_toolbox_tmp\.agent" -Destination ".\" -Recurse -Force
   Copy-Item -Path "$env:TEMP\ai_toolbox_tmp\AGENT.md" -Destination ".\" -Force
   Copy-Item -Path "$env:TEMP\ai_toolbox_tmp\SKILL.md" -Destination ".\" -Force
   Remove-Item -Path "$env:TEMP\ai_toolbox_tmp" -Recurse -Force
   ```
3. **Run bootstrap** to create router files and memory structure:
   ```bash
   # Linux/macOS
   bash .agent/scripts/bootstrap.sh
   # Windows
   powershell .agent/scripts/bootstrap.ps1
   ```
4. **Configure MCP servers** if your client supports it (see MCP section above).
5. **Read `AGENT.md`** to understand your operational bounds.
6. **Report to user:**
   > "✅ **AI Toolbox Environment initialized successfully.** The framework `.agent/` and rules are in place. Optional tools like `rtk` and `Beads` have been checked/installed. I have read the `AGENT.md` contract and am ready to work!"

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Bootstrap fails | Ensure you have `git` and execute permission on scripts |
| Hooks not running | Check `.git/hooks/pre-commit` exists; verify client-specific config |
| `rtk` not found | Ensure Rust is installed; use `--git` flag (not crates.io) |
| `bd` not found | Ensure Go is installed; use `steveyegge/beads` (not fork) |
| MCP servers failing | Ensure Node.js and `npx` are installed |
| Router files missing | Re-run `bootstrap.sh` / `.ps1` |
| Windows hook issues | Use `.ps1` scripts; ensure ExecutionPolicy allows |
