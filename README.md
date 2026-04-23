# AI Toolbox — Universal Terminal AI Workflow

[![Latest Release](https://img.shields.io/github/v/release/mrAibo/AI_Toolbox?label=version)](https://github.com/mrAibo/AI_Toolbox/releases)
[![CI](https://github.com/mrAibo/AI_Toolbox/actions/workflows/ci.yml/badge.svg)](https://github.com/mrAibo/AI_Toolbox/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

> Terminal AI agents are powerful — but without structure they forget context, dump 10,000-line logs into the chat, and start coding before planning.

AI Toolbox adds three layers on top of any terminal AI client:

| Layer | What it does |
|-------|-------------|
| **Memory** | Persists architecture decisions, task state, and session handover across restarts |
| **Rules** | Enforces TDD, safety guards, token-efficient output, and surgical changes |
| **Automation** | Hooks sync state on every command, handover on every session end |

Works with **10 AI clients** out of the box — no vendor lock-in.

---

## Quick Start

**New project (GitHub Template — recommended):**
1. On the **[repository page](https://github.com/mrAibo/AI_Toolbox)** click **"Use this template" → "Create a new repository"**
2. Fill in owner, repo name, and visibility — click **"Create repository"**
3. Clone your new repo locally and run setup:

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

> Full onboarding details: [USE_AS_TEMPLATE.md](USE_AS_TEMPLATE.md)

**Existing project (clone directly):**

```bash
# Linux / macOS
git clone https://github.com/mrAibo/AI_Toolbox.git my-project
cd my-project
bash .agent/scripts/setup.sh
```

```powershell
# Windows
git clone https://github.com/mrAibo/AI_Toolbox.git my-project
cd my-project
powershell -ExecutionPolicy Bypass -File .agent\scripts\setup.ps1
```

Setup detects your AI client, installs optional tools (rtk, Beads), and configures hooks automatically. A numbered checklist is printed for anything that needs manual action.

**Verify installation:**
```bash
bash .agent/scripts/doctor.sh       # Linux / macOS
powershell .agent/scripts/doctor.ps1   # Windows
```

---

## The Problem it Solves

Without AI Toolbox, a typical session looks like this:

```
Day 1:  AI plans feature X, writes code, claims it works
Day 2:  New session — AI has no memory, starts over, contradicts Day 1 decisions
Day 3:  AI runs "npm test" → dumps 8,000 lines of output → loses focus
Day 4:  AI skips tests, patches the wrong thing, breaks Day 1's code
```

With AI Toolbox:

```
Day 1:  AI reads session-handover.md → picks up exactly where Day 1 ended
        pre-command hook intercepts "npm test" → runs "rtk npm test" instead
        → shows only the 3 failing tests, not 8,000 lines
        → TDD rule enforces: write failing test first, then fix, then verify
Day 2:  hook-stop writes handover → next session resumes without repetition
```

---

## How it Works

Every session follows a fixed sequence defined in `AGENT.md`:

```
Session start  →  read memory-index.md
               →  run sync-task (loads current-task.md from Beads)
               →  read session-handover.md (unfinished work)

During work    →  pre-command hook blocks heavy commands without rtk
               →  TDD rules enforce RED → GREEN → REFACTOR
               →  large source-file reads trigger a "use git diff" reminder

Session end    →  hook-stop writes handover, caps history at 10 entries
               →  audit.log appended (append-only, gitignored)
```

The AI never loses context between sessions. If it restarts mid-task, it picks up exactly where it left off.

---

## The 9-Step Workflow

Every task — from a one-line fix to a multi-week feature — follows the same structure:

| Step | Name | What happens |
|------|------|-------------|
| 1 | **TASK** | Create Beads task: `bd create -t epic "Goal"` |
| 2 | **BRAINSTORM** | Design before code — constraints, 2–3 approaches, tradeoffs |
| 3 | **PLAN** | Break into 2–5 min subtasks, record decisions in ADRs |
| 4 | **ISOLATE** | Git worktree per task — no cross-contamination |
| 5 | **IMPLEMENT** | TDD: RED → GREEN → REFACTOR, no production code without a failing test |
| 6 | **REVIEW** | Self-review checklist before claiming done |
| 7 | **VERIFY** | Run tests, check for regressions, no silent completions |
| 8 | **FINISH** | Merge, update handover, close Beads task |
| 9 | **CLOSE** | `bd close` — marks task done, triggers next |

Full details: [.agent/workflows/unified-workflow.md](.agent/workflows/unified-workflow.md)

---

## Hook System

Hooks run automatically at key moments — no manual invocation needed on Full-Tier clients.

| Hook | When | What it does |
|------|------|-------------|
| `SessionStart` | Session begins | Runs sync-task, loads current-task.md |
| `PreToolUse` | Before any shell command | Blocks heavy commands (python, cargo, npm…) unless prefixed with `rtk` |
| `PostToolUse` | After file write/edit | Scans written files for secrets |
| `Stop` | Before each response | Updates memory files |
| `SessionEnd` | Session closes | Full memory consolidation, writes session-handover.md |
| `PreCompact` | Before context compaction | Injects architecture context so it survives compaction |

Git hooks (installed by bootstrap):
- **pre-commit** — verifies tier badges, warns on missing TDD coverage, scans for secrets
- **commit-msg** — enforces TDD markers in commit messages

---

## Token Efficiency

AI Toolbox is built to minimize token cost at every layer:

- **Cache-stable prefix** — each router file has a fixed `<!-- cache-prefix -->` header; the BOOT/SAFETY/HANDOVER block never changes, maximizing prompt-cache hits
- **rtk integration** — heavy command output compressed 60–90% before entering the context window
- **Instruction deduplication** — each rule lives in one file; router files reference, not repeat
- **Input context discipline** — agents are guided to read `git diff` and symbol context instead of full files (see `.agent/rules/diff-editing.md`)
- **Lazy memory loading** — only `memory-index.md` loads on boot; detail files load on demand

---

## Client Support

| Client | Tier | Auto hooks | Multi-agent | Router file |
|--------|------|-----------|------------|------------|
| Claude Code | Full | ✅ | ✅ | `CLAUDE.md` |
| Qwen Code | Full | ✅ | ✅ | `QWEN.md` |
| Antigravity | Full | ✅ | ✅ | `SKILL.md` |
| Codex CLI | Standard | ✅ | — | `CODERULES.md` |
| OpenCode | Standard | ✅ | ✅ | `OPENCODERULES.md` |
| Cursor | Standard | manual | — | `.cursorrules` |
| RooCode / Cline | Standard | manual | — | `.clinerules` |
| Windsurf | Standard | manual | — | `.windsurfrules` |
| Gemini CLI | Basic | — | — | `GEMINI.md` |
| Aider | Basic | — | — | `CONVENTIONS.md` |
| Pi (Inflection) | Basic | — | — | `PI.md` |

**Full** = hooks auto-enforce every rule, multi-agent parallelization available.  
**Standard** = hooks work but require manual invocation.  
**Basic** = rules are soft reminders only, no hook support.

---

## Key Files

```
AGENT.md                        ← AI's master execution contract (read first)
.agent/
  memory/
    memory-index.md             ← Boot entry point (lists all memory files)
    current-task.md             ← Active task (auto-generated by sync-task)
    session-handover.md         ← Unfinished work from last session
    architecture-decisions.md   ← Long-term ADRs
    integration-contracts.md    ← API / schema contracts
    audit.log                   ← Append-only audit trail (gitignored)
  rules/                        ← 21 hard execution constraints
    safety-rules.md             ← Destructive action prevention
    tdd-rules.md                ← RED → GREEN → REFACTOR enforcement
    diff-editing.md             ← Output + input context budget rules
    coding-discipline.md        ← Simplicity First, Surgical Changes
    parallel-execution.md       ← When and how to parallelize
  scripts/
    bootstrap.sh / .ps1         ← Silent idempotent setup (CI-safe)
    setup.sh / .ps1             ← Interactive wizard (client detect, tool install)
    doctor.sh / .ps1            ← Health check — validates entire setup
    sync-task.sh / .ps1         ← Syncs Beads task state to current-task.md
    hook-pre-command.sh / .ps1  ← Blocks heavy commands without rtk
    hook-stop.sh / .ps1         ← Writes session handover on stop
  workflows/                    ← Unified 9-step, bug-fix, code-review, branch-finish
  skills/                       ← TDD, debugging, code-review, parallel, safety
```

---

## Optional Tools

| Tool | Purpose | Without it |
|------|---------|-----------|
| **[rtk](https://github.com/rtk-ai/rtk)** | Compresses test/build output 60–90% | More tokens on heavy commands |
| **[Beads](https://github.com/steveyegge/beads)** | CLI task graph — moves plan out of chat | Manual edits to `current-task.md` |
| **[MCP servers](docs/mcp-guide.md)** | Context7 docs, filesystem, fetch | No live docs / web lookup |

```bash
cargo install rtk                                          # rtk
go install github.com/steveyegge/beads/cmd/bd@v0.63.3    # Beads
```

Both are installed automatically by `setup.sh` / `setup.ps1` if you confirm the prompts.

---

## Start Working

**Continuing existing work:**
> *"Execute your Boot Sequence, read our memories and sync tasks, then pick up the next step."*

**New feature or project:**
> *"I want to build [X]. Follow AGENT.md — do not write code yet. Brainstorm constraints and propose 2–3 approaches."*

**Paste into any supported AI client.** The Boot Sequence, task sync, and safety hooks do the rest.

---

## Documentation

| Guide | What's in it |
|-------|-------------|
| [AGENT.md](AGENT.md) | Master execution contract — all rules, boot sequence, 9-step workflow |
| [INSTALL.md](INSTALL.md) | Full installation guide — Template, clone, and per-client manual setup |
| [QUICKSTART.md](QUICKSTART.md) | 5-minute quick start — bootstrap, rtk, first session |
| [USE_AS_TEMPLATE.md](USE_AS_TEMPLATE.md) | GitHub Template step-by-step: create repo, clone, setup, first session |
| [docs/setup-claude.md](docs/setup-claude.md) | Claude Code: hooks, MCP, sub-agents, v1.2.0 features |
| [docs/setup-opencode.md](docs/setup-opencode.md) | OpenCode: commands, agents, skills |
| [docs/setup-codex.md](docs/setup-codex.md) | Codex CLI: config, permissions |
| [docs/setup-pi.md](docs/setup-pi.md) | Pi (Inflection AI): manual context workflow, limitations |
| [docs/mcp-guide.md](docs/mcp-guide.md) | MCP server setup for all clients |
| [docs/faq.md](docs/faq.md) | Frequently asked questions |
| [CHANGELOG.md](CHANGELOG.md) | Release history |
