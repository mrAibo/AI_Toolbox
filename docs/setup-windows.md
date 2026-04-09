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
Rust benötigt einen C++ Linker. Wähle **eine** Option:
- **VS Build Tools** (empfohlen, ~2-3 GB): https://visualstudio.microsoft.com/downloads/ → "Desktop development with C++"
- **MinGW-w64** (leichter, ~200-400 MB): https://www.mingw-w64.org/downloads/
- **GNU ABI** (minimal): Bei `rustup-init` Option `3)` wählen — funktioniert in den meisten Fällen

> **Tipp:** Nach der Installation eines Linkers **neues Terminal öffnen**, damit PATH-Änderungen wirksam werden.

```powershell
# rtk — Token-Optimierung (empfohlen)
# Installiere Rust von https://rustup.rs/, dann:
# ⚠️ WICHTIG: Nicht "cargo install rtk" — das ist ein anderes Projekt!
cargo install --git https://github.com/rtk-ai/rtk
rtk init -g  # Installiert Hooks (Windows: Fallback zu --claude-md)

# Beads — Task-Tracking (empfohlen)
# Option A: npm (empfohlen für Windows)
npm install -g @beads/bd

# Option B: Manuell falls npm fehlschlägt
curl -L -o $env:TEMP\beads.zip https://github.com/gastownhall/beads/releases/download/v0.63.3/beads_0.63.3_windows_amd64.zip

# Verify checksum (update hash when version changes)
$ExpectedHash = "<SHA256>"  # Update from GitHub Releases page — verify with: certutil -hashfile $env:TEMP\beads.zip SHA256
$ActualHash = (Get-FileHash $env:TEMP\beads.zip -Algorithm SHA256).Hash
if ($ActualHash -ne $ExpectedHash) { throw "Checksum mismatch — download may be corrupted" }

Expand-Archive -Path $env:TEMP\beads.zip -DestinationPath $env:TEMP\beads_extracted -Force
Copy-Item -Path "$env:TEMP\beads_extracted\bd.exe" -Destination "$env:APPDATA\npm\bd.exe" -Force
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
| `rustup-init` fragt nach C++ Linker | Option `1)` (VS Build Tools) oder `3)` (GNU ABI) wählen |
| `cargo install rtk` installiert falsches Tool | Verwende `cargo install --git https://github.com/rtk-ai/rtk` |
| `rtk: command not found` | Rust installieren, dann `cargo install --git https://github.com/rtk-ai/rtk` |
| `npm install -g @beads/bd` schlägt fehl | Manuelle Installation: ZIP herunterladen, extrahieren, `bd.exe` in PATH kopieren (siehe Schritt 3) |
| `bd: command not found` | npm oder manuelle Installation (siehe Schritt 3). **Nicht** `go install` auf Windows verwenden |
| AI doesn't read AGENT.md | Ensure your client's router file references AGENT.md |
| Git hooks not running | On Windows, use `bootstrap.ps1` for `.bat` wrapper creation |
| `rtk init -g` Warning "No hook installed" | Normal auf Windows — rtk verwendet `--claude-md` Modus als Fallback |
