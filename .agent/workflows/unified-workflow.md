# Unified Development Workflow

This is the PRIMARY workflow for all AI Toolbox projects. All tools work together automatically.

---

## The 9-Step Process

### 1. TASK (Beads)

Create or pick up a task:

```bash
bd create "feature description" -p high   # New task
bd ready                                    # Next ready task
bd update <ID> --claim                      # Claim it
```

Auto-loaded via `sync-task.sh/ps1` at session start.

### 2. BRAINSTORM (Superpowers → AGENT.md §7)

Analyze the task, identify constraints, propose 2-3 approaches.

- If unclear or architectural: use multi-agent parallel analysis
- Record decision in `.agent/memory/architecture-decisions.md`

### 3. PLAN (Superpowers → AGENT.md §3)

Break work into 2-5 minute tasks:

- Each task: clear input, output, verification step
- Store in `.agent/memory/current-task.md`

### 4. ISOLATE (optional)

For complex tasks, use Git worktrees or feature branches:

```bash
git worktree add ../feature-worktree <branch-name>
cd ../feature-worktree
```

### 5. IMPLEMENT (TDD → .agent/rules/tdd-rules.md)

For EACH sub-task, follow the RED-GREEN-REFACTOR cycle:

| Step | Action | Command |
|------|--------|---------|
| **RED** | Write failing test | Write test, no code yet |
| **VERIFY RED** | Confirm test fails | `rtk test` — MUST fail |
| **GREEN** | Write minimal code | Only enough to pass the test |
| **VERIFY GREEN** | Confirm test passes | `rtk test` — MUST pass |
| **REFACTOR** | Clean up code | Improve quality, tests stay green |
| **COMMIT** | Save | `rtk git commit -m "..."` |

**rtk** auto-optimizes all test/build output (60-90% fewer tokens).

### 6. REVIEW (.agent/workflows/code-review.md)

Run the self-review checklist before finishing:

- All tests pass (`rtk test`)
- No lint errors (`rtk lint`)
- No debug statements left
- Changes match original plan
- Edge cases handled

**For multi-agent:** Each sub-agent's output must pass review independently.

### 7. VERIFY (Superpowers → [.agent/rules/testing-rules.md](../rules/testing-rules.md))

Final verification run:

```bash
rtk test    # All tests pass
rtk lint    # No lint errors
```

Never claim completion without verification.

### 8. FINISH (.agent/workflows/branch-finish.md)

- Update session handover
- Record ADRs if needed
- Decide: merge, PR, or keep branch
- Clean up worktrees if used

### 9. CLOSE (Beads)

```bash
bd close "<ID>" "Completed: <short summary>"
bd ready  # What's next?
```

---

## Tool Coordination Matrix

| Step | Primary Tool | Auto-Trigger | Manual Override |
|------|-------------|-------------|-----------------|
| 1. TASK | Beads | `sync-task.sh/.ps1` | `bd create` |
| 2. BRAINSTORM | Superpowers / AGENT.md | AGENT.md §7 | `prompts/01-planning.md` |
| 3. PLAN | Superpowers / AGENT.md | AGENT.md §3 | — |
| 4. ISOLATE | Git worktrees | Optional | `git worktree add` |
| 5. IMPLEMENT | TDD + rtk | `hook-pre-command.sh/.ps1` | `rtk test` |
| 6. REVIEW | AI Toolbox Rules | `code-review.md` | — |
| 7. VERIFY | rtk + Superpowers | `.agent/rules/testing-rules.md` | `rtk test` |
| 8. FINISH | Beads + Memory | `hook-stop.sh/.ps1` | `branch-finish.md` |
| 9. CLOSE | Beads | — | `bd close` |

---

## When Existing Skills Aren't Enough

If the task requires specialized knowledge (Rust async, Kubernetes, GraphQL, etc.):

1. Follow **[.agent/rules/template-usage.md](../rules/template-usage.md)** — when and how to use specialist templates
2. Follow **[.agent/workflows/use-template.md](use-template.md)** — Gap Analysis → Search → Select → Adapt → Document → Execute
3. Access 413+ templates via `/browse-templates` (Claude Code) or `npx claude-code-templates@latest`

---

## The Complete Flow (Example)

```
User: "Build a REST API endpoint"
│
├─ Beads:     bd create "REST endpoint" → task in graph
├─ Brainstorm: 2 approaches (REST vs GraphQL) → choose REST
├─ Plan: 3 subtasks (schema, handler, tests)
│
├─ For each subtask:
│   ├─ RED: Write failing test
│   ├─ VERIFY RED: rtk test → fails ✓
│   ├─ GREEN: Write minimal code
│   ├─ VERIFY GREEN: rtk test → passes ✓
│   ├─ REFACTOR: Clean up
│   └─ COMMIT: rtk git commit
│
├─ REVIEW: code-review.md checklist → all items ✓
├─ VERIFY: rtk test + rtk lint → clean
├─ FINISH: session-handover.md updated
└─ Beads: bd close "REST endpoint complete"
```
