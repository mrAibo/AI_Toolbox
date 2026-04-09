# AI Toolbox Installation Instructions (For AI Agents)

You are an AI assistant (such as Claude Code, Qwen Code, Gemini CLI, RooCode/Cline, Cursor, Windsurf, Aider, or Antigravity) and the user has asked you to install the "AI Toolbox" workflow into the current repository/directory.

## Phase 0: Environment Discovery
Before you start, identify your own environment:
1.  **Operating System:** Are you running on Linux/macOS (Bash) or Windows (PowerShell)? Choose the corresponding commands in the steps below.
2.  **Platform Identity:** 
    - If you are **Claude Code**, you can use `mcp add` commands.
    - If you are **Antigravity**, you have access to **native slash-command workflows** and **artifacts**; prioritize these.
    - If you are **Gemini CLI**, **Aider**, **Cursor**, or **Windsurf**, follow the generic terminal instructions.
    - If you are **Qwen Code** or **RooCode/Cline**, you have file-based routing; follow the instructions in your respective router file.
3.  **Tooling:** Check if you have direct access to `git`, `npx`, `go`, and `cargo`.

## Step 1: Download the core files
Fetch the boilerplate framework files from the `mrAibo/AI_Toolbox` repository. 

**For Linux / macOS (Bash):**
```bash
git clone https://github.com/mrAibo/AI_Toolbox.git /tmp/ai_toolbox_tmp
cp -r /tmp/ai_toolbox_tmp/.agent .
cp /tmp/ai_toolbox_tmp/AGENT.md .
cp /tmp/ai_toolbox_tmp/SKILL.md .
rm -rf /tmp/ai_toolbox_tmp
```

**For Windows (PowerShell):**
```powershell
git clone https://github.com/mrAibo/AI_Toolbox.git $env:TEMP\ai_toolbox_tmp
Copy-Item -Path "$env:TEMP\ai_toolbox_tmp\.agent" -Destination ".\" -Recurse -Force
Copy-Item -Path "$env:TEMP\ai_toolbox_tmp\AGENT.md" -Destination ".\" -Force
Copy-Item -Path "$env:TEMP\ai_toolbox_tmp\SKILL.md" -Destination ".\" -Force
Remove-Item -Path "$env:TEMP\ai_toolbox_tmp" -Recurse -Force
```

## Step 2: Initialize AI Router Files & Workflows
Run the bootstrap script to create the core structure, Antigravity workflows (`.agent/workflows/`), and auto-discovery files (`CLAUDE.md`, `GEMINI.md`, etc.).

- **On Linux/macOS:** `bash .agent/scripts/bootstrap.sh`
- **On Windows:** `powershell .agent/scripts/bootstrap.ps1`

## Step 3: Check Core Stack Dependencies
The AI Toolbox relies on specific terminal tools. You must verify their presence and try to install them if missing.

### 3.1 Platform Prerequisites

**Windows users:** Before installing Rust tools, ensure you have a C++ linker:
- **Option A (Recommended):** Visual Studio Build Tools with "Desktop development with C++" workload (~2-3 GB)
  - Download: https://visualstudio.microsoft.com/downloads/
- **Option B (Lighter):** MinGW-w64 (~200-400 MB)
  - Download: https://www.mingw-w64.org/downloads/
- **Option C (Minimal):** During Rust installation, select option `3)` (GNU ABI) — works for most cases without extra tooling

**Linux/macOS:** No additional prerequisites needed beyond Rust and Go.

### 3.2 rtk (Rust Token Killer)
- Check if `rtk` is installed: `rtk --version`
- If missing, verify Rust is available: `cargo --version`
- **If Rust is installed, install rtk from GitHub (NOT crates.io):**
  ```bash
  # ⚠️ IMPORTANT: Use --git flag! The crates.io "rtk" is a different project (Rust Type Kit).
  cargo install --git https://github.com/rtk-ai/rtk
  ```
- **After installation, run:** `rtk init -g`
  - **Unix/macOS:** Installs pre-execution hooks for your AI client.
  - **Windows:** Falls back to `--claude-md` mode (hook-based mode requires Unix). This is fully functional.
- **If Rust is NOT installed:** Warn the user and point to https://rustup.rs/

