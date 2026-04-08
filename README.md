# 🚀 AI Toolbox: Universal Terminal AI Workflow

A robust, reusable foundation for terminal-based AI-assisted development. 

This repository provides a strict workflow contract for AI agents like **Claude Code**, **Qwen Code**, and **Gemini CLI**. It solves the three biggest problems of terminal-based AI development: Context Bloat, Project Amnesia, and Execution Drift.

---

## 🎯 The Purpose

Terminal AI agents are powerful, but without constraints, they tend to:
- Lose track of long-term architecture decisions.
- Dump 10,000-line raw build logs into the chat context, wasting tokens.
- Start writing code immediately without planning or verifying.
- Forget how to run tests or start the environment after a restart.

This toolbox fixes that by introducing a **Memory Layer**, a **Rule Layer**, and an **Automation Layer**.

---

## 📂 Architecture & Memory Contract

The repository enforces a strict separation between human instructions, AI workflow rules, and durable project memory.

```text
AI_Toolbox/
├── README.md                     # Human-facing overview (You are here)
├── AGENT.md                      # The AI's primary execution contract
├── SKILL.md                      # Antigravity Skill manifest (Antigravity-only)
├── GEMINI.md                     # Gemini CLI context file
├── CLAUDE.md                     # Claude Code router file
├── QWEN.md                       # Qwen Code router file
├── CONVENTIONS.md                # Aider router file
├── .cursorrules                  # Cursor router file
├── .clinerules                   # RooCode / Cline router file
├── .windsurfrules                # Windsurf router file
├── .claude.json                  # Claude Code hook configuration (bootstrap-generated)
├── .aider.conf.yml               # Aider configuration file (bootstrap-generated)
├── .gitignore                    # Ignores local output and temporary files
│
├── .agent/                       # The AI's "Brain"
│   ├── config/                   # Client capability definitions
│   │   └── client-capabilities.json  # Tier matrix (documentation)
│   │
│   ├── memory/                   # Durable project state
│   │   ├── current-task.md            # The AI's active todo list
│   │   ├── architecture-decisions.md  # Long-term architecture ADRs
│   │   ├── integration-contracts.md   # APIs, schemas, data expectations
│   │   ├── runbook.md                 # Recurring operational procedures
│   │   ├── session-handover.md        # Unfinished work for the next session
│   │   └── active-session.md          # Live status of current session
│   │
│   ├── rules/                    # Hard execution constraints
│   │   ├── safety-rules.md            # Prevention of destructive commands
│   │   ├── testing-rules.md           # Verification requirements (Bug Fix Seq)
│   │   ├── stack-rules.md             # Allowed languages & dependencies
│   │   ├── antigravity.md             # Antigravity-specific extensions
│   │   ├── qwen-code.md               # Qwen Code Full-Tier extensions
│   │   ├── mcp-rules.md               # MCP server usage constraints
│   │   ├── tool-integrations.md       # How rtk, Beads, Superpowers work together
│   │   ├── tdd-rules.md               # Mandatory RED-GREEN-REFACTOR cycle
│   │   ├── template-usage.md          # When to use 413+ specialist templates
│   │   └── status-reporting.md        # When/how the agent reports progress
│   │
│   ├── scripts/                  # Automation & Hooks
│   │   ├── bootstrap.sh / .ps1        # Initial repo setup
│   │   ├── hook-pre-command.sh / .ps1 # Terminal safety guard (rtk check)
│   │   ├── hook-stop.sh / .ps1        # Memory consolidation guard
│   │   ├── verify-commit.sh / .ps1    # Git pre-commit logic
│   │   └── sync-task.sh / .ps1        # Task tracker synchronization
│   │
│   ├── templates/                # Standardized formats
│   │   ├── adr-template.md            # Architecture Decision Record
│   │   ├── antigravity-plan.md        # Antigravity native plan
│   │   ├── issue-template.md          # Internal bug/issue report
│   │   ├── task-template.md           # Task definition
│   │   ├── multi-agent-coordination.md # Sub-agent task tracking
│   │   ├── clients/                   # Client-specific configs (QWEN.md, CONVENTIONS.md, .aider.conf.yml, .claude.json)
│   │   └── mcp/                       # MCP configs (6 clients + master config)
│   │
│   └── workflows/                # Workflow definitions
│       ├── start.md / sync.md         # Routine automation
│       ├── handover.md                # Session wrap-up
│       ├── plan.md                    # Planning mode
│       ├── adr.md                     # ADR creation
│       ├── unified-workflow.md        # 9-step task execution (TASK→CLOSE)
│       ├── bug-fix.md                 # 5-phase bug fix (Repro→Record)
│       ├── code-review.md             # Pre-merge review checklist
│       ├── branch-finish.md           # Branch completion steps
│       ├── multi-agent.md             # Parallel agent orchestration
│       └── use-template.md            # Template selection & adaptation
│
├── docs/                       # Detailed human guides (Setup, MCP, FAQ)
├── examples/                   # Sample workflows
└── prompts/                    # Quick-start prompts for the AI agent
```

