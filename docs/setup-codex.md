# Codex CLI Setup

## Prerequisites
- [Codex CLI](https://github.com/openai/codex) installed (`npm i -g @openai/codex` or `brew install --cask codex`)
- Git installed
- Node.js (for MCP servers via npx)

## Quick Start

### 1. Clone or copy the framework
```bash
git clone https://github.com/mrAibo/AI_Toolbox.git my-project
cd my-project
```

### 2. Run the bootstrap script
```bash
bash .agent/scripts/bootstrap.sh
```

### 3. Configure Codex CLI
Copy the hooks configuration:
```bash
cp .agent/templates/clients/.codex-hooks.json .codex/hooks.json
```

Enable hooks in your config (`~/.codex/config.toml` or `.codex/config.toml`):
```toml
[features]
codex_hooks = true
```

### 4. Optional: Copy the full config template
```bash
cp .agent/templates/clients/.codex-config.toml .codex/config.toml
```

This sets up:
- MCP servers (context7, sequential-thinking, filesystem, fetch)
- Approval policy and sandbox mode
- Model configuration

### 5. Start Codex
```bash
codex
```

Codex will automatically read `AGENTS.md` and the AI Toolbox memory files.

## What Gets Configured

| Component | File | Purpose |
|-----------|------|---------|
| Hooks | `.codex/hooks.json` | Pre/Post command validation, session sync, memory consolidation |
| Config | `.codex/config.toml` | MCP servers, model, sandbox settings |
| Router | `CODERULES.md` | Codex-specific AI Toolbox instructions |
| Memory | `.agent/memory/` | Project memory, decisions, task state |

## Hooks Explained

| Hook Event | Trigger | Script | Purpose |
|---|---|---|---|
| `SessionStart` | Session start/resume | `sync-task.sh` | Sync task state from Beads/task tracker |
| `PreToolUse` | Before Bash execution | `hook-pre-command-qwen.sh` | Validate heavy commands, recommend rtk |
| `PostToolUse` | After Bash execution | `hook-post-tool-qwen.sh` | Scan written files for secrets |
| `Stop` | Conversation end | `hook-stop-qwen.sh` | Consolidate session memory |

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Hooks not running | Set `codex_hooks = true` in config.toml |
| `hooks.json` not found | Ensure file is at `.codex/hooks.json` (not `~/.codex/hooks.json` for project-specific) |
| MCP servers failing | Ensure Node.js and npx are installed |
| Codex doesn't read AGENTS.md | Ensure project is trusted: `codex trust` |
