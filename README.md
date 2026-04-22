# 🚀 AI Toolbox: Universal Terminal AI Workflow

![Latest Release](https://img.shields.io/github/v/release/mrAibo/AI_Toolbox?include_prereleases&label=version)

> **Terminal AI agents are brilliant — but without discipline, they forget, drift, and waste tokens.**

AI Toolbox solves the three hardest problems of working with AI in your terminal:
- **Context Bloat** — AI dumps 10,000-line build logs into the chat, burning tokens and losing focus.
- **Project Amnesia** — After a restart, the AI forgets architecture decisions, test patterns, and where it left off.
- **Execution Drift** — The AI starts coding before planning, skips tests, and claims success without verification.

This project introduces a **Memory Layer**, a **Rule Layer**, and an **Automation Layer** that keep terminal AI agents disciplined, persistent, and token-efficient. It works with **10 AI clients** out of the box — Claude Code, Antigravity, Qwen Code, Gemini CLI, Aider, Cursor, Windsurf, RooCode/Cline, Codex CLI, and OpenCode — adapting its instructions to each client's actual capabilities.

**Production-grade:** Comprehensive CI validation (18 steps across 6 test suites: syntax, hooks, integration, git hooks, content, MCP schema), security-hardened hooks with full cross-shell parity, append-only audit trail, central client config with automated generator and schema validation, atomic-safe concurrent writes, and 11 structured workflows from TDD to multi-agent orchestration.

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
├── USE_AS_TEMPLATE.md            # GitHub Template onboarding guide (PR9)
├── AGENT.md                      # The AI's primary execution contract
├── SKILL.md                      # Antigravity Skill manifest (Antigravity-only)
├── GEMINI.md                     # Gemini CLI context file
├── CLAUDE.md                     # Claude Code router file
├── QWEN.md                       # Qwen Code router file
├── CONVENTIONS.md                # Aider router file
├── .cursorrules                  # Cursor router file
├── .clinerules                   # RooCode / Cline router file
├── .windsurfrules                # Windsurf router file
├── CODERULES.md                  # Codex CLI router file
├── OPENCODERULES.md              # OpenCode router file
├── .claude.json                  # Claude Code hook configuration (bootstrap-generated)
├── .aider.conf.yml               # Aider configuration file (bootstrap-generated)
├── .gitignore                    # Ignores local output and temporary files
│
├── .ai-toolbox/                  # Central configuration (PR4)
│   └── config.json               # Single source of truth for all 10 clients + 3 tiers
│
├── .agent/                       # The AI's "Brain"
│   ├── config/                   # Client capability definitions
│   │   └── client-capabilities.json  # Tier matrix (documentation)
│   │
│   ├── memory/                   # Durable project state
│   │   ├── memory-index.md          # Overview of all memory files (READ FIRST)
│   │   ├── current-task.md            # The AI's active todo list
│   │   ├── architecture-decisions.md  # Long-term architecture ADRs
│   │   ├── integration-contracts.md   # APIs, schemas, data expectations
│   │   ├── runbook.md                 # Recurring operational procedures
│   │   ├── session-handover.md        # Unfinished work for the next session
│   │   ├── active-session.md          # Live status of current session
│   │   └── audit.log                  # Append-only audit trail (runtime, PR8)
│   │
│   ├── rules/                    # Hard execution constraints
│   │   ├── safety-rules.md            # Prevention of destructive commands
│   │   ├── testing-rules.md           # Verification requirements (Bug Fix Seq)
│   │   ├── stack-rules.md             # Allowed languages & dependencies
│   │   ├── security-policy.md         # Security rules and bypass procedures (PR7)
│   │   ├── client-detection.md        # Client selection priority rules (PR5)
│   │   ├── antigravity.md             # Antigravity-specific extensions
│   │   ├── qwen-code.md               # Qwen Code Full-Tier extensions
│   │   ├── mcp-rules.md               # MCP server usage constraints
│   │   ├── tool-integrations.md       # How rtk, Beads, Superpowers work together
│   │   ├── tdd-rules.md               # Mandatory RED-GREEN-REFACTOR cycle
│   │   ├── template-usage.md          # When to use 413+ specialist templates
│   │   ├── status-reporting.md        # When/how the agent reports progress
│   │   ├── parallel-execution.md      # When and how to parallelize operations
│   │   ├── receiving-code-review.md   # Anti-sycophancy, verify before implementing (PR2)
│   │   ├── root-cause-tracing.md      # Backward tracing through call stack
│   │   ├── defense-in-depth.md        # Multi-layer post-fix validation
│   │   ├── condition-based-waiting.md # Condition polling instead of timeouts
│   │   └── testing-anti-patterns.md   # Common testing mistakes
│   │
│   ├── scripts/                  # Automation & Hooks
│   │   ├── bootstrap.sh / .ps1        # Initial repo setup (silent, idempotent)
│   │   ├── setup.sh / .ps1            # Interactive setup wizard (client detection, tool install)
│   │   ├── hook-pre-command.sh / .ps1 # Terminal safety guard (rtk check, hardened PR7)
│   │   ├── hook-stop.sh / .ps1        # Memory consolidation + audit emit
│   │   ├── verify-commit.sh / .ps1    # Git pre-commit logic (tier badges, secret scan)
│   │   ├── commit-msg.sh / .ps1       # TDD enforcement for commits
│   │   ├── doctor.sh / .ps1           # Health check — validates entire setup + audit
│   │   ├── sync-task.sh / .ps1        # Task tracker synchronization
│   │   ├── lib-atomic-write.sh        # Atomic write helpers (PR1)
│   │   ├── lib-audit.sh / .ps1        # Audit event emission library (PR8)
│   │   ├── generate_client_files.py   # Central client file generator (PR4)
│   │   ├── generate-client-files.sh / .ps1  # Generator wrapper for CI (PR4)
│   │   ├── validate-toolbox-config.sh # Config structure validation (PR6)
│   │   ├── validate-adr.sh            # ADR required-field validation (PR6)
│   │   ├── verify-concurrency.sh      # Concurrent write stress test (PR1)
│   │   ├── bootstrap-parity-check.sh  # Verifies .sh/.ps1 equivalence
│   │   ├── check-trailing-newlines.sh # Ensures file formatting consistency
│   │   ├── validate-client-capabilities.sh # Client capability matrix validation
│   │   ├── test-scripts.sh            # Syntax validation for all scripts
│   │   ├── test-hooks.sh              # Functional tests for all hook scripts
│   │   ├── test-integration.sh        # End-to-end integration tests
│   │   ├── test-git-hooks.sh          # Git hook behavior tests
│   │   ├── test-content.sh            # Markdown content validation tests
│   │   ├── test-mcp-schema.sh         # MCP configuration schema tests
│   │   └── test-audit.sh              # Audit trail functional tests (PR8)
│   │
│   ├── skills/                   # Client-agnostic skill library (PR2)
│   │   ├── brainstorming/             # Structured brainstorming workflow
│   │   ├── tdd/                       # Test-driven development
│   │   ├── debugging/                 # Systematic debugging
│   │   ├── code-review/               # Pre-merge review
│   │   ├── receiving-code-review/     # Anti-sycophancy + verify before implementing
│   │   ├── safety/                    # Safety and destructive-action checks
│   │   ├── testing/                   # Testing patterns and anti-patterns
│   │   ├── parallel/                  # Parallel agent orchestration
│   │   └── branch-finish/             # Branch completion checklist
│   │
│   ├── templates/                # Standardized formats
│   │   ├── adr-template.md            # Architecture Decision Record (typed fields, PR6)
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

1. **[rtk (Rust Token Killer)](https://github.com/rtk-ai/rtk)** — **Optional but recommended**
   A console proxy optimizer. Heavy commands (like `pytest`, `mvn test`, `npm run build`) and large logs must be read through `rtk`. It compresses errors and tracebacks by 60-90%, saving tokens and keeping the AI focused. **Without rtk:** AI Toolbox works normally but uses more tokens for heavy commands. **Setup:** `cargo install --git https://github.com/rtk-ai/rtk` + `rtk init -g`.
2. **[Beads](https://github.com/steveyegge/beads)** — **Optional but recommended**
   A local CLI task tracker. It moves the execution plan out of the AI's chat context and into a Git-backed graph. **Without Beads:** Task tracking falls back to manual `.agent/memory/current-task.md` edits. All workflows still function. **Setup:** `go install github.com/steveyegge/beads/cmd/bd@v0.63.3` + `bd init`.
3. **[Superpowers](https://github.com/obra/superpowers)** — **Methodology Source**
   The original source for TDD, brainstorming, debugging, code review, and planning skills. AI Toolbox `.agent/rules/` and `.agent/workflows/` are the **platform-universal adaptations** of these skills — no separate install needed. Works with any AI client.
4. **[Template Bridge](https://github.com/maslennikov-ig/template-bridge)** — **Template Source**
   Provides access to 413+ specialist agent templates in 26 categories. Access via `npx claude-code-templates@0.1.0 --agent {category}/{name}`. AI Toolbox `/templates` command provides unified access.
5. **Terminal AI Agents**
   - **[Qwen Code](https://github.com/QwenLM/qwen-code)**: Full-Tier client with hooks, sub-agents, skills, and commands.
   - **[Claude Code](https://docs.anthropic.com/en/docs/claude-code)**: Full-Tier client with native plugin support.
   - **[Codex CLI](https://github.com/openai/codex)**: Standard-Tier client with hooks and config-based routing.
   - **[OpenCode](https://github.com/anomalyco/opencode)**: Standard-Tier client with commands, agents, and skills.
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
| Codex CLI | 🥈 Standard | ✅ | ❌ | ✅ | `CODERULES.md` |
| OpenCode | 🥈 Standard | ⚠️ Commands | ✅ Agents | ✅ | `OPENCODERULES.md` |
| Gemini CLI | 🥉 Basic | ❌ | ❌ | ✅ | `GEMINI.md` |
| Aider | 🥉 Basic | ❌ | ❌ | ✅ | `CONVENTIONS.md` |

> **Note:** Antigravity is an internal client with full integration. For publicly available clients, see [Claude Code](https://docs.anthropic.com/en/docs/claude-code/), [Qwen Code](https://qwenlm.github.io/), [Codex CLI](https://github.com/openai/codex), [OpenCode](https://github.com/anomalyco/opencode), [Cursor](https://cursor.com/), [RooCode](https://roocode.com/), [Windsurf](https://windsurf.com/), [Gemini CLI](https://ai.google.dev/), and [Aider](https://aider.chat/).

**Tier behavior:**
- **Full:** Hooks enforce safety rules; multi-agent orchestration available; full automation via sync/handover scripts.
- **Standard:** Hooks available for sync/handover; no multi-agent; rules enforced via file-based routing.
- **Basic:** No hooks — safety rules are **soft reminders only**. Memory and Rules layers still active.



Want to convert an existing project into an AI Toolbox compliant project? Open your terminal AI (Claude Code, Qwen Code, Gemini CLI, RooCode/Cline, Cursor, Windsurf, Codex CLI, OpenCode, Aider, or Antigravity) in your project directory and paste this exact prompt:

> *"Use this repository as the strict project workflow standard. Read AGENT.md first and follow its Boot Sequence. Do not start coding until the memory is initialized. See INSTALL.md for setup instructions."*

Alternatively, you can reference the installation guide directly:
- GitHub: https://github.com/mrAibo/AI_Toolbox/blob/main/INSTALL.md
- Raw: https://raw.githubusercontent.com/mrAibo/AI_Toolbox/main/INSTALL.md

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

### 0. Starting from GitHub Template (New Users)

If you are creating a **new project** from scratch, the fastest starting point is:

1. Click **[Use this template](https://github.com/mrAibo/AI_Toolbox/generate)** on GitHub to generate your own repository
2. Clone it locally
3. Run `setup.sh` / `setup.ps1` (see step 1 below)

Full details — including the difference between Template, `setup.sh`, and `bootstrap.sh` — are in **[USE_AS_TEMPLATE.md](USE_AS_TEMPLATE.md)**.

---

### 1. Quick Setup (Recommended)

Run the one-command setup script — it detects your environment, installs optional tools, and configures everything:

```bash
# Linux/macOS
bash .agent/scripts/setup.sh

# Windows
powershell -ExecutionPolicy Bypass -File .agent\scripts\setup.ps1
```

> **setup.sh vs bootstrap.sh:** `setup.sh` is the interactive wizard — it detects your AI clients, offers to install tools (rtk, Beads), and configures MCP servers. `bootstrap.sh` is the silent, idempotent version — it creates router files and memory structure without installing anything. Use `setup.sh` for new projects, `bootstrap.sh` for CI or when you already have tools installed.

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
3. **Verify setup:** Run `.agent/scripts/doctor.sh` (or `.ps1`) to check all components.
4. **Connect your AI agent** to the workspace.

### 3. For AI Agents (Manual setup)
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
