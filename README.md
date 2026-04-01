# AI Toolbox

A reusable foundation for terminal-based AI-assisted development.

This repository is meant to help developers build a structured workflow for AI agents such as Claude Code, OpenCode, and Gemini CLI. The goal is to reduce context bloat, preserve project memory, and make the agent behave more like a disciplined engineering assistant than a free-form chat model.

---

## Why this repository exists

Terminal-based AI tools are powerful, but they quickly become messy without structure. Large logs, missing project memory, unclear priorities, and unbounded context can lead to poor results.

This toolbox tries to solve that by introducing:

- A clear separation between human-facing documentation and agent-facing rules.
- A durable memory layer for project decisions and contracts.
- A task layer for execution order and state tracking.
- Automation hooks for safe command handling.
- A workflow that supports brainstorming, planning, implementation, and verification.

---

## What this repository is for

This repository is a workflow contract for AI-assisted development.

It is especially useful if you want to:

- Use Claude Code, OpenCode, or Gemini CLI in a more reliable way.
- Keep long-running project memory outside the chat context.
- Avoid re-explaining architecture decisions over and over.
- Force structured execution instead of immediate code generation.
- Keep logs readable and reduce token waste.
- Support both Linux and Windows development environments.

---

## Core ideas

### 1. Task memory is not the same as project memory
- **Beads** is used for tasks, order, and execution state.
- `.agent/memory/*.md` is used for durable project memory.
- `README.md` is for humans.
- `AGENT.md` is for the AI agent.

### 2. Logs should be compressed
Large error logs, build logs, and test outputs should not be pasted raw into chat. They should be processed through `rtk` so the agent sees the useful part instead of the noise.

### 3. New projects should start with brainstorming
The agent should not begin by writing code. It should first brainstorm, then choose an approach, then record the decision, then create tasks, then implement.

### 4. The agent should verify before claiming success
No task should be considered complete without actual verification.

---

## Repository structure

Recommended structure:

```text
AI_Toolbox/
├─ README.md
├─ AGENT.md
├─ .gitignore
├─ .agent/
│  ├─ rules/
│  │  ├─ stack-rules.md
│  │  ├─ testing-rules.md
│  │  └─ safety-rules.md
│  ├─ memory/
│  │  ├─ architecture-decisions.md
│  │  ├─ integration-contracts.md
│  │  ├─ session-handover.md
│  │  └─ runbook.md
│  ├─ templates/
│  │  ├─ adr-template.md
│  │  ├─ task-template.md
│  │  └─ issue-template.md
│  └─ scripts/
│     ├─ hook-pre-command.sh
│     ├─ hook-pre-command.ps1
│     ├─ hook-stop.sh
│     ├─ hook-stop.ps1
│     ├─ bootstrap.sh
│     └─ bootstrap.ps1
├─ docs/
│  ├─ setup-linux.md
│  ├─ setup-windows.md
│  ├─ mcp-guide.md
│  └─ faq.md
├─ examples/
│  ├─ sample-beads-flow.md
│  ├─ sample-memory-update.md
│  └─ sample-agent-session.md
└─ prompts/
   ├─ bootstrap-en.txt
   ├─ bootstrap-de.txt
   └─ bootstrap-ru.txt
```

---

## Main components

### rtk
[rtk](https://github.com/rtk-ai/rtk) is used to compress terminal output and reduce token waste when the agent reads build logs or error logs.

### Beads
[Beads](https://github.com/steveyegge/beads) is used as the task tracker and short-term execution memory. It keeps the current workflow outside the chat context.

### Superpowers
[Superpowers](https://github.com/obra/superpowers) provides agent workflow and structured skills for tasks such as brainstorming, review, and disciplined implementation.

### Template Bridge
Template Bridge is used to connect the agent workflow with reusable templates and structured project patterns.

### Claude-Mem
[Claude-Mem](https://github.com/thedotmack/claude-mem) stores episodic memory: bug fixes, repeated patterns, and important project lessons.

---

## How to use this repository with an AI agent

1. Give the agent the repository link.
2. Tell the agent to read `AGENT.md` first.
3. Ask the agent to follow the workflow step by step.
4. If a tool or plugin is missing, continue with the core workflow and document the missing part.
5. Keep architecture decisions and project memory in `.agent/memory/`.
6. Keep task execution state in Beads.

Example prompt:

```text
Use this repository as the strict project workflow standard.
Read AGENT.md first and follow it step by step.
If something is missing, keep the core workflow and note the missing part in memory.
```

---

## Workflow overview

### For a new project
1. Brainstorm the idea first.
2. Record the chosen architecture in memory.
3. Create an epic in Beads.
4. Break the work into tasks.
5. Implement one ready task at a time.
6. Verify the result.
7. Update memory and handover files.

### For an existing project
1. Read project memory.
2. Check the current Beads state.
3. Work only on the next ready task.
4. Use `rtk` for large logs or heavy command output.
5. Verify before claiming success.

---

## Notes for Claude Code, OpenCode, and Gemini CLI

This repository is intentionally agent-neutral.

It should work as a shared workflow standard for:

- Claude Code
- OpenCode
- Gemini CLI

The exact plugin, hook, or MCP configuration may differ by tool, but the core idea remains the same:
- memory in files,
- tasks in a tracker,
- logs through `rtk`,
- verification before completion.

---

## Original projects

- rtk: https://github.com/rtk-ai/rtk
- Beads: https://github.com/steveyegge/beads
- Superpowers: https://github.com/obra/superpowers
- Template Bridge: https://github.com/maslennikov-ig/template-bridge
- Claude-Mem: https://github.com/thedotmack/claude-mem

---

## Next step

The next files to fill are:

- `AGENT.md`
- `.agent/memory/architecture-decisions.md`
- `.agent/memory/integration-contracts.md`
- `.agent/rules/*.md`
- `.agent/scripts/*.sh` / `.ps1`
