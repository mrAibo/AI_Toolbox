# Example: Safe Refactoring — Verification Before Completion

How AI Toolbox refactors code without breaking existing functionality.

---

## The Task

> "Rewrite user-handler.ts from Express to Fastify. All tests must stay green."

---

## Pre-Check: Capture the Baseline

Before refactoring, the agent captures the current state:

```bash
$ rtk test
✅ PASS (13 tests, 48ms)

$ rtk lint
✅ No issues

$ rtk git diff HEAD
# clean — no uncommitted changes
```

**Status output:**
```
🔧 ACTIVE: Refactoring user-handler.ts (Express → Fastify)
   → Baseline: 13 tests pass, 0 lint issues
   → Goal: Same behavior, different framework
```

---

## Step 1: Characterization Tests

The agent writes tests that capture current behavior (even if none exist yet):

```typescript
// user-handler.contract.test.ts
describe("User Handler Contract", () => {
  it("returns 200 with user data for valid ID", async () => {
    const response = await request(app).get("/users/valid-id");
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty("id");
    expect(response.body).toHaveProperty("name");
  });

  it("returns 404 for non-existent user", async () => {
    const response = await request(app).get("/users/nonexistent");
    expect(response.status).toBe(404);
  });

  it("returns 400 for invalid UUID", async () => {
    const response = await request(app).get("/users/not-a-uuid");
    expect(response.status).toBe(400);
  });

  it("includes CORS headers on error", async () => {
    const response = await request(app).get("/users/valid-id")
      .set("Origin", "http://example.com");
    expect(response.headers).toHaveProperty("access-control-allow-origin");
  });
});
```

```bash
$ rtk test -- user-handler.contract.test.ts
✅ PASS (4 new contract tests)
```

These tests are the safety net for refactoring.

**Status output:**
```
📋 Applying: .agent/rules/tdd-rules.md — characterization tests
🔧 Added 4 contract tests as safety net for refactoring
```

---

## Step 2: Refactoring — Small Steps

The agent changes one thing at a time, checking tests after each step.

### Step 2a: Install Fastify

```bash
$ rtk npm install fastify @fastify/cors
```

### Step 2b: New Fastify Handler

```typescript
// user-handler-fastify.ts
import { FastifyInstance } from "fastify";

export async function registerUserHandler(fastify: FastifyInstance) {
  fastify.get("/users/:id", async (request, reply) => {
    const { id } = request.params as { id: string };

    if (!isValidUUID(id)) {
      return reply.code(400).send({ error: "Invalid UUID format" });
    }

    const user = await userRepo.findById(id);
    if (!user) {
      return reply.code(404).send({ error: "User not found" });
    }

    return user.toJSON();
  });
}
```

**Check after each step:**

```bash
$ rtk test
✅ PASS (17 tests, 52ms)
   → 13 original tests: pass
   → 4 contract tests: pass
```

**Status output:**
```
🔧 ACTIVE: Refactoring — Step 2b: Fastify handler written
   → Tests: 17/17 pass (no regressions)
```

---

## Step 3: Parallel Run

The agent wires the new handler alongside the old one:

```typescript
// router.ts
// Old Express handler (temporary — will remove after verification)
// app.use("/users", expressUserHandler);

// New Fastify handler
await fastify.register(registerUserHandler);
```

**Check:**

```bash
$ rtk test
✅ PASS (17 tests, 52ms)
```

---

## Step 4: Remove Old Code

After confirming everything works, the agent removes the Express handler:

```bash
$ rtk npm uninstall express
$ rm user-handler-express.ts
```

**Final check:**

```bash
$ rtk test
✅ PASS (17 tests, 52ms)

$ rtk lint
✅ No issues

$ rtk git diff HEAD
 user-handler.ts          | 45 ++++++++---------------------
 user-handler.test.ts     | 12 ++++----
 router.ts                |  6 ++--
 package.json             |  3 +-
 4 files changed, 25 insertions(+), 41 deletions(-)
```

---

## Step 5: Code Review

```
## Changes
- Replaced Express handler with Fastify equivalent
- 4 files changed, 25 insertions, 41 deletions
- All 17 tests pass (13 original + 4 contract tests)

## Checklist
✅ All tests pass (rtk test — exit code 0)
✅ No lint errors (rtk lint — exit code 0)
✅ No debug statements left
✅ Behavior unchanged (contract tests verify)
✅ Old code fully removed

## Risks
- Fastify error format slightly different — checked, consumers unaffected
- CORS headers preserved — verified by contract test
```

---

## Done

```bash
$ rtk git commit -m "refactor: migrate user-handler from Express to Fastify

- Added 4 contract tests as safety net
- Replaced Express handler with Fastify equivalent
- Removed Express dependency from user module
- All 17 tests pass, no behavior changes"

$ bd close "bd-c7d8e9" "Refactored: Express → Fastify, 17 tests green"
```

**Status output:**
```
✅ Session Summary — 2026-04-05 16:45 UTC
   → Refactoring complete: Express → Fastify
   → Tests: 17/17 pass (4 new contract tests added)
   → Lines: -41 removed, +25 added (net -16)
   → Tokens saved (rtk): ~3200
```

---

## Anti-Patterns — What the Agent Did NOT Do

| Anti-Pattern | What would've happened | What the agent did instead |
|--------------|----------------------|---------------------------|
| Refactor without tests | Broke behaviour unnoticed | 4 contract tests BEFORE refactoring |
| Big-bang commit | 45 files, impossible to review | 4 files, one commit |
| "Should work" | Without checking | 17 tests after every step |
| Partial removal | Express stayed in dependencies | `npm uninstall express` |
| No contract tests | API changes unnoticed | 4 tests lock the API contract |

---

## Key Principle

> **Refactoring = changing structure without changing behavior.**
> Tests are the only way to prove behavior didn't change.

AI Toolbox enforces this through:
1. **TDD Rules** — characterization tests before refactoring
2. **Code Review Checklist** — verification that behavior is preserved
3. **rtk** — every test run is visible without token flooding
4. **Status Reporting** — progress is visible at every step
