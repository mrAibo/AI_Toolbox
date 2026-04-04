# AI Toolbox Installation Instructions (For AI Agents)

You are an AI assistant (such as Claude Code, OpenCode, Gemini CLI, or Antigravity) and the user has asked you to install the "AI Toolbox" workflow into the current repository/directory.

## Phase 0: Environment Discovery
Before you start, identify your own environment:
1.  **Operating System:** Are you running on Linux/macOS (Bash) or Windows (PowerShell)? Choose the corresponding commands in the steps below.
2.  **Platform Identity:** 
    - If you are **Claude Code**, you can use `mcp add` commands.
    - If you are **Antigravity**, you have access to **native slash-command workflows** and **artifacts**; prioritize these.
    - If you are **Gemini CLI** or **OpenCode**, follow the generic terminal instructions.
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

**1. rtk (Rust Token Killer)**
- Check if `rtk` is installed (e.g. `rtk --version`).
- If missing, ask the user if they have Rust installed. If yes, run `cargo install rtk`. If no, warn the user they need `rtk` installed to use the agent safely.

**2. Beads (Task Tracker)**
- Check if `bd` is installed (e.g. `bd version`).
- If missing, check if `go` is installed. If yes, run `go install github.com/steveyegge/beads@latest`. If no, warn the user.

## Step 4: Configure MCP Servers & Plugins
If you are **Claude Code** (or can execute configuring scripts), attempt to install the following recommended MCP servers and plugins. If they require cloning a repository, clone them into a tools directory (e.g., `~/.mcp-servers/` or `%USERPROFILE%\.mcp-servers\`):

**1. Core Protocol Servers**
```bash
claude mcp add context7 npx -y @context7/server
claude mcp add sequential-thinking npx -y @modelcontextprotocol/server-sequential-thinking
```

**2. Claude-Mem (Vector DB Memory)**
- Repository: `https://github.com/thedotmack/claude-mem`
- *Instruction for AI:* Clone this repository if missing, follow its build instructions, and add it to the MCP configuration.

**3. Template Bridge & Superpowers**
- Repositories: `https://github.com/maslennikov-ig/template-bridge` & `https://github.com/obra/superpowers`
- *Instruction for AI:* Check if these plugins/MCPs are active in your environment. If not, inform the user or attempt to configure them if valid installation commands are known.

**4. ⚡ Auto-Configure Terminal Hooks (CRITICAL)**
If your agent framework (Claude Code, OpenCode, Gemini CLI) supports execution hooks or start parameters, you MUST configure them automatically right now:
- Set `pre-command` hook to: `.agent/scripts/hook-pre-command.sh "$COMMAND"` (or `.ps1 "$COMMAND"` on Windows).
- Set `post-command` / `stop` hook to: `.agent/scripts/hook-stop.sh` (or `.ps1`).
- *If you configure this via a local JSON/TOML settings file (like `.claude.json` or `.opencode.yml`), create/update it now in the project root.*

If you are an agent without direct `mcp add` commands, inform the user they need to manually configure these servers in their respective MCP config files.

## Step 5: Update `.gitignore`
Append the following definitions to the project's existing `.gitignore`. If it does not exist, create it:

```text
# AI Toolbox specific
.beads/
.agent/memory/session-handover.md
.agent/memory/current-task.md
```

## Step 6: Finalization 
Once completed, read the `AGENT.md` file you just copied to understand your new operational bounds in this repository. 
Then, output a message to the user:
> "✅ **AI Toolbox Environment initialized successfully.** The framework `.agent/` and rules are in place. Optional tools like `rtk` and `Beads` have been checked/installed. I have read the `AGENT.md` contract and am ready to work!
>
> 💡 **Tip:** If you are using Antigravity, you can now use native workflows like `/start`, `/sync`, and `/handover`!"
