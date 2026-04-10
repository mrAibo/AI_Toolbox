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
# Follow the instructions in INSTALL.md
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

#### Prerequisites for Windows
Rust requires a C++ linker. Choose **one** option:
- **VS Build Tools** (recommended, ~2-3 GB): https://visualstudio.microsoft.com/downloads/ → "Desktop development with C++"
- **MinGW-w64** (lighter, ~200-400 MB): https://www.mingw-w64.org/downloads/
- **GNU ABI** (minimal): During `rustup-init`, select option `3)` — works for most cases

> **Tip:** After installing a linker, **open a new terminal** for PATH changes to take effect.

```powershell
# rtk — token optimization (recommended)
# Install Rust from https://rustup.rs/, then:
# ⚠️ IMPORTANT: Do NOT run "cargo install rtk" — that is a different project!
cargo install --git https://github.com/rtk-ai/rtk
rtk init -g  # Installs hooks (Windows: fallback to --claude-md)

# Beads — task tracking (recommended)
# Install Go from https://go.dev/dl/, then:
go install github.com/steveyegge/beads/cmd/bd@v0.63.3

# Alternative: Manual download if go install is not available
# Download from https://github.com/steveyegge/beads/releases, extract, and add bd.exe to PATH
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
See [MCP Guide](mcp-guide.md) for all AI clients.

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
| `rustup-init` asks for C++ linker | Choose option `1)` (VS Build Tools) or `3)` (GNU ABI) |
| `cargo install rtk` installs wrong tool | Use `cargo install --git https://github.com/rtk-ai/rtk` |
| `rtk: command not found` | Install Rust first, then `cargo install --git https://github.com/rtk-ai/rtk` |
| `npm install -g @beads/bd` fails | Beads no longer uses npm. Use `go install github.com/steveyegge/beads/cmd/bd@v0.63.3` instead |
| `bd: command not found` | Install Go, then `go install github.com/steveyegge/beads/cmd/bd@v0.63.3`, or download from https://github.com/steveyegge/beads/releases |
| AI doesn't read AGENT.md | Ensure your client's router file references AGENT.md |
| Git hooks not running | On Windows, use `bootstrap.ps1` for `.bat` wrapper creation |
| `rtk init -g` Warning "No hook installed" | Normal on Windows — rtk uses `--claude-md` mode as fallback |
