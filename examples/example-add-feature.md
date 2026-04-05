# Example: Adding a New Feature — Unified Workflow

Full cycle of adding a feature through the 9-step Unified Workflow.

---

## The Task

> "Add a GET /users/:id endpoint that returns user data from the database."

---

## Step 1: TASK (Beads)

```bash
$ bd create "GET /users/:id endpoint" -p high
Created task bd-a1b2c3

$ bd ready
bd-a1b2c3: GET /users/:id endpoint [high]
```

**What happened:** Beads stored the task in its graph. `sync-task.sh` auto-synced it to `.agent/memory/current-task.md` at session start.

**Status output:**
```
🔧 ACTIVE: Entering Step 1/9 — TASK
   → Task: GET /users/:id endpoint (bd-a1b2c3)
   → Priority: high
```

---

## Step 2: BRAINSTORM (Superpowers → AGENT.md §7)

The agent analyzes the request:

```
## Approaches
1. Direct DB query in handler (simple, but tightly coupled)
2. Repository pattern (testable, matches project patterns)
3. Service layer (overkill for a single endpoint)

## Decision: Repository pattern
- Matches existing project architecture
- Testable without a real DB
- Recorded in architecture-decisions.md
```

**Status output:**
```
🔧 ACTIVE: Entering Step 2/9 — BRAINSTORM
   → Skill: AGENT.md §7 (Brainstorming rules)
   → Decision: Repository pattern
```

---

## Step 3: PLAN (Superpowers → AGENT.md §3)

```
## Subtasks
1. Define UserRepository interface (2 min)
2. Implement in-memory repository for tests (3 min)
3. Write handler with GET /users/:id (3 min)
4. Write integration test (2 min)
5. Wire up router (1 min)
```

**Status output:**
```
🔧 ACTIVE: Entering Step 3/9 — PLAN
   → Subtasks: 5 (2-5 min each)
   → Stored in: .agent/memory/current-task.md
```

---

## Step 4: ISOLATE (optional)

Not needed for this task — working in the current branch.

---

## Step 5: IMPLEMENT (TDD → .agent/rules/tdd-rules.md)

### Subtask 1: UserRepository Interface

**RED:** Write a failing test first.

```typescript
// user-repository.test.ts
describe("UserRepository", () => {
  it("should find user by id", async () => {
    const repo = new InMemoryUserRepository();
    const user = await repo.findById("user-1");
    expect(user).toBeNull();
  });
});
```

**VERIFY RED:**

```bash
$ rtk test
❌ FAIL user-repository.test.ts
  UserRepository › should find user by id
    InMemoryUserRepository is not defined
```

rtk compressed output: 50 lines → 8 lines.

**Status output:**
```
📋 Applying: .agent/rules/tdd-rules.md — RED phase
🔧 Using: rtk test — compressed 50 lines → 8 lines (84% saved)
```

**GREEN:** Write minimal code to pass.

```typescript
// user-repository.ts
export class InMemoryUserRepository {
  async findById(id: string) { return null; }
}
```

**VERIFY GREEN:**

```bash
$ rtk test
✅ PASS (1 test, 12ms)
```

**COMMIT:**

```bash
$ rtk git commit -m "feat: define UserRepository interface with in-memory impl"
```

*Steps 1-6 repeat for each subtask.*

---

## Step 6: REVIEW (.agent/workflows/code-review.md)

```
## Changes
- user-repository.ts: Interface + in-memory implementation
- user-handler.ts: GET /users/:id handler
- router.ts: Wired up new endpoint
- user-repository.test.ts: 4 tests (happy path + error cases)

## Checklist
✅ All tests pass (rtk test — exit code 0)
✅ No lint errors (rtk lint — exit code 0)
✅ No debug statements left
✅ Changes match original plan
✅ Edge cases handled (user not found, invalid ID)
```

**Status output:**
```
🔧 ACTIVE: Entering Step 6/9 — REVIEW
   → Workflow: .agent/workflows/code-review.md
   → Checks: 5/5 passed
```

---

## Step 7: VERIFY (Superpowers → testing-rules.md)

```bash
$ rtk test
✅ PASS (12 tests, 45ms)

$ rtk lint
✅ No issues
```

**Status output:**
```
🔧 ACTIVE: Entering Step 7/9 — VERIFY
   → rtk test: 12 tests pass
   → rtk lint: 0 issues
```

---

## Step 8: FINISH (.agent/workflows/branch-finish.md)

Session handover updated:

```markdown
## Completed this session
- GET /users/:id endpoint with repository pattern
- 4 files changed, 12 tests added
- All tests pass, no lint errors
```

**Status output:**
```
🔧 ACTIVE: Entering Step 8/9 — FINISH
   → session-handover.md updated
   → Ready for merge
```

---

## Step 9: CLOSE (Beads)

```bash
$ bd close "bd-a1b2c3" "Completed: GET /users/:id endpoint with repository pattern"
Task bd-a1b2c3 closed.

$ bd ready
bd-d4e5f6: Add POST /users endpoint [high]
```

**Status output:**
```
✅ Session Summary — 2026-04-05 14:32 UTC
   → Steps completed: 9/9
   → Subtasks done: 5/5
   → Tokens saved (rtk): ~4000
   → Next task: bd-d4e5f6 (POST /users)
```

---

## Tool Activity Summary

| Tool | When Active | What It Did |
|------|-------------|-------------|
| **Beads** | Steps 1,9 | Stored task, tracked progress, provided next task |
| **Superpowers** | Steps 2,3,6,7 | Brainstorming, Planning, Review, Verification |
| **TDD Rules** | Step 5 | Enforced RED-GREEN-REFACTOR for each subtask |
| **rtk** | Every test/build | Compressed output by 60-90% (saved ~4000 tokens) |
| **MCP context7** | On demand | Provided Express.js routing docs when asked |
| **Templates** | Not needed | Existing skills were sufficient |
| **Hooks** | Auto | Pre-command blocked unsafe commands, stop-hook ran bd prime |

**Total time:** ~20 minutes
**Tokens saved by rtk:** ~4000
**Manual orchestration:** None — all tools worked together automatically.
