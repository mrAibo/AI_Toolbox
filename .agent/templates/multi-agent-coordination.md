# Multi-Agent Coordination Template

Use this template when orchestrating 2+ parallel sub-agents.

---

## Coordination Header

Copy this into `.agent/memory/current-task.md` before spawning agents.

```markdown
# Multi-Agent Task: Short title

- Orchestrator: [AI Agent Name]
- Date: YYYY-MM-DD
- Status: in-progress

## Sub-Tasks

| # | Agent Type | Prompt Summary | Status | Result Location |
|---|-----------|----------------|--------|-----------------|
| 1 | general-purpose | [What it should do] | pending | - |
| 2 | general-purpose | [What it should do] | pending | - |
| 3 | Explore | [What it should find] | pending | - |

## Synthesis
- [Fill in after all agents complete]

## Decisions
- [Any decisions made based on agent results]
```

---

## Sub-Agent Prompt Pattern

Use this structure when spawning each agent:

```
Task: [Clear, specific task description]

Scope: [What to cover, what to skip]
Output format: [Table, list, structured text — be specific]
Constraints: [File limits, depth limits, token budget]

Report findings concisely. Flag any issues with severity (🔴 High, 🟡 Medium, 🔵 Low).
```

---

## Result Synthesis Pattern

After all agents complete:

1. **Merge:** Combine all results into a single view
2. **Deduplicate:** Remove overlapping findings
3. **Prioritize:** Sort by severity/impact
4. **Decide:** What needs action vs. what's informational
5. **Record:** Update `session-handover.md` with summary

---

## Example: Code Review with 3 Agents

```
Agent 1 (general-purpose): "Review bootstrap.sh for syntax errors, dead code, and missing guards"
Agent 2 (general-purpose): "Review bootstrap.ps1 for the same issues"
Agent 3 (Explore): "Find all files referenced by AGENT.md that don't exist"

→ Synthesize: Merge all findings, remove duplicates, prioritize by severity
→ Report: "Found 12 issues: 3 High, 5 Medium, 4 Low"
```
