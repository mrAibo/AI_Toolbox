# AI Toolbox Protocol (OpenAI Codex CLI) -- Tier: Full
<!-- cache-prefix: tier badge + 3 critical rules must remain first and unmodified -->

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

AI Toolbox provides 9 skills in `.agent/skills/` (compatible with Codex `.codex/skills/` format). Each skill has YAML frontmatter with `name` and `description` fields for auto-triggering.

## Memory Layer

> Boot order: see [memory-index.md](.agent/memory/memory-index.md) — it lists all memory files in priority order.

## MCP Servers

Configured via `.codex/config.toml`. Recommended servers:
- `context7` — Documentation lookup
- `sequential-thinking` — Complex reasoning
- `filesystem` — File access (scoped to safe directories)
- `fetch` — Web content retrieval

Refer to [AGENT.md](AGENT.md) for the full operational contract.
