# Claude Code Setup

## Prerequisites
- [Claude Code CLI](https://claude.ai/code) installed (`npm install -g @anthropic-ai/claude-code`)
- Git installed
- Node.js (for MCP servers via npx)
- Anthropic API key or Claude Pro/Max subscription

## Quick Start

### 1. Clone or copy the framework
```bash
git clone https://github.com/mrAibo/AI_Toolbox.git my-project
cd my-project
```

### 2. Run the one-command setup
```powershell
# Windows
powershell -ExecutionPolicy Bypass -File .agent/scripts/setup.ps1
```
```bash
# Unix/macOS
bash .agent/scripts/setup.sh
```

The setup script will:
- Auto-detect Claude Code
- Install `.claude.json` hooks (pre-command, stop)
- Optionally install git commit hooks (TDD + secret scan)
- Optionally configure MCP servers (context7, sequential-thinking)
- Bootstrap all memory and rule files

### 3. Start Claude Code
```bash
claude
```

Claude Code will read `CLAUDE.md` automatically on session start.

## What Gets Configured

| Component | File | Purpose |
|-----------|------|---------|
| Router | `CLAUDE.md` | Full-Tier AI Toolbox protocol and 9-step workflow |
| Hooks | `.claude.json` | Pre-command safety, stop memory consolidation |
| Memory | `.agent/memory/` | Project memory, decisions, task state |
| Rules | `.agent/rules/` | Safety, TDD, parallel execution, client specifics |
| Workflows | `.agent/workflows/` | Bug fix, code review, branch finish, multi-agent |
| MCP | `~/.claude/` | context7 and sequential-thinking servers |

## MCP Servers

Two MCP servers are installed during setup:

| Server | Command | Purpose |
|--------|---------|---------|
| `context7` | `npx -y @upstash/context7-mcp@1.2.0` | Up-to-date library documentation |
| `sequential-thinking` | `npx -y @modelcontextprotocol/server-sequential-thinking@0.1.0` | Structured multi-step reasoning |

To add manually:
```bash
claude mcp add context7 npx -y @upstash/context7-mcp@1.2.0
claude mcp add sequential-thinking npx -y @modelcontextprotocol/server-sequential-thinking@0.1.0
```

## Available Slash Commands

After setup, these commands are available in Claude Code sessions:

| Command | Purpose |
|---------|---------|
| `/boot` | Boot AI Toolbox and recover session context |
| `/sync` | Sync task state from Beads/task tracker |
| `/handover` | Create session handover for next session |
| `/templates` | Browse 413+ specialist agent templates |
| `/generate` | Generate client files from `.ai-toolbox/config.json` |

## Sub-Agent Orchestration

Claude Code supports spawning sub-agents via the `Agent` tool. AI Toolbox defines three agent roles:

- `Explore` — fast codebase search (Glob, Grep, Read, WebFetch)
- `general-purpose` — complex multi-step research or implementation
- `Plan` — architecture design before implementation

See [multi-agent.md](../agent/workflows/multi-agent.md) for the full orchestration workflow.

## Hooks Reference

AI Toolbox registers hooks via `.claude.json`:

| Hook | Trigger | Action |
|------|---------|--------|
| Pre-command | Before any tool call | Block heavy commands without `rtk` prefix |
| Stop | Session end / agent stop | Write session handover, consolidate memory |

> Note: `.claude.json` hook support is experimental. Check [.agent/rules/claude-code.md](../agent/rules/claude-code.md) for known limitations.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Hooks not firing | Verify Claude Code version supports `.claude.json` hooks; check for `EXPERIMENTAL` note in `.claude.json` |
| MCP servers missing | Re-run `claude mcp add ...` commands above |
| `CLAUDE.md` not loaded | Ensure you are in the project root when starting `claude` |
| Boot sequence not running | Manually run `bash .agent/scripts/sync-task.sh` before your first task |
| Secret scan blocking commit | Set `SKIP_SECRET_SCAN=1` for legitimate secrets; document in `.agent/memory/architecture-decisions.md` |
