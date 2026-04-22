# Claude Code Environment Specifics

Claude Code is a **Full-Tier** client with access to hooks, multi-agent orchestration, plan mode, and the complete AI Toolbox automation layer.

## Hook Configuration

Hooks are registered via `.claude.json` in the project root (created by `setup.sh` / `setup.ps1`):

| Event | Script | Purpose |
|-------|--------|---------|
| `PreToolUse` | `hook-pre-command.sh` / `.ps1` | Block heavy commands, enforce `rtk` prefix |
| `PostToolUse` | `hook-stop.sh` / `.ps1` | Memory consolidation after tool use |
| `Stop` | `hook-stop.sh` / `.ps1` | Write session handover on agent stop |

> Note: `.claude.json` hook support is experimental in Claude Code. If hooks do not fire, verify the Claude Code version supports `hooks` in `.claude.json`.

## Sub-Agent Orchestration

Use the `Agent` tool to spawn sub-agents for parallel task execution:

- `subagent_type: "Explore"` — fast codebase search (Glob, Grep, Read, WebFetch)
- `subagent_type: "general-purpose"` — complex multi-step research or implementation
- `subagent_type: "Plan"` — architecture design and implementation planning

Coordinate sub-agents via `.agent/memory/` files for shared state. Write results to `session-handover.md` before spawning the next agent.

## MCP Integration

Two MCP servers are configured during `setup.sh` / `setup.ps1` for Claude:

| Server | Purpose |
|--------|---------|
| `context7` | Up-to-date library docs (replaces outdated training data) |
| `sequential-thinking` | Structured multi-step reasoning for complex problems |

Always query Context7 before implementing with external libraries:
```
use context7: <library-name>
```

## Plan Mode

Enter plan mode before major architectural changes or when the task spans multiple files. Document the approved plan in `.agent/memory/current-task.md` before implementation begins.

## Session Boot

On every session start, run the boot sequence from `CLAUDE.md`:
```powershell
# Windows
powershell -ExecutionPolicy Bypass -File .agent/scripts/sync-task.ps1
```
```bash
# Unix/macOS
bash .agent/scripts/sync-task.sh && cat .agent/memory/current-task.md
```

## Multi-Agent Coordination

When running parallel agents:
1. Give each agent a self-contained prompt (no shared conversation context)
2. Use `.agent/memory/session-handover.md` to pass results between agents
3. Serialize writes to shared memory files via the atomic write library (`lib-atomic-write.sh`)
4. Refer to [multi-agent.md](../workflows/multi-agent.md) for the full orchestration workflow
