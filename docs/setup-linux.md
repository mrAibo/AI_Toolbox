# Linux / macOS Setup

## Prerequisites
- Git
- Bash (Linux) or Zsh/Bash (macOS)
- A terminal-based AI tool (Claude Code, Qwen Code, Gemini CLI, etc.)

## Quick Start (2 minutes)

### 1. Clone or copy the framework
```bash
# Option A: Use as a starting point for a new project
git clone https://github.com/mrAibo/AI_Toolbox.git my-project
cd my-project

# Option B: Download into an existing project
curl -sSL https://raw.githubusercontent.com/mrAibo/AI_Toolbox/main/INSTALL.md | head -30
# Then follow the instructions in INSTALL.md
```

### 2. Run the bootstrap script
```bash
bash .agent/scripts/bootstrap.sh
```
This creates:
- Router files (`CLAUDE.md`, `QWEN.md`, `GEMINI.md`, etc.) for your AI client
- Memory files with seed content (`.agent/memory/`)
- Rule files (`.agent/rules/`)
- Git pre-commit hook

### 3. Install optional tools
```bash
# rtk — token optimization (recommended)
cargo install rtk
rtk init -g  # Instails hooks for your AI client

# Beads — task tracking (recommended)
go install github.com/steveyegge/beads@latest
bd init
```

### 4. Start your AI agent
Open your AI client in the project directory. It will automatically read `AGENT.md` and follow the boot sequence.

## What Gets Created

```
my-project/
├── AGENT.md                    # Master protocol (already exists)
├── CLAUDE.md / QWEN.md / ...   # Router files (generated)
├── .gitignore                  # Updated with AI Toolbox entries
└── .agent/
    ├── memory/                 # Project brain (seed content)
    ├── rules/                  # Execution constraints (seed content)
    └── scripts/                # Bootstrap, hooks, sync (already exists)
```

## Optional: MCP Setup
```bash
# Minimal — documentation + reasoning
claude mcp add context7 npx -y @upstash/context7-mcp
claude mcp add sequential-thinking npx -y @modelcontextprotocol/server-sequential-thinking
```
See [MCP Guide](mcp-guide.md) for all AI clients.

## Verification

```bash
# All router files exist
ls CLAUDE.md QWEN.md GEMINI.md CONVENTIONS.md .cursorrules .clinerules .windsurfrules

# Memory files have content
cat .agent/memory/architecture-decisions.md
cat .agent/memory/current-task.md

# Bootstrap is idempotent — running again doesn't overwrite
bash .agent/scripts/bootstrap.sh  # Should skip all existing files
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `bootstrap.sh: permission denied` | `chmod +x .agent/scripts/bootstrap.sh` |
| `rtk: command not found` | Install Rust, then `cargo install rtk` |
| `bd: command not found` | Install Go, then `go install github.com/steveyegge/beads@latest` |
| AI doesn't read AGENT.md | Ensure your client's router file (CLAUDE.md, QWEN.md, etc.) references AGENT.md |
