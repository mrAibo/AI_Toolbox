# Code Review Workflow

This workflow defines the self-review process that runs BEFORE merging or marking a task complete.

The purpose is to catch issues before they reach production.

---

## When to run this workflow

- Before merging a feature branch
- Before marking a task as complete
- Before closing a Beads task
- After all tests pass, before final commit

---

## Pre-Review Checklist

Work through each item. Do NOT skip any.

### Code Quality
- [ ] All tests pass (`rtk test` — exit code 0)
- [ ] No lint errors (`rtk lint` — exit code 0)
- [ ] No `console.log`, `print`, `dbg`, or debug statements left
- [ ] No commented-out code blocks
- [ ] No TODO comments without corresponding issue/task reference

### Correctness
- [ ] Changes match the original plan (check `.agent/memory/current-task.md`)
- [ ] Edge cases are handled (null input, empty strings, boundary values)
- [ ] Error messages are actionable for the end user
- [ ] No hardcoded credentials, tokens, or secrets

### Architecture
- [ ] No new dependencies without justification
- [ ] New code follows existing project patterns
- [ ] Public APIs are documented
- [ ] Breaking changes are documented in `architecture-decisions.md`

### Testing
- [ ] New code has tests (TDD cycle followed)
- [ ] Tests cover both happy path and error cases
- [ ] Test names describe the behavior being tested

---

## Review Process

### Step 1: Summarize

Write a brief summary of what was changed and why:

```
## Changes
- [File]: [What changed and why]
- [File]: [What changed and why]
```

### Step 2: List risks

Identify any risks or edge cases not covered:

```
## Risks and Open Questions
- [Risk or open question]
- [Risk or open question]
```

### Step 3: Final verification

Run one last verification:

```bash
rtk test    # All tests pass
rtk lint    # No lint errors
rtk diff    # Review all changes
```

### Step 4: Decision

- **If issues found:** Fix them and restart the review (go back to Step 1).
- **If clean:** Proceed to finish (`.agent/workflows/branch-finish.md`).

---

## Multi-Agent Review

When multiple sub-agents produced code:

1. Review each sub-agent's output independently
2. Check for conflicts between sub-agent changes
3. Verify integration points work (end-to-end test)
4. Only approve when ALL sub-agent outputs pass review

---

## Anti-Patterns

| Anti-Pattern | Why it's bad | What to do instead |
|--------------|-------------|-------------------|
| Skipping the checklist | Easy to miss obvious issues | Work through each item |
| "Looks good to me" without running tests | Assumption without evidence | Always run tests and lint |
| Reviewing only new code | Misses interaction with existing code | Review the full diff |
| Ignoring test coverage | Untested code is a time bomb | Require tests for new logic |
