# Example: Ensemble Walkthrough — Building a REST API Endpoint

This example shows how all tools work together in a real development session.

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

**What happened:** Beads stored the task in its graph database. The `sync-task.sh` script auto-synced this to `.agent/memory/current-task.md` at session start.

---

## Step 2: BRAINSTORM (Superpowers → AGENT.md §7)

The AI analyzes the request:

```
## Approaches
1. Direct DB query in handler (simple, but tightly coupled)
2. Repository pattern (testable, follows existing project patterns)
3. Service layer (overkill for a single endpoint)

## Decision: Repository pattern
- Matches existing project architecture
- Testable without a real DB
- Recorded in architecture-decisions.md
```

**What happened:** Superpowers' brainstorming skill guided the analysis. No code written yet.

---

## Step 3: PLAN (Superpowers → AGENT.md §3)

```
## Subtasks
1. Define User repository interface (2 min)
2. Implement in-memory repository for tests (3 min)
3. Write handler with GET /users/:id (3 min)
4. Write integration test (2 min)
5. Wire up router (1 min)
```

**What happened:** Work broken into 2-5 minute tasks. Each has clear input/output/verification.

---

## Step 5: IMPLEMENT (TDD → .agent/rules/tdd-rules.md)

*(Steps 1-4 covered earlier: TASK, BRAINSTORM, PLAN, ISOLATE skipped — not needed for this example)*

### Subtask 1: Define User repository interface

**RED:** Write failing test first

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

rtk compressed the output: 50 lines → 8 lines.

**GREEN:** Write minimal code

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
✅ Edge cases handled (user not found, invalid ID format)
```

---

## Step 7: VERIFY (Superpowers → .agent/rules/testing-rules.md)

```bash
$ rtk test
✅ PASS (12 tests, 45ms)

$ rtk lint
✅ No issues
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

---

## Step 9: CLOSE (Beads)

```bash
$ bd close "bd-a1b2c3" "Completed: GET /users/:id endpoint with repository pattern"
Task bd-a1b2c3 closed.

$ bd ready
bd-d4e5f6: Add POST /users endpoint [high]
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
