# OpenCode Setup

## Prerequisites
- [OpenCode CLI](https://github.com/anomalyco/opencode) installed (`curl -fsSL https://opencode.ai/install | bash` or `npm i -g opencode-ai`)
- Git installed
- Node.js (for MCP servers via npx)
- API key for your LLM provider (OpenAI, Anthropic, etc.)

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
This creates:
- Router files (`OPENCODERULES.md`, `CLAUDE.md`, `QWEN.md`, etc.)
- Memory files with seed content
- Rule files (safety, testing, TDD, MCP, etc.)
- Git pre-commit hook

### 3. Configure OpenCode
Copy the AI Toolbox configuration:
```bash
cp .agent/templates/clients/opencode-config.json opencode.json
```

Edit `opencode.json` to add your provider and model:
```jsonc
{
  "provider": "openai",  // or "anthropic", "google", etc.
  "model": "gpt-4o",     // or "claude-sonnet-4", "gemini-2.0-flash", etc.
  // ... rest of AI Toolbox config
}
```

### 4. Optional: Install AI Toolbox Skills
AI Toolbox skills are compatible with OpenCode's skills system. Copy them:
```bash
# For project-level skills
cp -r .qwen/skills/* .opencode/skills/
```

### 5. Start OpenCode
```bash
opencode
```

OpenCode will automatically read `AGENTS.md` and the AI Toolbox memory files.

## What Gets Configured

| Component | File | Purpose |
|-----------|------|---------|
| Config | `opencode.json` | MCP servers, commands, agents, permissions |
| Router | `OPENCODERULES.md` | OpenCode-specific AI Toolbox instructions |
| Memory | `.agent/memory/` | Project memory, decisions, task state |
| Rules | `.agent/rules/` | Safety, TDD, testing, parallel execution |
| Workflows | `.agent/workflows/` | Bug fix, code review, branch finish, etc. |

## Available Commands

After configuration, these commands are available in OpenCode:

| Command | Purpose |
|---|---|
| `/boot` | Boot AI Toolbox and recover session context |
| `/sync` | Sync task state from Beads/task tracker |
| `/handover` | Create session handover for next session |
| `/templates` | Browse 413+ specialist agent templates |

## Using AI Toolbox Sub-Agents

AI Toolbox defines 3 sub-agents in `opencode.json`:
- `ai-toolbox-reviewer` — Code review before merges
- `ai-toolbox-tester` — TDD & testing
- `ai-toolbox-security` — Security audit

Use them with `@ai-toolbox-reviewer`, `@ai-toolbox-tester`, or `@ai-toolbox-security` in your conversation.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Commands not showing up | Rename `opencode.json` to `opencode.jsonc` (JSONC with comments) |
| MCP servers failing | Ensure Node.js and npx are installed |
| OpenCode doesn't read AGENTS.md | Run `/init` in OpenCode to initialize project |
| Skills not loading | Copy skills to `.opencode/skills/` directory |
| Hooks not running | OpenCode hooks are limited — use commands and skills instead |
