# Quick Start — AI Toolbox in 5 Minutes

This guide gets you up and running in under 5 minutes.

---

## Prerequisites

- **Git** installed
- **Terminal AI client** (Claude Code, Qwen Code, Gemini CLI, Cursor, Codex CLI, OpenCode, etc.)
- *(Optional)* **Rust** for rtk, **Go** for Beads

---

## Step 1: Create or Clone (1 min)

```bash
# New project
git clone https://github.com/mrAibo/AI_Toolbox.git my-project
cd my-project

# Or in an existing project
curl -sSL https://raw.githubusercontent.com/mrAibo/AI_Toolbox/main/INSTALL.md
# Follow the instructions
```

---

## Step 2: Bootstrap (1 min)

```bash
# Linux/macOS
bash .agent/scripts/bootstrap.sh

# Windows
powershell -ExecutionPolicy Bypass -File .agent\scripts\bootstrap.ps1
```

This creates:
- ✅ Router files for your AI client (`CLAUDE.md`, `QWEN.md`, `CODERULES.md`, `OPENCODERULES.md`, etc.)
- ✅ Memory files with seed content
- ✅ Rule files (safety, testing, TDD, MCP, code review, root cause tracing, defense in depth, etc.)
- ✅ Git pre-commit hook

---

## Step 3: Install rtk (1 min, optional but recommended)

```bash
# ⚠️ IMPORTANT: Use --git flag! The crates.io "rtk" is a different project.
cargo install --git https://github.com/rtk-ai/rtk
rtk init -g
```

rtk compresses test/build output by 60-90%, saving tokens and keeping the AI focused.

---

## Step 4: Start Your AI Agent (30 sec)

Open your AI client in the project directory. It will:
1. Read `AGENT.md` (or your client's router file) automatically
2. Run the Boot Sequence
3. Restore context from memory files
4. Be ready to work

**Useful commands** (available in supported clients):
| Command | Purpose |
|---------|---------|
| `/boot` | Boot AI Toolbox, recover session context |
| `/sync` | Sync task state from Beads/task tracker |
| `/handover` | Create session handover for next session |
| `/templates` | Browse 413+ specialist agent templates |
| `/doctor` | Health check — verify all components are working |

**Client-specific quick start:**
- **Qwen Code:** Hooks + 8 sub-agents auto-enabled. Use `@ai-toolbox-reviewer`, `@ai-toolbox-tester`, `@ai-toolbox-security` for parallel review, testing, and security audits.
- **Claude Code:** Hooks auto-configured. Use Agent Teams for parallel work.
- **Codex CLI:** Hooks enabled via `.codex/hooks.json` + `codex_hooks = true` in config.
- **OpenCode:** Use `/boot`, `/sync`, `/handover`, `/templates` commands. Sub-agents: `@ai-toolbox-reviewer`, `@ai-toolbox-tester`, `@ai-toolbox-security`.
- **Cursor / Windsurf / RooCode:** Rule files auto-created. Open project and start.
- **Gemini CLI / Aider:** File-based instructions. Run `sync-task.sh` manually at session start.

**Prompt to use:**
```
I want to build [describe your project/feature].
Per AGENT.md rules, do not code yet.
Analyze constraints, propose approaches, and let's plan.
```

---

## That's It

You now have:
- ✅ A structured AI workflow (11 workflows: TDD, bug-fix, code review, planning, multi-agent, etc.)
- ✅ Persistent project memory (architecture decisions, integration contracts, session handover)
- ✅ Safety rules (no destructive actions without confirmation)
- ✅ TDD enforcement (RED-GREEN-REFACTOR)
- ✅ Task tracking (if you installed Beads)
- ✅ Token optimization (if you installed rtk — saves 60-90% on heavy commands)
- ✅ **Automatic hooks** (Qwen Code, Claude Code, Codex CLI — auto-enabled by bootstrap)
- ✅ **Sub-Agents** for parallel work (Qwen Code: 8 agents; OpenCode: 3 agents; Claude Code: Agent Teams)
  - `reviewer` — Code review before merges
  - `tester` — TDD & testing (RED-GREEN-REFACTOR)
  - `security` — Secrets, vulnerabilities, permissions audit
  - Plus: frontend, backend, performance, documenter, handover (Qwen Code)

---

## Health Check

Run the doctor script to verify everything is set up correctly:
```bash
bash .agent/scripts/doctor.sh
# Windows:
powershell -ExecutionPolicy Bypass -File .agent\scripts\doctor.ps1
```

This checks:
- ✅ `.agent/` folder structure
- ✅ Router files exist
- ✅ Memory files initialized
- ✅ rtk and Beads installed (optional)
- ✅ Git hooks configured
- ✅ MCP servers (if configured)

---

## What's Next?

| If you want to... | Read |
|-------------------|------|
| Understand the full architecture | [docs/architecture.md](docs/architecture.md) |
| Install for a specific client | [INSTALL.md](INSTALL.md) |
| Set up MCP servers | [docs/mcp-guide.md](docs/mcp-guide.md) |
| See real examples | [examples/README.md](examples/README.md) |
| Contribute to AI Toolbox | [CONTRIBUTING.md](CONTRIBUTING.md) |
| See what changed | [CHANGELOG.md](CHANGELOG.md) |
