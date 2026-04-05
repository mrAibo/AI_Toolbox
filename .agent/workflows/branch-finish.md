# Finishing a Development Branch

This workflow defines what happens when a feature or fix is complete and ready to be integrated.

---

## When to run this workflow

- All tests pass
- Code review completed (`.agent/workflows/code-review.md`)
- Ready to merge, create a PR, or close the task

---

## Steps

### Step 1: Final Verification

Run all checks one last time:

```bash
rtk test    # All tests pass
rtk lint    # No lint errors
rtk diff    # Review all changes since last commit
```

### Step 2: Update Session Handover

Write a summary in `.agent/memory/session-handover.md`:

```markdown
## Completed this session
- [What was done]
- [Files changed]
- [Tests added/modified]

## Next steps
- [What should happen next]
```

### Step 3: Update Architecture Decisions

If the change involved any architectural decisions, record them in `.agent/memory/architecture-decisions.md`:

```markdown
### ADR-XXXX: [Title]
- Status: accepted
- Date: YYYY-MM-DD
- Context: [Why this decision was needed]
- Decision: [What was decided]
- Consequences: [Impact on the codebase]
```

### Step 4: Close the Beads Task

```bash
bd close "<ID>" "Completed: <short summary>"
```

### Step 5: Decide on Integration

Choose one:

| Option | When to use | Action |
|--------|-------------|--------|
| **Merge** | Simple fix, tested, no risk | `rtk git merge <branch>` |
| **Create PR** | Feature, team review needed | `gh pr create` |
| **Keep branch** | Work in progress, need to continue later | Nothing |
| **Discard** | Approach was wrong, need different direction | `git branch -D <branch>` |

### Step 6: Cleanup (if merging)

- Delete feature branch: `git branch -d <branch>`
- Check next ready task: `bd ready`
- If a task is ready, start working on it (return to Unified Workflow)

---

## Git Worktree (for complex features)

When working on a non-trivial task, prefer Git worktrees for isolation:

```bash
# Create isolated worktree
git worktree add ../feature-worktree <branch-name>
cd ../feature-worktree

# Work independently from main branch
# ...

# When done
git worktree remove ../feature-worktree
```

This keeps the main branch clean while you work.

---

## Anti-Patterns

| Anti-Pattern | Why it's bad | What to do instead |
|--------------|-------------|-------------------|
| Merging without final verification | Could break main | Always run rtk test + lint first |
| Closing a task without session handover | Next session doesn't know the state | Always update session-handover.md |
| Forgetting to record ADRs | Decisions get lost over time | Document non-trivial decisions |
| Leaving dead branches | Clutters the repo | Delete or document them |
