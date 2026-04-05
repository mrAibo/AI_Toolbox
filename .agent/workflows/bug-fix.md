# Bug Fix Workflow

This workflow defines the structured process for identifying, fixing, and documenting bugs.

---

## Core Principle

> **Never fix a bug without first reproducing it.**

---

## Phase 1: Reproduce

**Goal:** Confirm the bug exists and understand its trigger.

1. Run the reproduction step or test that demonstrates the bug
2. Capture the actual output (via `rtk` for large outputs)
3. Note the expected output

**Output:**
```
Bug: [Short description]
Repro Step: [Exact command or user action]
Actual: [What happened]
Expected: [What should have happened]
```

**If you cannot reproduce it:**
- Ask the user for more details
- Check if the bug was already fixed
- Check if environment/config differs from expected

---

## Phase 2: Identify

**Goal:** Find the root cause.

1. Trace the error from the reproduction step backwards
2. Check recent changes (`git log`, `git diff`) — regression?
3. Check related rules, configs, and integrations
4. Identify the **smallest change** that would fix the bug

**Output:**
```
Root Cause: [What causes the bug]
Affected File(s): [Which files need to change]
Risk: [Low/Medium/High — what else could break?]
```

---

## Phase 3: Fix

**Goal:** Apply the minimal fix.

1. Write the fix (smallest possible change)
2. Do NOT refactor unrelated code unless asked
3. If the fix requires architectural changes, stop and propose a plan first

---

## Phase 4: Verify

**Goal:** Confirm the bug is fixed and no regressions exist.

1. Re-run the reproduction step from Phase 1
2. Confirm actual output now matches expected output
3. Run related tests (if any) to check for regressions
4. Run `verify-commit.sh` / `.ps1` if committing

**Verification Checklist:**
- [ ] Original reproduction step passes
- [ ] Related tests pass (if any)
- [ ] No new warnings from verify-commit
- [ ] User-impacting behavior is correct

---

## Phase 5: Record

**Goal:** Document the fix so it doesn't get lost.

If the bug was non-trivial, record it in `.agent/memory/architecture-decisions.md`:

```markdown
### ADR-XXXX: Fix [Bug Title]
- Status: accepted
- Date: YYYY-MM-DD
- Context: [What was the bug, how was it triggered]
- Decision: [What was the fix]
- Root Cause: [Why did it happen]
- Consequences: [Any side effects, trade-offs, or future considerations]
```

Also update `.agent/memory/session-handover.md` if the fix changes the current work context.

---

## Quick Reference

| Phase | Question | Output |
|-------|----------|--------|
| 1. Reproduce | "Can I trigger it?" | Repro step + actual vs expected |
| 2. Identify | "Why does it happen?" | Root cause + risk assessment |
| 3. Fix | "What's the smallest change?" | Minimal fix |
| 4. Verify | "Is it really fixed?" | Repro passes + no regressions |
| 5. Record | "Will we remember this?" | ADR entry (if non-trivial) |

---

## Anti-Patterns to Avoid

| Pattern | Why It's Bad | What to Do Instead |
|---------|-------------|-------------------|
| Fix without reproducing | Might fix the wrong thing | Always reproduce first |
| Refactor while fixing | Introduces new bugs | Fix only, refactor separately |
| No verification | No proof it works | Always re-run the repro step |
| No documentation | Same bug returns | Record in ADR if non-trivial |
| Suppress the error | Hides the real problem | Fix the root cause |
