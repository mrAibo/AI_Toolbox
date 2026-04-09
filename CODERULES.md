# AI Toolbox Protocol (OpenAI Codex CLI) -- Tier: Full

This project uses the **AI Toolbox** workflow framework. Codex CLI reads this file via `AGENTS.md` references.

## Critical Session Rules

1. **BOOT:** Detect `.agent/`? Read `AGENT.md` section 2 (Boot Sequence) and ensure `.codex/hooks.json` is configured.
2. **SAFETY:** All heavy terminal commands (builds, tests, package installs) MUST be validated by the pre-command hook.
3. **HANDOVER:** Maintain project history in `.agent/memory/session-handover.md` at the end of every session.

## Hooks Configuration

AI Toolbox hooks are defined in `.agent/templates/clients/.codex-hooks.json`. Copy to `.codex/hooks.json` and enable in config:

```toml
[features]
codex_hooks = true
```

## Skills

AI Toolbox provides 8 skills in `.qwen/skills/` (compatible with Codex `.codex/skills/` format). Each skill has YAML frontmatter with `name` and `description` fields for auto-triggering.

## Memory Layer

Read these files at session start (in order):
1. `.agent/memory/memory-index.md` -- Overview of all memory files (READ FIRST)
2. `.agent/memory/architecture-decisions.md` -- ADR index
3. `.agent/memory/integration-contracts.md` -- API/schema contracts
4. `.agent/memory/session-handover.md` -- Unfinished work from last session
5. `.agent/memory/current-task.md` -- Active todo list
6. `.agent/memory/runbook.md` -- Operational procedures

## MCP Servers

Configured via `.codex/config.toml`. Recommended servers:
- `context7` — Documentation lookup
- `sequential-thinking` — Complex reasoning
- `filesystem` — File access (scoped to safe directories)
- `fetch` — Web content retrieval

Refer to [AGENT.md](AGENT.md) for the full operational contract.
