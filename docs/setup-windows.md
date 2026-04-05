# Windows Setup

## Prerequisites
- Git for Windows (includes Git Bash)
- PowerShell 5.1+ (included with Windows 10/11)
- A terminal-based AI tool (Claude Code, Qwen Code, Gemini CLI, etc.)

## Quick Start (2 minutes)

### 1. Clone or copy the framework
```powershell
# Option A: Use as a starting point for a new project
git clone https://github.com/mrAibo/AI_Toolbox.git my-project
cd my-project

# Option B: Download into an existing project
# Follow the instructions in install.md
```

### 2. Run the bootstrap script
```powershell
powershell -ExecutionPolicy Bypass -File .agent\scripts\bootstrap.ps1
```
This creates:
- Router files (`CLAUDE.md`, `QWEN.md`, `GEMINI.md`, etc.) for your AI client
- Memory files with seed content (`.agent\memory\`)
- Rule files (`.agent\rules\`)
- Git pre-commit hook (both `.git/hooks/pre-commit` and `.git/hooks/pre-commit.bat`)

> **Note:** If you get an execution policy error, run:
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

### 3. Install optional tools
```powershell
# rtk — token optimization (recommended)
# Install Rust from https://rustup.rs/, then:
cargo install rtk
rtk init -g  # Installs hooks for your AI client

# Beads — task tracking (recommended)
# Install Go from https://go.dev/dl/, then:
go install github.com/steveyegge/beads@latest
bd init
```

### 4. Start your AI agent
Open your AI client in the project directory. It will automatically read `AGENT.md` and follow the boot sequence.

## What Gets Created

```
my-project\
├── AGENT.md                    # Master protocol (already exists)
├── CLAUDE.md / QWEN.md / ...   # Router files (generated)
├── .gitignore                  # Updated with AI Toolbox entries
└── .agent\
    ├── memory\                 # Project brain (seed content)
    ├── rules\                  # Execution constraints (seed content)
    └── scripts\                # Bootstrap, hooks, sync (already exists)
```

## Optional: MCP Setup
```powershell
# Minimal — documentation + reasoning
claude mcp add context7 npx -y @upstash/context7-mcp
claude mcp add sequential-thinking npx -y @modelcontextprotocol/server-sequential-thinking
```
See [docs/mcp-guide.md](mcp-guide.md) for all AI clients.

## Verification

```powershell
# All router files exist
Test-Path CLAUDE.md, QWEN.md, GEMINI.md, CONVENTIONS.md, .cursorrules, .clinerules, .windsurfrules

# Memory files have content
Get-Content .agent\memory\architecture-decisions.md
Get-Content .agent\memory\current-task.md

# Bootstrap is idempotent — running again doesn't overwrite
powershell -ExecutionPolicy Bypass -File .agent\scripts\bootstrap.ps1  # Should skip all existing files
```

## Git Bash vs PowerShell

Both bootstrap scripts produce equivalent output:

| Feature | `bootstrap.sh` (Git Bash) | `bootstrap.ps1` (PowerShell) |
|---------|--------------------------|------------------------------|
| Router files | ✅ Same content | ✅ Same content |
| Memory files | ✅ Same content | ✅ Same content |
| Rules files | ✅ Same content | ✅ Same content |
| Git hooks | `pre-commit` (bash) | `pre-commit` (bash) + `pre-commit.bat` (batch) |
| Script permissions | `chmod +x` on `.sh` files | N/A (PowerShell handles execution) |

**Recommendation:** Use `bootstrap.ps1` on Windows for full hook coverage (includes `.bat` wrapper for native Git).

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `ExecutionPolicy` error | `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| `rtk: command not found` | Install Rust from rustup.rs, then `cargo install rtk` |
| `bd: command not found` | Install Go from go.dev, then `go install github.com/steveyegge/beads@latest` |
| AI doesn't read AGENT.md | Ensure your client's router file references AGENT.md |
| Git hooks not running | On Windows, use `bootstrap.ps1` for `.bat` wrapper creation |