### 3.3 Beads (Task Tracker)
- Check if `bd` is installed: `bd version`
- If missing, install based on your platform:

  **Linux/macOS (via Go):**
  ```bash
  go install github.com/steveyegge/beads@latest
  ```

  **Windows (via npm — recommended):**
  ```powershell
  npm install -g @beads/bd
  ```
  If the npm postinstall extraction fails (known issue on some Windows systems), install manually:
  ```powershell
  # 1. Download the ZIP
  curl -L -o $env:TEMP\beads.zip https://github.com/gastownhall/beads/releases/download/v0.63.3/beads_0.63.3_windows_amd64.zip

  # 2. Extract
  Expand-Archive -Path $env:TEMP\beads.zip -DestinationPath $env:TEMP\beads_extracted -Force

  # 3. Copy bd.exe to your PATH (adjust path as needed)
  Copy-Item -Path "$env:TEMP\beads_extracted\bd.exe" -Destination "C:\Users\YOUR_USERNAME\AppData\Roaming\npm\bd.exe" -Force
  ```

  **Alternative (all platforms):** Download the latest release directly from https://github.com/steveyegge/beads/releases

- If Go is NOT installed (Linux/macOS): Warn the user and point to https://go.dev/dl/

## Step 4: Configure MCP Servers & Plugins
If you are **Claude Code** (or can execute configuring scripts), attempt to install the following recommended MCP servers and plugins. If they require cloning a repository, clone them into a tools directory (e.g., `~/.mcp-servers/` or `%USERPROFILE%\.mcp-servers\`):

**1. Core Protocol Servers**
```bash
claude mcp add context7 npx -y @upstash/context7-mcp
claude mcp add sequential-thinking npx -y @modelcontextprotocol/server-sequential-thinking
```

**2. Memory MCP Server**
- Official MCP Server: `npx -y @modelcontextprotocol/server-memory`
- *Instruction for AI:* This provides cross-session memory for storing and retrieving context, bug fixes, and project experience.

**3. bat & rg (ripgrep)**
- Optional but recommended: modern replacements for `cat` and `grep`.
- Install via your package manager (e.g. `cargo install bat ripgrep`, `brew install bat ripgrep`, or your OS package manager).

**4. Template Bridge & Superpowers**
- **Superpowers:** No separate installation needed — the engineering discipline (TDD, Planning, Debugging) is encoded in `.agent/rules/` and applied automatically when the AI reads `AGENT.md`. TDD is enforced via [`.agent/rules/tdd-rules.md`](.agent/rules/tdd-rules.md).
- **Template Bridge:** Provides 413+ specialist templates for when existing skills aren't enough. Access via `/browse-templates` (Claude Code) or browse the [GitHub repo](https://github.com/maslennikov-ig/template-bridge). Rules: [`.agent/rules/template-usage.md`](.agent/rules/template-usage.md).

**5. ⚡ Auto-Configure Terminal Hooks (CRITICAL)**

Each AI client has its own way of handling hooks. If your client supports them, configure them now:

*   **Claude Code:** We've provided a `.agent/templates/clients/.claude.json` template. Copy it to your root or update your existing config:
    ```json
    {
      "NOTE": "EXPERIMENTAL: Claude Code hook API is evolving. This is a conceptual template.",
      "PLATFORM_GUIDE": "Use .sh on Unix/macOS and .ps1 on Windows.",
      "hooks": {
        "pre-command": ".agent/scripts/hook-pre-command.sh \"$COMMAND\"",
        "// windows-pre-command": "powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-pre-command.ps1 \"$COMMAND\"",
        "post-command": ".agent/scripts/hook-stop.sh",
        "// windows-post-command": "powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-stop.ps1",
        "on-session-start": "bash .agent/scripts/sync-task.sh && cat .agent/memory/current-task.md",
        "// windows-on-session-start": "powershell -ExecutionPolicy Bypass -File .agent/scripts/sync-task.ps1 ; Get-Content .agent/memory/current-task.md"
      }
    }
    ```
*   **Qwen Code (Full Tier):** Configure hooks in your Qwen Code config analogously to Claude Code.
*   **Cursor / Windsurf / Cline (Standard Tier):** These clients primarily use rule files (`.cursorrules`, `.windsurfrules`, `.clinerules`). Run the `bootstrap` script to generate these with the **Critical 3 Session Rules**.
*   **Gemini CLI (Basic Tier):** Does not natively support command hooks. Rely on the instructions in `GEMINI.md` and manually run the sync-task script (`.sh` on Unix, `.ps1` on Windows) at the start of a session.
*   **Aider (Basic Tier):** Uses `CONVENTIONS.md` as its context file and `.aider.conf.yml` for configuration — both auto-generated by `bootstrap`. No hooks are configured; safety rules are soft reminders only.

**6. 📡 Configure MCP Servers (Optional but Recommended)**

MCP servers extend your AI agent with external resources (docs, web, GitHub, memory). Setup depends on your client:

*   **Claude Code:**
    ```bash
    claude mcp add context7 npx -y @upstash/context7-mcp
    claude mcp add sequential-thinking npx -y @modelcontextprotocol/server-sequential-thinking
    ```
*   **Qwen Code:** Add MCP servers to your Qwen Code MCP config (see `.agent/templates/mcp/mcp-qwen.json`).
*   **Cursor:** Copy `.agent/templates/mcp/mcp-cursor.json` to `.cursor/settings.json`.
*   **RooCode/Cline:** Copy `.agent/templates/mcp/mcp-clinerules.json` to Cline MCP settings.
*   **Windsurf:** Copy `.agent/templates/mcp/mcp-windsurf.json` to Windsurf MCP settings.
*   **Gemini CLI:** Copy `.agent/templates/mcp/mcp-gemini.json` to Gemini CLI config (minimal profile).
*   **Aider:** Add MCP section to `.aider.conf.yml` (see `.agent/templates/mcp/mcp-aider.yml`).

Full guide: **[docs/mcp-guide.md](docs/mcp-guide.md)**.


If you are an agent without direct `mcp add` commands, inform the user they need to manually configure these servers in their respective MCP config files.

## Step 5: Verify `.gitignore` (Optional)
The bootstrap script from Step 2 already handles updating the `.gitignore`. You can verify that the following definitions exist in the project's `.gitignore`:

```text
# AI Toolbox specific
.beads/
.agent/memory/session-handover.md
.agent/memory/current-task.md
```

## Step 6: Qwen Code Setup (Automatic)

If Qwen Code is detected (either `qwen` command exists OR `.qwen/` directory exists), bootstrap automatically creates `.qwen/settings.json` with 6 AI Toolbox hooks:

| Hook | Purpose |
|---|---|
| `SessionStart` | Syncs task state from Beads/task tracker |
| `PreToolUse` | Validates heavy commands, recommends `rtk` wrapper |
| `PostToolUse` | Scans written/edited files for secrets and credentials |
| `Stop` | Updates session memory files before each response |
| `SessionEnd` | Full memory consolidation and handover creation |
| `PreCompact` | Injects architecture context before context compaction |

**No manual configuration needed** — hooks are created automatically by bootstrap.

**No CLI flag needed** — hooks are enabled by default when `.qwen/settings.json` contains hook configuration.

Qwen Code also supports **8 Sub-Agents** for parallel task delegation (reviewer, tester, frontend, backend, security, performance, documenter, handover). These are defined in `.qwen/agents/` and delegate automatically based on task context.

For manual setup or customization, see `.agent/templates/clients/qwen-hooks-unix.jsonc` (Linux/macOS) or your existing `.qwen/settings.json` (Windows).

## Step 7: Finalization
Once completed, read the `AGENT.md` file you just copied to understand your new operational bounds in this repository.
Then, output a message to the user:
> "✅ **AI Toolbox Environment initialized successfully.** The framework `.agent/` and rules are in place. Optional tools like `rtk` and `Beads` have been checked/installed. I have read the `AGENT.md` contract and am ready to work!
>
> 💡 **Tip:** If you are using Antigravity, you can now use native workflows like `/start`, `/sync`, and `/handover`!
>
> 💡 **Tip:** If you are using Qwen Code, hooks are enabled automatically when `.qwen/settings.json` contains hook configuration. 8 Sub-Agents are available for parallel task delegation."
