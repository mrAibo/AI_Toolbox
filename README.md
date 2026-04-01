# 🚀 AI Toolbox: Universal Terminal AI Workflow

A robust, reusable foundation for terminal-based AI-assisted development. 

This repository provides a strict workflow contract for AI agents like **Claude Code**, **OpenCode**, and **Gemini CLI**. It solves the three biggest problems of terminal-based AI development: Context Bloat, Project Amnesia, and Execution Drift.

---

## 🎯 The Purpose

Terminal AI agents are powerful, but without constraints, they tend to:
- Lose track of long-term architecture decisions.
- Dump 10,000-line raw build logs into the chat context, wasting tokens.
- Start writing code immediately without planning or verifying.
- Forget how to run tests or start the environment after a restart.

This toolbox fixes that by introducing a **Memory Layer**, a **Rule Layer**, and an **Automation Layer**.

---

## 📂 Architecture & Memory Contract

The repository enforces a strict separation between human instructions, AI workflow rules, and durable project memory.

```text
AI_Toolbox/
├── README.md               # Human-facing overview (You are here)
├── AGENT.md                # The AI's primary execution contract
├── .gitignore              # Ignores local output and temporary files
│
├── .agent/                 # The AI's "Brain"
│   ├── memory/             # Durable project state
│   │   ├── architecture-decisions.md  # Long-term architecture ADRs
│   │   ├── integration-contracts.md   # APIs, schemas, data expectations
│   │   ├── runbook.md                 # Recurring operational procedures
│   │   └── session-handover.md        # Unfinished work for the next session
│   │
│   ├── rules/              # Hard execution constraints
│   │   ├── stack-rules.md             # Allowed languages & dependencies
│   │   ├── testing-rules.md           # Verification requirements
│   │   └── safety-rules.md            # Prevention of destructive commands
│   │
│   ├── scripts/            # Automation & Hooks
│   │   ├── bootstrap.sh / .ps1        # Initial repo setup
│   │   ├── hook-pre-command.sh / .ps1 # Terminal safety guard
│   │   └── hook-stop.sh / .ps1        # Memory consolidation guard
│   │
│   └── templates/          # Standardized formats
│       ├── adr-template.md            # Architecture Decision Record
│       ├── issue-template.md          # Bug tracking
│       └── task-template.md           # Task definition
│
├── docs/                   # Detailed human guides (Setup, MCP, FAQ)
├── examples/               # Sample workflows
└── prompts/                # Quick-start prompts for the AI agent
```

---

## ⚙️ The Core Stack

This workflow assumes the use of a few key tools to keep the AI disciplined:

1. **[rtk (Rust Token Killer)](https://github.com/rtk-ai/rtk)**
   A console proxy optimizer. Heavy commands (like `pytest`, `mvn test`, `npm run build`) and large logs must be read through `rtk`. It compresses errors and tracebacks by 80%, saving tokens and keeping the AI focused.
2. **[Beads](https://github.com/steveyegge/beads)** (Optional but recommended)
   A local CLI task tracker. It moves the execution plan out of the AI's chat context and into a Git-backed graph.
3. **[Claude-Mem](https://github.com/thedotmack/claude-mem)** (Optional)
   A local vector database for storing episodic bug fixes and project experience.

---

## 🚀 Getting Started

### For Humans
1. Clone this repository to your local machine.
2. Run the bootstrap script for your OS to ensure all folders exist:
   - Linux/macOS: `bash .agent/scripts/bootstrap.sh`
   - Windows: `powershell .agent/scripts/bootstrap.ps1`
3. Connect your AI agent to the workspace.

### For AI Agents
Give your terminal AI agent this exact prompt to start a project:

> *"Use this repository as the strict project workflow standard. Read AGENT.md first and follow its Boot Sequence. Do not start coding until the memory is initialized."*

*(See the `prompts/` folder for German and Russian translations).*

---

## 🧠 The Agent Workflow

When the AI agent works in this repository, it follows a strict sequence defined in `AGENT.md`:

1. **Boot Sequence:** Upon starting, the agent reads `architecture-decisions.md` and `session-handover.md` to restore context.
2. **Brainstorming:** For new features, the agent analyzes and proposes solutions before writing code.
3. **Task Creation:** Work is broken down into small, verifiable steps.
4. **Execution:** Code is written and executed. Heavy commands are prefixed with `rtk`.
5. **Verification:** The agent must run tests or verify output before claiming success.
6. **Consolidation:** Before shutting down, the agent updates the handover and memory files.

---

## 🛡️ Hooks & Safety

The repository includes shell and PowerShell hooks in `.agent/scripts/`. 
If you configure your AI agent (like Claude Code) to use these hooks:
- **Pre-command hook:** Blocks the AI from running heavy test/build commands without the `rtk` prefix, and prevents raw `cat` of massive log files.
- **Stop hook:** Reminds the AI to consolidate its memory into `session-handover.md` before exiting.

---

## 📚 Further Reading

Check the `docs/` folder for detailed guides:
- `setup-linux.md` & `setup-windows.md`
- `mcp-guide.md` (How to integrate Model Context Protocol servers safely)
- `faq.md`
