# Antigravity Environment Specifics

This file defines how to work with the **AI Toolbox** when using the **Antigravity** assistant environment.

---

## 🚀 Native Workflows (Slash Commands)

Use the built-in slash commands defined in `.agent/workflows/` for routine operations:

- `/start`: Performs the **Boot Sequence** (restores context, syncs tasks).
- `/plan`: Generates an **Implementation Plan** from the template.
- `/sync`: Synchronizes `bd` (Beads) state with project memory and artifacts.
- `/adr`: Records an **Architecture Decision Record** (ADR).
- `/handover`: Finalizes the session, updates memory, and generates a walkthrough.

---

## 📄 Artifact Management

Antigravity uses native artifacts to display structured project information. Maintain these as first-class citizens:

- **Implementation Plan:** Use `/plan` to trigger the `implementation_plan.md` artifact.
- **Task Tracking:** Always maintain the `task.md` artifact. Sync it with `/sync`.
- **Session Walkthrough:** Always generate a `walkthrough.md` artifact during the `/handover` workflow.

---

## 🧩 Antigravity Memory Coordination

While the AI Toolbox uses `.agent/memory/` for universal storage, Antigravity-specific artifacts provide the visual representation. Ensure they are always synchronized before concluding a session.
