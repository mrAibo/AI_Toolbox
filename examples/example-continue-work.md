# Example: Resuming Work After a Break — Session Handover

How AI Toolbox restores context after a break (overnight, weekend, vacation).

---

## The Scenario

You worked on a feature yesterday. Closed the session. This morning — you continue.

**Without AI Toolbox:** 20-30 minutes re-reading code, restoring context, remembering what you did.

**With AI Toolbox:** 30 seconds — the agent remembers everything.

---

## What Happened Yesterday

You were working on the `POST /users` endpoint. The session ended at the IMPLEMENT step (TDD GREEN phase).

`hook-stop.sh` automatically wrote:

```markdown
## Session Handover — 2026-04-04 18:30 UTC

### Completed
- POST /users handler written (Fastify)
- 3 tests added: happy path, duplicate email, missing name
- All 16 tests pass

### In Progress
- Step 5/9: IMPLEMENT (TDD GREEN phase)
- Next: Write validation middleware for request body

### Next Step
- Add request validation middleware (Joi schema)
- Then: integration test with real DB

### Notes
- Using Joi for validation (decided over Zod — simpler for this case)
- Database tests use in-memory SQLite — slow but works
```

`active-session.md` was also updated:

```markdown
# Active Session — 2026-04-04 18:30 UTC

## Current Step
- **Workflow:** Unified Workflow (Step 5/9 — IMPLEMENT)
- **Task:** POST /users endpoint (bd-d4e5f6)
- **Phase:** GREEN — Implementation written, need validation

## Progress
- Steps completed: 4/9
- Subtasks done: 2/4
- Tokens saved (rtk): ~1800
```

---

## This Morning: Boot Sequence

You open your terminal and launch the AI agent.

### Step 1: Environmental Check

```
🔍 Checking: .agent/ folder exists ✅
🔍 Checking: rtk binary available ✅
🔍 Checking: bd binary available ✅
```

### Step 2: Context Recovery

```
📖 Reading: .agent/memory/architecture-decisions.md
   → 43 ADRs loaded (latest: ADR-0043 — Null check for findById)

📖 Reading: .agent/memory/integration-contracts.md
   → 2 API contracts loaded (Users API, Auth API)
```

### Step 3: Work-in-Progress Check

```
📖 Reading: .agent/memory/session-handover.md
   → "POST /users handler written, 3 tests added"
   → "Next: Write validation middleware for request body"
   → "Using Joi for validation (decided over Zod)"
```

### Step 4: Task Synchronization

```
🔄 Running: .agent/scripts/sync-task.sh
   → Beads: bd-d4e5f6 "POST /users endpoint" [in_progress]
   → Exported to: .agent/memory/current-task.md
```

### Step 5: Summarization

```
✅ Context Restored — 2026-04-05 09:00 UTC

### Yesterday's Progress
- Task: POST /users endpoint (bd-d4e5f6)
- Completed: Handler written, 3 tests added
- Stopped at: Step 5/9 — IMPLEMENT (GREEN phase)
- Next: Request validation middleware (Joi)

### Architecture Context
- 43 ADRs available
- Repository pattern for data access
- Fastify for HTTP layer
- Joi for validation

### Ready to continue? [y/n]
```

---

## Continuing the Work

You press `y`. The agent picks up exactly where it left off:

```
🔧 ACTIVE: Resuming Step 5/9 — IMPLEMENT
   → Task: POST /users endpoint (bd-d4e5f6)
   → Phase: Adding request validation middleware

📋 Applying: .agent/rules/tdd-rules.md — RED phase
🔧 Writing failing test: POST /users without name returns 400
```

```typescript
// validation.test.ts
it("should return 400 if name is missing", async () => {
  const response = await request(app)
    .post("/users")
    .send({ email: "test@example.com" });
  expect(response.status).toBe(400);
  expect(response.body.error).toContain("name is required");
});
```

```bash
$ rtk test -- validation.test.ts
❌ FAIL validation.test.ts
  POST /users › should return 400 if name is missing
    Expected: 400
    Received: 201 (created user with missing name)
```

**Status output:**
```
🔧 RED confirmed — now writing Joi validation middleware
```

---

## What If You Missed Several Days?

The agent checks `session-handover.md` and `architecture-decisions.md` for changes:

```
📖 Reading: .agent/memory/session-handover.md
   → Last session: 2026-04-01 (3 days ago)
   → "POST /users handler written, stopped at validation"

📖 Reading: .agent/memory/architecture-decisions.md
   → 2 new ADRs since last session:
     ADR-0044: Switched from Joi to Zod (simpler TypeScript integration)
     ADR-0045: Added rate limiting to all POST endpoints

⚠️ DECISION CHANGE DETECTED:
   → ADR-0044: Validation library changed from Joi to Zod
   → Previous session used Joi — should I switch to Zod? [y/n]
```

The agent **doesn't blindly continue** — it checks that context hasn't changed.

---

## What If the Task Was Already Closed?

```
📖 Reading: .agent/memory/session-handover.md
   → "POST /users completed yesterday by another session"

🔄 Running: sync-task.sh
   → Beads: bd-d4e5f6 [closed] — "POST /users complete"
   → Next ready: bd-f6g7h8 "Add rate limiting to POST /users" [high]

✅ Task bd-d4e5f6 is closed. Picking up next task:
   → bd-f6g7h8: Add rate limiting to POST /users

Ready to start? [y/n]
```

---

## Comparison

| Scenario | Without AI Toolbox | With AI Toolbox |
|----------|-------------------|-----------------|
| Overnight break | 20-30 min to restore context | 30 seconds |
| Missed 3 days | 1+ hour re-reading | 2 minutes (check ADRs) |
| Task closed by someone else | Discovered after writing code | Sees immediately, picks next task |
| Context changed | Would code against old context | Checks ADRs before starting |

---

## How It Works Technically

| File | Role | Updated By |
|------|------|-----------|
| `session-handover.md` | What was done, where we stopped | hook-stop.sh/ps1 |
| `active-session.md` | Live session status | Agent at each step |
| `current-task.md` | Current task from Beads | sync-task.sh/ps1 |
| `architecture-decisions.md` | Architectural decisions | Agent when decisions are made |
| `integration-contracts.md` | API contracts | Agent when API changes |

The Boot Sequence reads these files **in this order** at every session start.
