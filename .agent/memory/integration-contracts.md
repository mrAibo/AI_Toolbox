# Integration Contracts

This file stores durable expectations about integrations, schemas, formats, and interfaces.

Its purpose is to help future sessions understand what must remain compatible.

---

## How to use this file

Update this file whenever one of the following changes:
- external API expectations
- internal service contracts
- input/output file formats
- database schema assumptions
- naming conventions that other tools depend on

Do not put brainstorming notes here.
Only store stable or expected contracts.

---

## Contract format

Use this structure:

### Contract name
- Type:
- Owner:
- Source:
- Expected input:
- Expected output:
- Constraints:
- Failure modes:
- Notes:

---

## Current contracts

### Project memory contract
- Type: repository workflow contract
- Owner: AI workflow
- Source: repository structure
- Expected input:
  The agent reads `README.md`, `AGENT.md`, and `.agent/memory/*.md`
- Expected output:
  The agent restores context before doing new work
- Constraints:
  Durable memory must stay concise and structured
- Failure modes:
  If memory files are outdated, the agent may make wrong assumptions
- Notes:
  Boot sequence must always read these files

### Terminal log handling contract
- Type: execution contract
- Owner: AI workflow
- Source: terminal rules
- Expected input:
  Large logs, test output, build output
- Expected output:
  Compressed, relevant log summaries through `rtk`
- Constraints:
  Large raw logs should not be injected directly into the model context
- Failure modes:
  If raw logs are used, context bloat and degraded reasoning may occur
- Notes:
  Prefer `rtk read <file>` for `.log` files

### Task tracking contract
- Type: workflow contract
- Owner: project execution
- Source: Beads
- Expected input:
  Epics, tasks, task state
- Expected output:
  A clear ready-task execution order
- Constraints:
  Durable architecture memory must not be mixed with task state
- Failure modes:
  If tasks and memory are mixed, the workflow becomes noisy and harder to resume
- Notes:
  Use Beads for execution state, not for full architecture history
