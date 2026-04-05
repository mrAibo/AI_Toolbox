# Пример: Возобновление работы после перерыва — Session Handover

Как AI Toolbox восстанавливает контекст после перерыва (ночь, выходные, отпуск).

---

## Сценарий

Вы работали вчера над фичей. Закрыли сессию. Сегодня утром — продолжаете.

**Без AI Toolbox:** 20-30 минут на перечитывание кода, восстановление контекста, вспоминание что делали.

**С AI Toolbox:** 30 секунд — агент всё помнит.

---

## Что произошло вчера

Вы работали над `POST /users` endpoint. Сессия закончилась на шаге IMPLEMENT (TDD GREEN phase).

`hook-stop.sh` автоматически записал:

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

`active-session.md` также обновлён:

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

## Сегодня утром: Boot Sequence

Вы открываете терминал и запускаете AI-агент.

### Шаг 1: Environmental Check

```
🔍 Checking: .agent/ folder exists ✅
🔍 Checking: rtk binary available ✅
🔍 Checking: bd binary available ✅
```

### Шаг 2: Context Recovery

```
📖 Reading: .agent/memory/architecture-decisions.md
   → 43 ADRs loaded (latest: ADR-0043 — Null check for findById)

📖 Reading: .agent/memory/integration-contracts.md
   → 2 API contracts loaded (Users API, Auth API)
```

### Шаг 3: Work-in-Progress Check

```
📖 Reading: .agent/memory/session-handover.md
   → "POST /users handler written, 3 tests added"
   → "Next: Write validation middleware for request body"
   → "Using Joi for validation (decided over Zod)"
```

### Шаг 4: Task Synchronization

```
🔄 Running: .agent/scripts/sync-task.sh
   → Beads: bd-d4e5f6 "POST /users endpoint" [in_progress]
   → Exported to: .agent/memory/current-task.md
```

### Шаг 5: Summarization

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

## Продолжение работы

Вы нажимаете `y`. Агент продолжает ровно с того места, где остановился:

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

**Статус:**
```
🔧 RED confirmed — now writing Joi validation middleware
```

---

## Что если вы пропустили несколько дней?

Агент проверяет `session-handover.md` и `architecture-decisions.md` на изменения:

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

Агент **не продолжает слепо** — он проверяет что контекст не изменился.

---

## Что если задача уже закрыта?

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

## Сравнение

| Сценарий | Без AI Toolbox | С AI Toolbox |
|----------|---------------|-------------|
| Перерыв на ночь | 20-30 мин на восстановление | 30 секунд |
| Пропущено 3 дня | 1+ час на перечитывание | 2 минуты (проверка ADRs) |
| Задача закрыта другим | Обнаружил бы после написания кода | Сразу видит, берёт следующую |
| Контекст изменился | Писал бы по старому контексту | Проверил бы ADRs перед стартом |

---

## Как это работает технически

| Файл | Роль | Обновляется |
|------|------|-------------|
| `session-handover.md` | Что сделали, где остановились | hook-stop.sh/ps1 |
| `active-session.md` | Live-статус сессии | Агент при каждом шаге |
| `current-task.md` | Текущая задача из Beads | sync-task.sh/ps1 |
| `architecture-decisions.md` | Архитектурные решения | Агент при новых решениях |
| `integration-contracts.md` | API контракты | Агент при изменениях API |

Boot Sequence читает их **в этом порядке** при каждом старте.
