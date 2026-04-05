# Status Reporting Rules

This file defines when and how the AI agent reports its current status to the user.

The purpose is to make the agent's work transparent and traceable.

---

## Core Rule

**Never work silently.** Report what you're doing at every significant step.

---

## When to Report Status

### Step Transitions (MANDATORY)
When transitioning between workflow steps:

```
🔧 ACTIVE: Entering Step 5/9 — IMPLEMENT (TDD)
   → Task: [task description]
   → Phase: RED — Writing failing test
```

### Skill Usage (MANDATORY)
When applying a rule file or workflow:

```
📋 Applying: .agent/rules/tdd-rules.md — RED-GREEN-REFACTOR cycle
📋 Applying: .agent/workflows/code-review.md — Self-review checklist
```

### Tool Usage (RECOMMENDED)
When running significant commands:

```
🔧 Using: rtk test — compressed 50 lines → 8 lines (84% saved)
🔧 Using: rtk lint — 0 issues found
```

### MCP Usage (RECOMMENDED)
When querying MCP servers:

```
🌐 MCP context7: Found 3 Express.js routing patterns
🌐 MCP sequential-thinking: Structuring debug analysis
```

### Multi-Agent (MANDATORY)
When spawning or completing sub-agents:

```
🤖 Spawning Agent 1/3: Reviewing bootstrap.sh (general-purpose)
🤖 Agent 2/3 complete: 5 issues found in bootstrap.ps1
🤖 All agents complete — synthesizing results
```

### Error/Blocker (MANDATORY)
When something fails:

```
⚠️ BLOCKED: Cannot run tests — bd not installed
   → Falling back to manual task tracking
   → User action needed: go install github.com/steveyegge/beads@latest
```

---

## Status File

Update `.agent/memory/active-session.md` at each step transition:

```markdown
# Active Session — YYYY-MM-DD HH:MM UTC

## Current Step
- **Workflow:** [workflow name] (Step X/9 — [STEP NAME])
- **Task:** [task description] ([beads-id])
- **Phase:** [current phase, e.g. RED, GREEN, REVIEW]

## Active Skills & Rules
- [rule file] — [what it's doing]

## Active Tools
- [tool] — [usage stats]

## Active MCPs
- [mcp server] — [query count or last result]

## Multi-Agent Status
- Agents spawned: X
- Agents active: Y

## Progress
- Steps completed: X/9
- Subtasks done: X/Y
- Tokens saved (rtk): ~X
```

---

## Session End Summary

At session end (via hook-stop), write a summary to `.agent/memory/session-handover.md`:

```markdown
## Session Summary — YYYY-MM-DD HH:MM UTC

### Completed
- [What was done]
- [Steps completed]
- [Tests added/passed]

### Stats
- Tokens saved (rtk): ~X
- MCP queries: X
- Sub-agents used: X

### Next Step
- [What should happen next]
```

---

## What NOT to Report

Do NOT report every single small action:
- Individual file reads
- Simple grep/search operations
- Internal reasoning steps

DO report:
- Step transitions
- Skill/workflow applications
- Tool runs with meaningful output
- Agent spawn/complete events
- Errors and blockers
