# Example: Parallel Code Review with Multi-Agent

This example demonstrates a real code review session using 3 parallel sub-agents, exactly like the review round 3 on AI_Toolbox.

---

## Scenario

You need to review two bootstrap scripts (`bootstrap.sh` and `bootstrap.ps1`) and cross-reference all documentation files for consistency. Sequentially this would take 30+ minutes. With parallel agents: ~5 minutes.

---

## Step 1: Define Independent Tasks

| # | Agent Type | Task |
|---|-----------|------|
| 1 | `general-purpose` | Audit `bootstrap.sh` — syntax, guards, content parity |
| 2 | `general-purpose` | Audit `bootstrap.ps1` — same checks |
| 3 | `Explore` | Find all files referenced by AGENT.md/README that don't exist |

These tasks are independent — Agent 1 doesn't need Agent 2's output.

---

## Step 2: Spawn Agents in Parallel

```python
# Single message, 3 parallel calls:

agent(description="Audit bootstrap.sh", prompt="Review the entire file for:\n1. Syntax errors\n2. Missing guards on file creation\n3. Content parity with committed rules files\n4. Dead code\nReport with line numbers and severity.")

agent(description="Audit bootstrap.ps1", prompt="Review the entire file for:\n1. Syntax errors (unclosed here-strings)\n2. Missing guards\n3. Unused variables\n4. Content parity\nReport with line numbers and severity.")

agent(description="Cross-reference all docs", prompt="Find every [link](path) in AGENT.md, README.md, and all router files. Check if each target file exists. Report broken links.")
```

---

## Step 3: Synthesize Results

```
## Review Summary — 3 Agents

### Agent 1 (bootstrap.sh)
- 🔴 Found 3 files without guards
- 🟡 Content drift in testing-rules.md fallback

### Agent 2 (bootstrap.ps1)
- 🔴 Found 2 files unconditionally overwritten
- 🟡 Dead code: $QwenContent variable never used

### Agent 3 (Cross-reference)
- ✅ All 47 links valid
- ✅ No broken references

### Consolidated
- 5 High priority fixes
- 4 Medium improvements
- 0 broken links
```

---

## Key Takeaways

1. **Parallel saved ~20 min** — 3 agents ran simultaneously
2. **Independent prompts** — each agent had a self-contained task
3. **Structured output** — agents reported with severity + line numbers
4. **Easy synthesis** — results merged into a single table
5. **Used `Explore`** for simple file existence checks (cheaper than `general-purpose`)
