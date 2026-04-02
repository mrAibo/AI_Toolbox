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
├── SKILL.md                # Antigravity Skill manifest
├── GEMINI.md               # Antigravity context guide
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
│       ├── antigravity-plan.md        # Antigravity native plan
│       └── task-template.md           # Task definition
│
└── workflows/          # Antigravity Slash Commands
    ├── start.md / sync.md         # Routine automation
    └── handover.md                # Session wrap-up
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
4. **Terminal AI Agents**
   - **[OpenCode](https://opencode.ai/)**: An open-source terminal alternative.
   - **[Gemini CLI](https://geminicli.com)**: Google's console AI agent using Gemini models.
   - **[Aider](https://aider.chat/)**: (Optional) AI pair programming in your terminal.
5. **[MCP Servers](https://modelcontextprotocol.io/)**
   Model Context Protocol (MCP) integrations for GitHub, Docs, Databases, etc., to connect agents safely to resources.
6. **[context7](https://github.com/context7/context7)**
   Lazy-loading tool for providing up-to-date documentation accurately to the agent.
7. **[Template Bridge](https://github.com/maslennikov-ig/template-bridge) & [Superpowers](https://github.com/obra/superpowers)**
   Plugins for managing rigid TDD workflows and accessing expert agent templates.

---

## 🤖 One-Prompt Installation

Want to convert an existing project into an AI Toolbox compliant project? Open your terminal AI (Claude Code, OpenCode, Gemini CLI, RooCode) in your project directory and paste this exact prompt:

```text
Follow the setup instructions here to initialize the AI Toolbox environment:
https://raw.githubusercontent.com/mrAibo/AI_Toolbox/main/install.md
```

The AI will autonomously download the `.agent` folder, `AGENT.md`, run the bootstrap script to create the routers, and report back when finished.

---

## 🚀 Manual Installation & Usage

### 1. Set up the repo
Clone this repository as a starting point.
2. Run the bootstrap script for your OS to ensure all folders exist:
   - Linux/macOS: `bash .agent/scripts/bootstrap.sh`
   - Windows: `powershell .agent/scripts/bootstrap.ps1`
3. Connect your AI agent to the workspace.

### 2. For AI Agents (Manual setup)
Give your terminal AI agent this exact prompt to start a project:

> *"Use this repository as the strict project workflow standard. Read AGENT.md first and follow its Boot Sequence. Do not start coding until the memory is initialized."*

*(See the `prompts/` folder for German and Russian translations).*

---

## 🏁 How to Start Working

Depending on whether you are beginning something entirely new or just picking up yesterday's work, use one of the two approaches below:

### Scenario A: Starting a New Project or Major Feature
If you are at the very beginning of a project or want to plan a large new architecture, you need to trigger the **Brainstorming & Planning Mode**. 

1. Launch your AI agent in the terminal.
2. Give a **Planning Prompt**:
   > *"I want to build a [describe project/feature]. According to our AGENT.md rules, do not write code yet. Analyze this request, identify constraints, and propose 2-3 architectural approaches to brainstorm."*
3. The AI will brainstorm with you. Once you decide on a path, it will automatically record the decision in `.agent/memory/architecture-decisions.md`, create a structured task plan (e.g., via `bd`), and then begin execution.

### Scenario B: Continuing an Existing Project
...
3. Give an **Execution Prompt**:
   > *"We are continuing our work. Please execute your Boot Sequence to read our memories and sync the tasks, then pick up the next step."*
4. The AI autopilot engages: It restores its context from `.agent/memory/`, checks `current-task.md`, and begins implementing the exact next step without getting sidetracked.

### Scenario C: Antigravity Native Mode
If you are using the **Antigravity** assistant, the toolbox is a first-class citizen.

1. Launch Antigravity.
2. Use **Slash Commands**:
   - Type `/start` to boot the project memory.
   - Type `/sync` to update your task list artifact.
   - Type `/handover` to wrap up and generate a walkthrough.
3. Antigravity will automatically use native artifacts (`implementation_plan.md`, `task.md`) for a premium experience.

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
