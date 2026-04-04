# Qwen Code Environment Specifics

Qwen Code is a **Full-Tier** client with access to hooks, multi-agent orchestration, plan mode, and sync automation.

## SubAgent Configuration
- Use the `agent` tool to spawn sub-agents for parallel task execution.
- Specify `subagent_type` as `general-purpose` for complex research/tasks or `Explore` for fast codebase exploration.
- Coordinate sub-agents via `.agent/memory/` files to maintain shared state.

## Hook Setup
- **Pre-command hook:** `.agent/scripts/hook-pre-command.sh` (or `.ps1`) — enforces `rtk` prefix for heavy commands.
- **Stop hook:** `.agent/scripts/hook-stop.sh` (or `.ps1`) — triggers memory consolidation on session end.
- Configure hooks in your Qwen Code settings analogously to Claude Code's `.claude.json` hook configuration.

## Plan Mode
- Use plan mode before major architectural changes.
- Document plans in `.agent/memory/current-task.md` after approval.

## Multi-Agent Coordination
- When spawning multiple agents, provide clear, independent prompts.
- Use `.agent/memory/session-handover.md` to track sub-agent outcomes.
- Refer to `QWEN.md` for Full-Tier feature details.
