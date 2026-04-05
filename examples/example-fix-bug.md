# Example: Fixing a Bug — Structured Debugging Workflow

How AI Toolbox finds and fixes bugs systematically, not by guessing.

---

## The Task

> "The GET /users/:id endpoint sometimes returns 500 instead of 404 for non-existent users."

---

## Phase 1: REPRODUCE (Bug-Fix Workflow §1)

**Goal:** Confirm the bug and understand its trigger.

The agent writes a reproduction test:

```typescript
// bug-repro.test.ts
it("should return 404 for non-existent user, not 500", async () => {
  const response = await request(app).get("/users/nonexistent-id");
  expect(response.status).toBe(404); // Currently returns 500
});
```

Runs it:

```bash
$ rtk test -- bug-repro.test.ts
❌ FAIL bug-repro.test.ts
  GET /users/:id › should return 404 for non-existent user
    Expected: 404
    Received: 500
```

**Status output:**
```
🔧 ACTIVE: Bug Fix — Phase 1/5: REPRODUCE
   → Bug: GET /users/:id returns 500 instead of 404
   → Repro: Test case with nonexistent ID
   → Actual: 500 Internal Server Error
   → Expected: 404 Not Found
```

---

## Phase 2: IDENTIFY (Bug-Fix Workflow §2)

**Goal:** Find the root cause.

The agent traces backwards from the error:

```
## Trace
1. 500 comes from Express error handler
2. Handler: user-handler.ts line 23
3. There: const user = await repo.findById(id)
4. If user === null → code crashes at user.toJSON()

## Root Cause
findById returns null for non-existent IDs.
Code doesn't check for null before calling .toJSON().
```

Checks `git log`:

```bash
$ rtk git log --oneline -5 -- user-handler.ts
a1b2c3 feat: add GET /users/:id endpoint
```

Not a regression — bug existed since the endpoint was created.

**Status output:**
```
🔧 ACTIVE: Bug Fix — Phase 2/5: IDENTIFY
   → Root Cause: Missing null check before .toJSON()
   → Affected: user-handler.ts:23
   → Risk: Low — one-line fix
```

---

## Phase 3: FIX (Bug-Fix Workflow §3)

**Goal:** Minimal fix.

```typescript
// BEFORE (line 23)
const user = await repo.findById(id);
res.json(user.toJSON()); // 💥 crashes if user is null

// AFTER
const user = await repo.findById(id);
if (!user) return res.status(404).json({ error: "User not found" });
res.json(user.toJSON());
```

Only 2 lines added. No refactoring.

**Status output:**
```
🔧 ACTIVE: Bug Fix — Phase 3/5: FIX
   → Changed: 2 lines in user-handler.ts
   → No refactoring — minimal fix only
```

---

## Phase 4: VERIFY (Bug-Fix Workflow §4)

**Goal:** Confirm the fix, check for regressions.

```bash
$ rtk test
✅ PASS (13 tests, 48ms)
   → bug-repro.test.ts: NOW PASSES
   → All 12 existing tests: still pass

$ rtk lint
✅ No issues
```

Agent also checks edge cases:

```typescript
it("should return 400 for invalid UUID format", async () => {
  const response = await request(app).get("/users/not-a-uuid");
  expect(response.status).toBe(400);
});
```

**Status output:**
```
🔧 ACTIVE: Bug Fix — Phase 4/5: VERIFY
   → Repro test: NOW PASSES ✅
   → All 13 tests: pass
   → Lint: clean
   → Edge case (invalid UUID): handled
```

---

## Phase 5: RECORD (Bug-Fix Workflow §5)

**Goal:** Document the fix so it doesn't return.

The agent records in `architecture-decisions.md`:

```markdown
### ADR-0043: Null check required for findById results
- Status: accepted
- Date: 2026-04-05
- Context: GET /users/:id returned 500 for non-existent users
  because findById returns null and code called .toJSON() on it.
- Decision: All findById callers must check for null before use.
  Added null check in user-handler.ts.
- Root Cause: Missing defensive check on nullable return value.
- Consequences: All future handlers must check for null.
  Added to code-review checklist.
```

**Status output:**
```
🔧 ACTIVE: Bug Fix — Phase 5/5: RECORD
   → ADR-0043 recorded in architecture-decisions.md
   → Added to code-review checklist
```

---

## Done

```bash
$ rtk git commit -m "fix: return 404 for non-existent users instead of 500

Added null check in user-handler.ts before calling .toJSON().
Added regression test. Recorded ADR-0043."

$ bd close "bd-a1b2c3" "Fixed: 500 → 404 for non-existent users"
```

**Status output:**
```
✅ Session Summary — 2026-04-05 15:10 UTC
   → Bug fixed: 500 → 404 for non-existent users
   → Root cause: Missing null check
   → Tests: 13/13 pass (1 new regression test)
   → ADR: ADR-0043 recorded
   → Tokens saved (rtk): ~800
```

---

## Anti-Patterns — What the Agent Did NOT Do

| Anti-Pattern | What would've happened | What the agent did instead |
|--------------|----------------------|---------------------------|
| Fix without reproducing | Fixed randomly, didn't know the cause | Wrote test, confirmed bug |
| Refactor during fix | Rewrote the entire handler | 2 lines — fix only |
| No verification | Said "should work" | Ran 13 tests |
| No documentation | Bug would return | ADR + regression test |
| Suppress the error | Hid 500 with empty response | Returned correct 404 |

---

## Tools in This Example

| Tool | Role |
|------|------|
| **TDD Rules** | Regression test written BEFORE the fix |
| **rtk** | Compressed test output 60→6 lines |
| **Bug-Fix Workflow** | 5 phases: Repro → Identify → Fix → Verify → Record |
| **Code Review** | Checklist before commit |
| **Status Reporting** | Every phase was visible |
