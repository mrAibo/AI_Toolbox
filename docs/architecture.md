# AI Toolbox Architecture

This document provides a visual overview of how all components work together.

---

## High-Level Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER / AI AGENT                          │
│         (Claude Code, Qwen Code, Gemini CLI, etc.)              │
└───────────────┬───────────────────────────────────┬─────────────┘
                │                                   │
                ▼                                   ▼
┌───────────────────────────┐       ┌───────────────────────────────┐
│     ENTRY POINTS          │       │      HUMAN INTERFACE          │
│                           │       │                               │
│  CLAUDE.md  (Full)        │       │  README.md — Overview          │
│  QWEN.md    (Full)        │       │  CONTRIBUTING.md — Guide       │
│  SKILL.md   (Full)        │       │  CHANGELOG.md — History        │
│  .cursorrules (Standard)  │       │  docs/ — Detailed guides       │
│  .clinerules  (Standard)  │       │  examples/ — Usage examples    │
│  GEMINI.md    (Basic)     │       │  prompts/ — Ready-to-use       │
│  CONVENTIONS.md (Basic)   │       │                               │
└───────────────┬───────────┘       └───────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AGENT.md (Master Protocol)                    │
│                                                                  │
│  §1  General behavior    §8  Verification rules                 │
│  §2  Boot sequence       §9  Safety rules (+ MCP, Status)       │
│  §3  New project flow   §10  End-of-session behavior            │
│  §4  Execution rules    §11  Client-Specific Extensions         │
│  §5  Terminal rules     §12  Specialist Templates               │
│  §6  Memory rules       §13  Context-Driven Skill Selection     │
│  §7  Brainstorming rules §14  The Toolbox Toolkit                │
│                          §15  External Project Integrations      │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                ┌───────────┼───────────┐
                ▼           ▼           ▼
┌───────────────┐ ┌────────────────┐ ┌──────────────────────────┐
│   RULES       │ │   WORKFLOWS    │ │   SCRIPTS / HOOKS        │
│               │ │                │ │                          │
│ safety-rules  │ │ unified-       │ │ bootstrap.sh/.ps1        │
│ testing-rules │ │  workflow.md   │ │                          │
│ stack-rules   │ │ bug-fix.md     │ │ hook-pre-command.sh/.ps1 │
│ tdd-rules     │ │ code-review.md │ │ hook-stop.sh/.ps1        │
│ mcp-rules     │ │ branch-finish.md│ │ verify-commit.sh/.ps1    │
│ status-report │ │ multi-agent.md │ │ sync-task.sh/.ps1        │
│ template-     │ │ use-template.md│ │                          │
│  usage.md     │ │ adr.md         │ │                          │
└───────┬───────┘ └───────┬────────┘ └────────┬─────────────────┘
        │                 │                    │
        ▼                 ▼                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                        MEMORY LAYER                             │
│                                                                  │
│  architecture-decisions.md  ← ADRs (architectural choices)      │
│  integration-contracts.md   ← API contracts, schema expectations │
│  session-handover.md        ← Unfinished work, next steps       │
│  current-task.md            ← Active todo (synced from Beads)   │
│  runbook.md                 ← Operational procedures            │
│  active-session.md          ← Live status of current session    │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     EXTERNAL TOOLS                              │
│                                                                  │
│  ┌─────────┐  ┌───────┐  ┌────────────┐  ┌──────────────────┐  │
│  │   rtk   │  │ Beads │  │Superpowers │  │ Template Bridge  │  │
│  │         │  │       │  │            │  │                  │  │
│  │ Token   │  │ Task  │  │ TDD, Plan, │  │ 413+ specialist  │  │
│  │ opti-   │  │ Track-│  │ Debug,     │  │ agent templates  │  │
│  │ mization│  │ ing   │  │ Review     │  │ (26 categories)  │  │
│  └─────────┘  └───────┘  └────────────┘  └──────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    MCP Servers                           │   │
│  │  context7 │ sequential-thinking │ filesystem │ github    │   │
│  │  fetch    │ memory              │                        │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Data Flow: The 9-Step Unified Workflow

```
User: "Build feature X"
   │
   ▼
┌─────────┐     ┌───────────┐     ┌─────────┐     ┌──────────┐
│ 1. TASK │────▶│2.BRAINSTORM│────▶│3. PLAN  │────▶│4.ISOLATE │
│  Beads  │     │ AGENT.md  │     │ AGENT.md │     │(optional)│
│  create │     │   §7      │     │   §3      │     │worktrees │
└─────────┘     └───────────┘     └─────────┘     └──────────┘
                                                      │
                                                      ▼
                                              ┌──────────┐
                                              │5.IMPLEMENT│
                                              │  TDD      │
                                              │RED-GREEN- │
                                              │REFACTOR   │
                                              └─────┬────┘
                                                    │
                                                    ▼
┌─────────┐     ┌───────────┐     ┌─────────┐     ┌──────────┐
│9. CLOSE │◀────│8. FINISH  │◀────│7. VERIFY│◀────│6. REVIEW │
│  Beads  │     │branch-    │     │ testing │     │  code-   │
│  close  │     │ finish    │     │  rules  │     │ review   │
└─────────┘     └───────────┘     └─────────┘     └──────────┘
      │               │
      ▼               ▼
  Next task    session-handover
  (bd ready)   + active-session
```

---

## Tool Responsibilities

| Tool | Solves | How |
|------|--------|-----|
| **rtk** | Token bloat from long logs | Intercepts commands, compresses output 60-90% |
| **Beads** | Task tracking outside chat context | Graph database, syncs to `current-task.md` |
| **Superpowers** | Engineering discipline | Encoded in rules: TDD, Planning, Debugging, Review |
| **Template Bridge** | Specialist knowledge gaps | 413+ templates on-demand when skills aren't enough |
| **MCP** | External resource access | Docs, web, GitHub, memory — per client configs |
| **Status Reporting** | "What is the AI doing?" | `active-session.md` updated at each step |

---

## Session Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│                      SESSION START                          │
│                                                             │
│  Boot Sequence:                                             │
│  1. Environmental check (.agent/, rtk, bd)                 │
│  2. Read architecture-decisions.md                          │
│  3. Read integration-contracts.md                           │
│  4. Read session-handover.md (if exists)                    │
│  5. Run sync-task.sh → updates current-task.md              │
│  6. Summarize recovered context                             │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                      DURING SESSION                         │
│                                                             │
│  Agent follows Unified Workflow (9 steps)                   │
│  Status reported at each step → active-session.md           │
│  Heavy commands intercepted by rtk                          │
│  Multi-agent: spawn → execute → synthesize                  │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                       SESSION END                           │
│                                                             │
│  hook-stop.sh/ps1 runs automatically:                       │
│  1. Runs sync-task (final Beads export)                     │
│  2. Runs bd prime (refresh context)                         │
│  3. Appends active-session.md to session-handover.md        │
│  4. Reminds to update memory files                          │
└─────────────────────────────────────────────────────────────┘
```
