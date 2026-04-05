# Multi-Agent Orchestration Workflow

This workflow defines when and how to spawn sub-agents for parallel execution.

---

## When to Use Multi-Agent

Use parallel agents when the task is:
- **Large scope** — 3+ independent sub-tasks (e.g. audit 5 files, review 3 modules)
- **Time-critical** — sequential execution would take too long
- **Naturally partitioned** — sub-tasks don't depend on each other's output

**Do NOT use multi-agent when:**
- Task B depends on Task A's output (sequential required)
- The task is simple and fits in one agent
- Token budget is tight (each agent consumes context)

---

## Agent Type Selection

| Task Type | Agent Type | Example |
|-----------|------------|---------|
| Deep analysis, complex research | `general-purpose` | Code review, architecture audit |
| Fast file/keyword search | `Explore` | Find all API endpoints, locate config files |
| Mixed (explore + analyze) | Both in parallel | Explore finds files → general-purpose analyzes them |

---

## Orchestration Pattern

### Step 1: Define Independent Tasks
Break the work into 2-5 independent sub-tasks. Each task must have:
- Clear, self-contained prompt
- Expected output format
- No dependency on other sub-task results

### Step 2: Spawn Agents in Parallel
Launch all agents in a single message with multiple tool calls:

```
agent: "Audit bootstrap.sh for X, Y, Z"     → general-purpose
agent: "Audit bootstrap.ps1 for X, Y, Z"   → general-purpose
agent: "Find all config files in project"   → Explore
```

### Step 3: Collect and Synthesize
- Wait for all agents to complete
- Merge results into a single summary
- Resolve any contradictions
- Report to user with consolidated findings

---

## Coordination via Memory

Use `.agent/memory/` to share state between agents:

1. **Before spawning:** Write task breakdown to `.agent/memory/current-task.md`
2. **During execution:** Agents write results to `.agent/memory/session-handover.md`
3. **After completion:** Orchestrator synthesizes all results

---

## Error Handling

If an agent fails:
1. Retry once with a more specific prompt
2. If still failing, fall back to sequential execution
3. Document the failure in session-handover.md

---

## Token Budget Management

- Keep sub-agent prompts concise (under 500 tokens each)
- Ask agents to return structured output (tables, lists)
- Use `Explore` for simple searches (cheaper than `general-purpose`)