---

## ⚙️ The Core Stack

This workflow assumes the use of a few key tools to keep the AI disciplined:

1. **[rtk (Rust Token Killer)](https://github.com/rtk-ai/rtk)**
   A console proxy optimizer. Heavy commands (like `pytest`, `mvn test`, `npm run build`) and large logs must be read through `rtk`. It compresses errors and tracebacks by 60-90%, saving tokens and keeping the AI focused. **Setup:** `cargo install --git https://github.com/rtk-ai/rtk` + `rtk init -g`.
2. **[Beads](https://github.com/steveyegge/beads)** (Recommended)
   A local CLI task tracker. It moves the execution plan out of the AI's chat context and into a Git-backed graph. **Setup:** `go install github.com/steveyegge/beads@latest` + `bd init`.
3. **[Superpowers](https://github.com/obra/superpowers)** — **Methodology Source**
   The original source for TDD, brainstorming, debugging, code review, and planning skills. AI Toolbox `.agent/rules/` and `.agent/workflows/` are the **platform-universal adaptations** of these skills — no separate install needed. Works with any AI client.
4. **[Template Bridge](https://github.com/maslennikov-ig/template-bridge)** — **Template Source**
   Provides access to 413+ specialist agent templates in 26 categories. Access via `npx claude-code-templates@latest --agent {category}/{name}`. AI Toolbox `/templates` command provides unified access.
5. **Terminal AI Agents**
   - **[Qwen Code](https://github.com/QwenLM/qwen-code)**: Full-Tier client with hooks, sub-agents, skills, and commands.
   - **[Claude Code](https://docs.anthropic.com/en/docs/claude-code)**: Full-Tier client with native plugin support.
   - **[Cursor](https://cursor.sh/)**: Standard-Tier client via `.cursorrules`.
   - **[Gemini CLI](https://geminicli.com)**: Basic-Tier client via `GEMINI.md`.
   - **[Aider](https://aider.chat/)**: Basic-Tier client via `CONVENTIONS.md`.
6. **[MCP Servers](https://modelcontextprotocol.io/)**
   Model Context Protocol (MCP) integrations for GitHub, Docs, Databases, etc., to connect agents safely to resources. **Setup:** See [docs/mcp-guide.md](docs/mcp-guide.md).

**AI Toolbox is the adapter layer** — it translates Superpowers methodology and Template Bridge templates for ANY AI client, not just Claude Code. No duplication, just platform-universal adaptation.

Full integration details, commands, and how everything works together: **[.agent/rules/tool-integrations.md](.agent/rules/tool-integrations.md)**.

### 🎻 How the Ensemble Works

All tools work together automatically:

1. **You describe a feature** → Beads creates the task
2. **AI brainstorms** → Superpowers skills guide the analysis
3. **AI plans** → Tasks broken into 2-5 min steps
4. **AI implements with TDD** → RED → GREEN → REFACTOR (enforced by rules)
5. **rtk optimizes** → Every test/build uses 60-90% fewer tokens
6. **MCP provides resources** → Docs, web content, GitHub on demand
7. **Templates fill gaps** → 413+ specialist agents when needed
8. **AI reviews itself** → Code Review Workflow before finish
9. **Beads tracks progress** → Task closed, next one ready

No manual orchestration needed. Just describe what you want.

### The Complete Flow

```
User: "Build feature X"
  → Beads:     bd create "feature X" → task in graph
  → Superpowers: brainstorming → clarify requirements
  → Beads:     bd create subtasks → decomposed work
  → For each subtask:
      → Superpowers: test-driven-development OR systematic-debugging
      → rtk: rtk test → shows only failures (60-90% less tokens)
      → MCP: context7 → docs on demand
      → Beads: bd close → task done
  → Superpowers: verification-before-completion → final check
  → Beads: bd close "feature X complete" → done
```

---

## 🎯 Client Capability Matrix

The framework adapts its instructions to each client's actual capabilities via a **3-Tier Orchestration System**:

| Client | Tier | Hooks | Multi-Agent | File Rules | Router File |
|--------|------|-------|-------------|------------|-------------|
| Claude Code | 🥇 Full | ✅ | ✅ Agent Teams | ✅ | `CLAUDE.md` |
| Antigravity | 🥇 Full | ✅ | ✅ Agent Manager | ✅ | `SKILL.md` |
| Qwen Code | 🥇 Full | ✅ | ✅ SubAgents | ✅ | `QWEN.md` |
| Cursor | 🥈 Standard | ✅ | ⚠️ Background | ✅ | `.cursorrules` |
| RooCode / Cline | 🥈 Standard | ✅ (v3.36+) | ❌ | ✅ | `.clinerules` |
| Windsurf | 🥈 Standard | ✅ | ❌ | ✅ | `.windsurfrules` |
| Gemini CLI | 🥉 Basic | ❌ | ❌ | ✅ | `GEMINI.md` |
| Aider | 🥉 Basic | ❌ | ❌ | ✅ | `CONVENTIONS.md` |

**Tier behavior:**
- **Full:** Hooks enforce safety rules; multi-agent orchestration available; full automation via sync/handover scripts.
- **Standard:** Hooks available for sync/handover; no multi-agent; rules enforced via file-based routing.
- **Basic:** No hooks — safety rules are **soft reminders only**. Memory and Rules layers still active.



Want to convert an existing project into an AI Toolbox compliant project? Open your terminal AI (Claude Code, Qwen Code, Gemini CLI, RooCode/Cline, Cursor, Windsurf, Aider, or Antigravity) in your project directory and paste this exact prompt:

```text
Follow the setup instructions here to initialize the AI Toolbox environment:
https://raw.githubusercontent.com/mrAibo/AI_Toolbox/main/INSTALL.md
```

The AI will autonomously download the `.agent` folder, `AGENT.md`, run the bootstrap script to create the routers, and report back when finished.

---

### 🔌 MCP Integration (Optional)

Extend your AI agent with external tools via the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/).

**Quick Setup:**

```bash
# Minimal — documentation + reasoning
claude mcp add context7 npx -y @upstash/context7-mcp
claude mcp add sequential-thinking npx -y @modelcontextprotocol/server-sequential-thinking

# Developer (recommended) — + filesystem access + web fetch
claude mcp add filesystem npx -y @modelcontextprotocol/server-filesystem .
claude mcp add fetch npx -y @modelcontextprotocol/server-fetch
```

| Profile | Servers | When to Use |
|---------|---------|-------------|
| **minimal** | context7, sequential-thinking | Quick tasks |
| **developer** | + filesystem, fetch | Daily work (recommended) |
| **full** | + github, memory | Full project work |

Full config templates, security rules, and troubleshooting: **[docs/mcp-guide.md](docs/mcp-guide.md)**

---

### 1. Quick Setup (Recommended)

Run the one-command setup script — it detects your environment, installs optional tools, and configures everything:

```bash
# Linux/macOS
bash .agent/scripts/setup.sh

# Windows
powershell -ExecutionPolicy Bypass -File .agent\scripts\setup.ps1
```

The script will:
- ✅ Detect installed AI clients and let you pick a primary one
- ✅ Run bootstrap (creates all router files and memory structure)
- ✅ Detect your project stack (Node.js, Rust, Python, Go, etc.)
- ✅ Offer to install rtk (token optimization) and Beads (task tracking)
- ✅ Configure MCP servers for your primary client

### 2. Manual Initialization (Direct Clone)
1. **Set up the repo:** Clone this repository as a starting point.
2. **Run the bootstrap script** for your OS to ensure all folders and router files exist:
   - Linux/macOS: `bash .agent/scripts/bootstrap.sh`
   - Windows: `powershell .agent/scripts/bootstrap.ps1`
3. **Connect your AI agent** to the workspace.

### 2. For AI Agents (Manual setup)
Give your terminal AI agent this exact prompt to start a project:

> *"Use this repository as the strict project workflow standard. Read AGENT.md first and follow its Boot Sequence. Do not start coding until the memory is initialized."*

*(See the `prompts/` folder for German and Russian translations).*

---

## 🏁 How to Start Working

Depending on whether you are beginning something entirely new or just picking up yesterday's work, use one of the two approaches below:

### Scenario A: Starting a New Project or Major Feature
If you are at the very beginning of a project or want to plan a large new architecture, you need to trigger the **Brainstorming & Planning Mode**. 

1. Launch your AI agent in the terminal.
2. Give a **Planning Prompt**:
   > *"I want to build a [describe project/feature]. According to our AGENT.md rules, do not write code yet. Analyze this request, identify constraints, and propose 2-3 architectural approaches to brainstorm."*
3. The AI will brainstorm with you. Once you decide on a path, it will automatically record the decision in `.agent/memory/architecture-decisions.md`, create a structured task plan (e.g., via `bd`), and then begin execution.

### Scenario B: Continuing an Existing Project
If you are returning to a project with existing memory, let the AI catch up.

1. Launch your AI agent in the terminal.
2. Give an **Execution Prompt**:
   > *"We are continuing our work. Please execute your Boot Sequence to read our memories and sync the tasks, then pick up the next step."*
3. The AI autopilot engages: It restores its context from `.agent/memory/`, checks `current-task.md`, and begins implementing the exact next step without getting sidetracked.

### Scenario C: Antigravity Native Mode
If you are using the **Antigravity** assistant, the toolbox is a first-class citizen.

1. Launch Antigravity.
2. Use **Slash Commands**:
   - Type `/start` to boot the project memory.
   - Type `/sync` to update your task list artifact.
   - Type `/handover` to wrap up and generate a walkthrough.
3. Antigravity will automatically use native artifacts (`implementation_plan.md`, `task.md`) for a premium experience.

---

## 🧠 The Agent Workflow

When the AI agent works in this repository, it follows a strict sequence defined in `AGENT.md`:

1. **Boot Sequence:** 
   - **Environmental Check:** Verify `.agent/` and required binaries (`rtk`, `bd`).
   - **Context Recovery:** Read `architecture-decisions.md` and `integration-contracts.md`.
   - **WIP Check:** Read `session-handover.md` to see where the last session stopped.
   - **Task Sync:** Run `sync-task.sh/ps1` to load the current task list.
   - **Summarization:** The agent provides a brief update on what it recovered.
2. **Execution Flow:**
   - **Planning:** Identify constraints and update the plan.
   - **Implementation:** Write code; prefix heavy commands with `rtk`.
   - **Verification:** Run tests or verify output before claiming success.
3. **Consolidation:** Before shutting down, the agent updates the handover and memory files.

---

## 🛡️ Hooks & Safety

The repository includes shell and PowerShell hooks in `.agent/scripts/`.
**These hooks are installed automatically by `bootstrap.sh/ps1`** — they create a Git pre-commit hook in `.git/hooks/pre-commit` that calls `verify-commit.sh/.ps1`. No manual setup required.

Additionally, `setup.sh/ps1` configures per-client hooks for Claude Code, Qwen Code, Cursor, Cline, and Windsurf:
- **Pre-command hook:** Blocks the AI from running heavy test/build commands without the `rtk` prefix, and prevents raw `cat` of massive log files.
- **Stop hook:** Reminds the AI to consolidate its memory into `session-handover.md` before exiting.
- **Commit verification:** Enforces tier badges on router files, warns about missing TDD coverage, and checks for broken markdown links.

---

## 🤖 Qwen Code Integration

Qwen Code (`qwen`) is a **Full-Tier** client with the deepest AI Toolbox integration:

### Native Hooks (Automatic)
When bootstrap detects Qwen Code, it automatically creates `.qwen/settings.json` with 6 hooks:

| Hook | Trigger | Script | Purpose |
|---|---|---|---|
| `SessionStart` | Session beginnt | `sync-task.sh` | Task-State laden |
| `PreToolUse` | Vor Bash-Befehl | `hook-pre-command-qwen.sh` | Heavy-Command-Erkennung, empfiehlt `rtk` |
| `PostToolUse` | Nach write/edit | `hook-post-tool-qwen.sh` | Secret-Scanner in geschriebenen Dateien |
| `Stop` | Vor Antwort-Ende | `hook-stop-qwen.sh` | Memory-Dateien aktualisieren |
| `SessionEnd` | Session endet | `hook-session-end-qwen.sh` | Full Memory Consolidation + bd prime |
| `PreCompact` | Vor Kontext-Komprimierung | `hook-pre-compact-qwen.sh` | Architect-Kontext injizieren (überlebt Kompaktierung) |

**Kein Flag nötig:** Hooks sind standardmäßig aktiviert, sobald `.qwen/settings.json` die Hook-Konfiguration enthält.

### 8 Sub-Agenten (Automatische Delegation)
Qwen Code's natives Sub-Agent-System ermöglicht automatische Parallelverarbeitung. Die folgenden Agenten liegen in `.qwen/agents/` und werden bei passenden Tasks automatisch delegiert:

| Agent | Zweck | Parallel zu |
|---|---|---|
| `ai-toolbox-reviewer` | Code Review (Sicherheit, TDD, Qualität) | Tester, Performance |
| `ai-toolbox-tester` | TDD & Testing (RED-GREEN-REFACTOR) | Implementation, Documenter |
| `ai-toolbox-frontend` | UI/Components/CSS/Templates | Backend, Security |
| `ai-toolbox-backend` | API/Server/DB/Infrastruktur | Frontend, Tester |
| `ai-toolbox-security` | Secrets/Vulnerabilities/Permissions | Reviewer, Performance |
| `ai-toolbox-performance` | Bottlenecks/Memory/Optimierung | Tester, Security |
| `ai-toolbox-documenter` | Docs/Runbook/ADRs/Handover | Implementation, Testing |
| `ai-toolbox-handover` | Session-End Memory Konsolidierung | — |

**Parallele Szenarien:**
```
Feature-Entwicklung:  Frontend + Backend + Tester (3 parallel)
Bug-Fix:              Tester + Implementation + Security + Performance (4 parallel)
CI-Check vor Push:    Tester + Security + Documenter + Performance (4 parallel)
```

Agenten werden automatisch delegiert basierend auf der `description` — Phrasen wie `"use PROACTIVELY"` erhöhen die Delegationswahrscheinlichkeit. Expliziter Aufruf: `@ai-toolbox-reviewer review the recent changes`.

### Manuelles Setup (falls Bootstrap nicht lief)
```bash
# Linux/macOS
# Hooks werden automatisch von bootstrap.sh erstellt wenn qwen erkannt wird
# Oder manuell:
cp .agent/templates/clients/qwen-hooks-unix.jsonc ~/.qwen/settings.json
# Pfade in der JSONC-Datei anpassen

# Windows
# Hooks werden automatisch von bootstrap.ps1 erstellt
# Konfiguration liegt bereits in C:\Users\crown\.qwen\settings.json
```

---

## 📚 Further Reading

Check the `docs/` folder for detailed guides:
- `setup-linux.md` & `setup-windows.md`
- `mcp-guide.md` (How to integrate Model Context Protocol servers safely)
- `faq.md`
