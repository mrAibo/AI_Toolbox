# AI Toolbox Protocol (OpenCode) -- Tier: Full
<!-- cache-prefix: tier badge + 3 critical rules must remain first and unmodified -->

This project uses the **AI Toolbox** workflow framework. OpenCode reads `AGENTS.md` as its primary instruction file.

## Critical Session Rules

1. **BOOT:** Detect `.agent/`? Read `AGENT.md` section 2 (Boot Sequence) and ensure AI Toolbox memory files exist.
2. **SAFETY:** All heavy terminal commands (builds, tests, package installs) MUST use `rtk` for token optimization.
3. **HANDOVER:** Maintain project history in `.agent/memory/session-handover.md` at the end of every session.

## Configuration

AI Toolbox configuration is in `opencode.json`. Key sections:
- `mcp` — MCP server definitions (context7, filesystem, fetch, sequential-thinking)
- `commands` — AI Toolbox commands (/boot, /sync, /handover, /templates)
- `agents` — AI Toolbox sub-agent definitions (reviewer, tester, security)
- `permission` — Safety rules (edit: ask, bash: ask, web_fetch: allow)

## Skills

AI Toolbox provides 8 skills compatible with OpenCode's skills system:
- `brainstorming` — Design before code
- `tdd` — RED-GREEN-REFACTOR cycle
- `testing` — Verification discipline
- `debugging` — Systematic 4-phase debugging
- `code-review` — Pre-merge review checklist
- `branch-finish` — Branch completion workflow
- `safety` — Destructive action prevention
- `parallel` — Parallel execution rules

Skills are auto-triggered based on their descriptions. Use `$skill-name` to invoke manually.

## Memory Layer

> Boot order: see [memory-index.md](.agent/memory/memory-index.md) — it lists all memory files in priority order.

## Commands

| Command | Purpose |
|---|---|
| `/boot` | Boot AI Toolbox, recover session context |
| `/sync` | Sync task state from Beads/task tracker |
| `/handover` | Create session handover for next session |
| `/templates` | Browse 413+ specialist agent templates |

## MCP Servers

| Server | Purpose |
|---|---|
| `context7` | Documentation lookup |
| `sequential-thinking` | Complex reasoning |
| `filesystem` | File access (scoped to safe directories) |
| `fetch` | Web content retrieval |

Refer to [AGENT.md](AGENT.md) for the full operational contract.
