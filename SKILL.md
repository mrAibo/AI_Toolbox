---
name: AI Toolbox
description: A strict, memory-backed agentic development framework for terminal-based AIs. (Antigravity Manifest)
---

# AI Toolbox Skill (Antigravity Manifest) -- Tier: Full

> [!NOTE]
> This file is a specific manifest for the **Antigravity** agentic framework. If you are using Claude Code, Cursor, or other agents, please refer to the router files (CLAUDE.md, .cursorrules) or the master protocol in AGENT.md.
> As a **Full-Tier** client, Antigravity has access to hooks, multi-agent orchestration, plan mode, and sync automation.

This skill allows the assistant to follow the strict project standards defined in the **AI Toolbox** repository.

## Capabilities:
1. **Context Restoration:** Automatically restores session context via `AGENT.md` guidelines.
2. **Task Synchronization:** Syncs `Beads` (CLI task tracker) to readable markdown files.
3. **Session Handover:** Enforces recording of accomplishments to prevent "context amnesia".

## Instructions for the Assistant:
1.  **Always** read `AGENT.md` if the `.agent/` folder is detected.
2.  Follow the **Boot Sequence** before performing any implementation task.
3.  Use the **slash commands** in `.agent/workflows/` for routine operations.
4.  In Antigravity environments, prioritize native artifacts (`implementation_plan.md`, `task.md`, `walkthrough.md`) but keep them synchronized with the AI Toolbox state.
