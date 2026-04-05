# Tool Integrations

This file documents how external tools integrate into the AI Toolbox workflow.

Each tool solves a specific problem. Together they form a complete development environment.

---

## The Tool Stack

| Tool | Solves | Tier |
|------|--------|------|
| **[rtk](https://github.com/rtk-ai/rtk)** | Token bloat from long logs and build output | Required |
| **[Beads](https://github.com/steveyegge/beads)** | Task tracking outside the AI's chat context | Recommended |
| **[Superpowers](https://github.com/obra/superpowers)** | Engineering process discipline (TDD, Planning, Debugging) | Optional |
| **[Template Bridge](https://github.com/maslennikov-ig/template-bridge)** | Access to 413+ specialist agent templates | Optional |
| **[MCP Servers](https://modelcontextprotocol.io/)** | External resources (docs, web, GitHub, memory) | Optional |

---

## 1. rtk (Rust Token Killer) — Token Optimization

### What it does

Intercepts shell commands, compresses output by 60-90%, and feeds only the essential info to the AI.

| Without rtk | With rtk |
|-------------|----------|
| `cargo test` → 25,000 tokens | `rtk test` → 2,500 tokens |
| `git push` → 200 tokens | `rtk git push` → 10 tokens |
| Raw error logs → flooding context | Filtered errors + TEE for full output |

### Install (1 command)

```bash
cargo install rtk
```

### Setup (1 command)

```bash
rtk init -g
```

This installs pre-execution hooks for Claude Code, Qwen Code, Cursor, Windsurf, Cline, Gemini, and other clients. After this, the AI automatically routes commands through rtk without needing to type `rtk` manually.

### Key Commands

| Command | Purpose |
|---------|---------|
| `rtk <command>` | Run any command through rtk (auto-compresses output) |
| `rtk test` | Run tests — shows only failures |
| `rtk build` | Build — shows only errors |
| `rtk lint` | Lint — grouped by rule, deduplicated |
| `rtk smart <file>` | 2-line summary of any file |
| `rtk read <file>` | Read with comments/boilerplate removed |
| `rtk find <pattern>` | Find files matching pattern |
| `rtk grep <pattern>` | Search file contents |
| `rtk diff` | Show what changed since last commit |
| `rtk gain` | Show your token savings (stats + graphs) |

### When It Runs Automatically

- **Pre-command hook** rewrites heavy commands to use `rtk`
- **Testing rules** require `rtk` for test execution
- **Safety rules** require `rtk` for large log output

---

## 2. Beads (bd) — Task Tracking

### What it does

Moves the execution plan out of the AI's chat context and into a Git-backed graph database. Tasks persist across sessions, branches, and AI restarts.

### Install (1 command)

```bash
# Requires Go
go install github.com/steveyegge/beads@latest
```

### Setup (1 command)

```bash
bd init
```

### Key Commands

| Command | Purpose |
|---------|---------|
| `bd create "task" -p high` | Create a task |
| `bd ready` | List tasks with no blockers |
| `bd update <ID> --claim` | Claim a task atomically |
| `bd show <ID>` | Show task details + audit trail |
| `bd dep add <child> <parent>` | Add dependency |
| `bd close <ID> "message"` | Close a task |
| `bd prime` | Load current task context (for session start) |

### When It Runs Automatically

- **Boot Sequence** — AI checks Beads for current task state
- **sync-task script** — syncs Beads to `.agent/memory/current-task.md`
- **Session handover** — AI records completed tasks via `bd close`

### Workflow Integration

```
1. User describes feature → AI creates tasks: bd create "..."
2. AI claims task → bd update <ID> --claim
3. AI works on task → follows Superpowers workflow
4. AI verifies → rtk test (shows only failures)
5. AI closes task → bd close <ID> "completed"
6. Next session → bd ready shows next task
```

---

## 3. Superpowers — Engineering Process Discipline

### What it does

Provides structured workflows for TDD, Planning, Debugging, Code Review, and Branch Management. Ensures the AI follows engineering best practices instead of improvising.

### Key Skills

| Skill | When to Use |
|-------|-------------|
| **brainstorming** | New feature, unclear requirements |
| **test-driven-development** | Writing new code with tests |
| **systematic-debugging** | Complex bugs with root cause tracing |
| **writing-plans** | Breaking work into 2-5 min tasks |
| **executing-plans** | Following a plan with human checkpoints |
| **subagent-driven-development** | Parallel task execution with review |
| **dispatching-parallel-agents** | Multiple independent tasks at once |
| **verification-before-completion** | Before marking any task done |
| **requesting-code-review** | Before merging/PR |
| **using-git-worktrees** | Isolated feature branches |
| **finishing-a-development-branch** | Merge/PR decision + cleanup |

### How It Integrates

Superpowers skills are **triggered by context**, not by commands. The AI Toolbox rules files encode the same discipline:

| Superpowers Skill | AI Toolbox Equivalent |
|-------------------|----------------------|
| `test-driven-development` | `.agent/rules/testing-rules.md` (RED-GREEN-REFACTOR) |
| `systematic-debugging` | `.agent/workflows/bug-fix.md` (Repro → Fix → Verify) |
| `verification-before-completion` | `testing-rules.md` "Do not claim completion without verification" |
| `subagent-driven-development` | `.agent/rules/qwen-code.md` (Multi-Agent Coordination) |
| `writing-plans` | `AGENT.md` §3 (Brainstorm → Architecture → Tasks → Implementation) |
| `brainstorming` | `AGENT.md` §7 (Brainstorming rules) |

### When It Runs Automatically

- When the AI reads `AGENT.md`, it follows the encoded discipline
- No separate installation needed — rules are part of `.agent/rules/`

---

## 4. Template Bridge — 413+ Specialist Agent Templates

### What it does

Provides on-demand access to 413+ specialist agent templates across 26 categories: Security, DevOps, AI/ML, Web3, Rust, Go, UI/UX, Performance, Database, and more.

### Key Commands

| Command | Purpose |
|---------|---------|
| `/browse-templates` | Interactive template search |
| `template-catalog` skill | Lists available templates by category |

### When to Use

- You need a specialist (e.g., "write a Rust async server", "design a Kubernetes deployment")
- You want established patterns instead of improvising
- You need security, performance, or architecture review

### How It Integrates

Template Bridge is a Claude Code plugin. For other clients, the template catalog can be accessed manually via the [GitHub repo](https://github.com/maslennikov-ig/template-bridge).

---

## 5. MCP Servers — External Resources

### What they do

Connect the AI to external resources: documentation, web content, GitHub, file systems, and cross-session memory.

### Setup

See **[docs/mcp-guide.md](../../docs/mcp-guide.md)** for full setup.

| Profile | Servers | When to Use |
|---------|---------|-------------|
| **minimal** | context7, sequential-thinking | Quick tasks |
| **developer** | + filesystem, fetch | Daily work (recommended) |
| **full** | + github, memory | Full project work |

### When It Runs Automatically

- MCP servers connect when the AI client starts
- `context7` provides docs on demand (no manual lookup needed)
- `sequential-thinking` structures complex reasoning automatically

---

## How Everything Works Together

### The Complete Flow

```
User: "Build a feature X"
│
├─ Beads:     bd create "feature X" → task in graph
├─ Superpowers: brainstorming → clarify requirements
├─ Beads:     bd create subtasks → decomposed work
│
├─ For each subtask:
│   ├─ Superpowers: writing-plans → break into steps
│   ├─ Beads:     bd update --claim → AI takes task
│   │
│   ├─ If TDD:
│   │   ├─ Superpowers: test-driven-development
│   │   ├─ rtk: rtk test → shows only test failures
│   │   └─ Beads: bd close → task done
│   │
│   ├─ If debugging:
│   │   ├─ Superpowers: systematic-debugging
│   │   ├─ rtk: rtk read/log → compressed output
│   │   └─ Beads: bd close → fix verified
│   │
│   └─ If parallel:
│       ├─ Superpowers: dispatching-parallel-agents
│       ├─ MCP: context7 → docs for each agent
│       └─ Beads: bd close → all tasks done
│
├─ Superpowers: verification-before-completion → final check
├─ rtk: rtk test → all tests pass (compressed output)
├─ Superpowers: finishing-a-development-branch → merge/PR
└─ Beads: bd close "feature X complete" → done
```

### The Minimal Setup (No Brainer)

For most users, this is enough:

```bash
# 1. Install core tools
cargo install rtk
go install github.com/steveyegge/beads@latest

# 2. Setup
rtk init -g    # auto-hooks for all clients
bd init         # task tracking

# 3. Open AI agent, read AGENT.md — done
```

Everything else (MCP, Superpowers, Template Bridge) is optional and can be added later.
