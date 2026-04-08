# Parallel Execution Rules

## Mandatory Parallelization

The following **MUST** use parallel agents or parallel tool calls:

- Fetching **2+ URLs** simultaneously → Use parallel web_fetch or a single agent with "fetch all in parallel"
- Reading **3+ independent files** → read_file in parallel within one message
- Running **independent verification checks** → parallel agents or parallel commands
- Reviewing **multiple files for the same dimension** → parallel agents (e.g., review 5 files at once)
- Researching **unrelated sub-topics** → parallel agents with independent prompts
- Checking **CI status across multiple runs** → parallel fetches

## Heuristic: "Can it run in parallel?"

Before executing multiple operations, ask:

1. **Do they depend on each other's output?** → If NO: **PARALLELIZE**
2. **Would sequential execution waste time?** → If YES: **PARALLELIZE**
3. **Are there 2+ independent sub-tasks?** → If YES: **PARALLELIZE**

## Anti-Patterns (NEVER do these)

- ❌ Sequential `web_fetch` for multiple independent URLs
- ❌ Reading files one-by-one when all are needed for context
- ❌ Running independent checks sequentially (e.g., CI status, then logs, then jobs)
- ❌ Researching unrelated topics one at a time
- ❌ Sequential code review of multiple files when one multi-file review would suffice
- ❌ Calling multiple independent API endpoints in sequence

## Correct Patterns

- ✅ Launch **multiple agents in a single message** for independent tasks:
  ```
  Agent 1: "Read commands.md and extract all features"
  Agent 2: "Read hooks.md and extract all events"
  Agent 3: "Read sub-agents.md and extract configuration"
  ```
- ✅ Use **`web_fetch` with multiple URLs in parallel** within one message
- ✅ Use **`read_file` for multiple files in parallel** within one message
- ✅ Spawn **2-5 agents for multi-dimensional code review** (correctness, quality, performance, audit)
- ✅ Parallel `run_shell_command` for independent commands

## Agent Types

| Type | When to use | Examples |
|------|-------------|----------|
| `Explore` | Fast file/keyword search, URL fetching | "Find all files matching pattern X", "Read this URL" |
| `general-purpose` | Complex research, multi-step analysis, code review | "Review this code for security issues", "Compare approaches A vs B" |

## Limits

- **Max 5 parallel agents** per message to avoid resource exhaustion
- Use **Explore** for simple tasks (search, read, fetch)
- Use **general-purpose** for complex tasks (analysis, review, research)
- For **>5 independent tasks**, batch them in groups of 5

## Self-Check Before Execution

Before sending a message with multiple tool calls, verify:
- [ ] Could any of these run in parallel instead of sequentially?
- [ ] Am I about to do 2+ web_fetch calls? → Do them in parallel
- [ ] Am I about to read 3+ files? → Read them in parallel
- [ ] Am I about to spawn agents one at a time? → Spawn them together
