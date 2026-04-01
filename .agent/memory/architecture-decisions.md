# Architecture Decisions

This file stores durable project-level decisions that should survive across sessions.

It is not a task tracker.
It is not a scratchpad.
It is the long-term memory for architectural and workflow decisions.

---

## How to use this file

Write short, clear entries whenever a meaningful project decision is made.

Each entry should answer:
- What was decided?
- Why was it decided?
- What alternatives were considered or rejected?
- What should future sessions remember?

---

## Decision format

Use this structure for new entries:

### ADR-XXXX: Short title
- Status: proposed / accepted / replaced / deprecated
- Date: YYYY-MM-DD
- Context:
- Decision:
- Consequences:
- Rejected alternatives:

---

## Current decisions

### ADR-0001: Repository-based project memory
- Status: accepted
- Date: 2026-04-01
- Context:
  Terminal-based AI agents lose context between sessions and tend to repeat questions or reintroduce old mistakes.
- Decision:
  Durable project memory is stored in repository files under `.agent/memory/`.
- Consequences:
  The agent must restore context from files at the start of a session.
- Rejected alternatives:
  Relying only on chat context.

### ADR-0002: Separate task memory from architecture memory
- Status: accepted
- Date: 2026-04-01
- Context:
  Tasks and architecture decisions serve different purposes.
- Decision:
  Beads is used for task flow and execution state, while `.agent/memory/architecture-decisions.md` stores long-term architectural knowledge.
- Consequences:
  The agent must not mix task progress with durable architecture decisions.
- Rejected alternatives:
  Keeping everything in a single running document.

### ADR-0003: Prefer structured execution over immediate coding
- Status: accepted
- Date: 2026-04-01
- Context:
  Immediate code generation often leads to drift, poor assumptions, and missing verification.
- Decision:
  Large or unclear requests must begin with brainstorming and structure before implementation.
- Consequences:
  The workflow starts with analysis, then planning, then execution.
- Rejected alternatives:
  Jumping directly into code for all requests.

### ADR-0004: Compress heavy terminal output
- Status: accepted
- Date: 2026-04-01
- Context:
  Raw build logs and test logs waste context and reduce agent quality.
- Decision:
  Heavy command output should be routed through `rtk` whenever possible, and large log files should be read with `rtk read`.
- Consequences:
  The agent should avoid raw log dumps.
- Rejected alternatives:
  Reading full raw logs directly into context.
