# FAQ

## General

### Why are there so many files?
Because the repository separates human docs, AI rules, memory, templates, and scripts. Each file serves a specific purpose — the AI reads rules, humans read docs, and hooks automate execution.

### Why not keep everything in README?
Because the agent needs a stable execution contract, not only a human overview. The README is for humans; `AGENT.md` is the AI's primary instruction set.

### Why use memory files?
Because sessions reset, but the repository should remember important decisions, unfinished work, and integration contracts. Memory files persist across AI restarts.

### Is this Open Source?
Yes — MIT License. Fork it, modify it, use it for any project.

---

## Setup & Installation

### How do I install AI Toolbox in a new project?
The fastest way: open your terminal AI in the project directory and paste this prompt:
```
Follow the setup instructions here to initialize the AI Toolbox environment:
https://raw.githubusercontent.com/mrAibo/AI_Toolbox/main/INSTALL.md
```
The AI will download everything, run bootstrap, and configure hooks.

### Do I need all the external tools (rtk, Beads, MCP)?
No. The core works with just `AGENT.md` and the bootstrap scripts. External tools are optional enhancements:
- **rtk** — token optimization (highly recommended)
- **Beads** — task tracking (recommended)
- **MCP** — external resources (optional)

### Can I use AI Toolbox with any AI client?
Yes. It supports Claude Code, Qwen Code, Gemini CLI, Cursor, RooCode/Cline, Windsurf, and Aider. Each client gets its own router file with tier-appropriate instructions.

---

## Workflows

### What is the Unified Workflow?
It's the 9-step process that governs all development work:
1. **TASK** — Create/pick up a task via Beads
2. **BRAINSTORM** — Analyze, propose approaches
3. **PLAN** — Break into 2-5 min subtasks
4. **ISOLATE** — (Optional) Use Git worktrees
5. **IMPLEMENT** — TDD: RED → GREEN → REFACTOR
6. **REVIEW** — Self-review checklist
7. **VERIFY** — Final test + lint run
8. **FINISH** — Update handover, decide on merge
9. **CLOSE** — Close task in Beads, pick next

### What if I just want to fix a quick bug?
The Bug-Fix Workflow is a streamlined 5-phase process: Reproduce → Identify → Fix → Verify → Record. It still requires a regression test and ADR documentation for non-trivial bugs.

### Can the AI work on multiple tasks in parallel?
Yes — the Multi-Agent Workflow allows spawning 2-5 parallel agents for independent sub-tasks. Each agent's output must pass the review gate before integration.

---

## Tools Integration

### What does rtk actually do?
rtk (Rust Token Killer) intercepts heavy shell commands, compresses their output by 60-90%, and feeds only essential info to the AI. Example: `npm test` with 3000 lines becomes 300 lines.

### How do Beads and AI Toolbox work together?
Beads stores tasks in a graph database. The AI Toolbox syncs Beads state to `.agent/memory/current-task.md` at session start, so the AI always knows the current task even after restarts.

### What are the 413+ specialist templates?
Template Bridge provides access to 413+ specialist agent templates across 26 categories (Security, DevOps, AI/ML, Web3, Rust, Go, etc.). They're used when existing AI Toolbox skills (TDD, Planning, Debugging) aren't sufficient for a specialized task.

### Do I need to configure MCP servers?
Only if you want external resource access. The minimal setup (context7 + sequential-thinking) works with one command: `claude mcp add context7 npx -y @upstash/context7-mcp`. See [MCP Guide](mcp-guide.md) for all clients.

---

## Status Reporting

### How do I know what the AI is doing?
The agent reports status at every significant step:
```
🔧 ACTIVE: Entering Step 5/9 — IMPLEMENT (TDD)
   → Task: GET /users/:id (bd-a1b2c3)
   → Phase: RED — Writing failing test
📋 Applying: .agent/rules/tdd-rules.md
🔧 Using: rtk test — compressed 50 lines → 8 lines (84% saved)
```
The live status is also tracked in `.agent/memory/active-session.md`.

### What happens when the session ends?
The `hook-stop.sh/ps1` script automatically writes a session summary to `session-handover.md` from `active-session.md`. Next session, the Boot Sequence reads this and restores context.

---

## Troubleshooting

### Bootstrap fails on Windows
Run PowerShell as Administrator and execute: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`. Then run `powershell -ExecutionPolicy Bypass -File .agent/scripts/bootstrap.ps1`.

### The AI doesn't follow the workflow
Make sure `AGENT.md` is in the project root and the AI reads it at session start. For Claude Code, this is automatic via `CLAUDE.md`. For other clients, their respective router file points to `AGENT.md`.

### rtk is not found
Install Rust first (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh` or https://rustup.rs/ for Windows), then run `cargo install --git https://github.com/rtk-ai/rtk`. **Do NOT use `cargo install rtk`** — that installs a different project (Rust Type Kit). After installation, run `rtk init -g` to install hooks for your AI client.

### Beads is not found
Install Go first, then run `go install github.com/steveyegge/beads/cmd/bd@latest`. Initialize with `bd init` in your project directory. Alternatively, download the binary directly from https://github.com/steveyegge/beads/releases and place `bd` (or `bd.exe` on Windows) in your PATH.

### MCP servers fail to connect
Ensure Node.js and `npx` are installed. For Claude Code, use `claude mcp add`. For other clients, copy the JSON config from `.agent/templates/mcp/` to your client's MCP settings. See [MCP Guide](mcp-guide.md) for client-specific instructions.
