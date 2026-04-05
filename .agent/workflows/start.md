---
description: Trigger the mandatory Boot Sequence for AI Toolbox
---

1. Follow the **Definitive Boot Sequence** from `AGENT.md §2`.

Steps for reference and automation:
- **Environmental Check:** Verify presence of `.agent/` folder and recommended binaries (`rtk`, `bd`).
- Read ADRs and Integration Contracts.
- Read `.agent/memory/session-handover.md` if it exists.
- Run `.agent/scripts/sync-task.sh` (or `.ps1` on Windows) to get the latest task state.
- Summarize recovered context.
