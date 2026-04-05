# Пример: Безопасный рефакторинг — Verification Before Completion

Как AI Toolbox рефакторит код, не ломая существующую функциональность.

---

## Задача

> "Перепиши user-handler.ts с Express на Fastify. Все тесты должны оставаться зелёными."

---

## Pre-Check: Фиксируем текущее состояние

Перед рефакторингом агент фиксирует baseline:

```bash
$ rtk test
✅ PASS (13 tests, 48ms)

$ rtk lint
✅ No issues

$ rtk git diff HEAD
# clean — no uncommitted changes
```

**Статус:**
```
🔧 ACTIVE: Refactoring user-handler.ts (Express → Fastify)
   → Baseline: 13 tests pass, 0 lint issues
   → Goal: Same behavior, different framework
```

---

## Шаг 1: Characterization Tests

Агент пишет тесты, которые фиксируют текущее поведение (даже если их нет):

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

Эти тесты — safety net для рефакторинга.

**Статус:**
```
📋 Applying: .agent/rules/tdd-rules.md — characterization tests
🔧 Added 4 contract tests as safety net for refactoring
```

---

## Шаг 2: Рефакторинг — Small Steps

Агент меняет по одному файлу за раз, проверяя тесты после каждого шага.

### Шаг 2a: Установка Fastify

```bash
$ rtk npm install fastify @fastify/cors
```

### Шаг 2b: Новый handler на Fastify

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

**Проверка после каждого шага:**

```bash
$ rtk test
✅ PASS (17 tests, 52ms)
   → 13 original tests: pass
   → 4 contract tests: pass
```

**Статус:**
```
🔧 ACTIVE: Refactoring — Step 2b: Fastify handler written
   → Tests: 17/17 pass (no regressions)
```

---

## Шаг 3: Параллельный запуск

Агент подключает новый handler рядом со старым:

```typescript
// router.ts
// Old Express handler (temporary — will remove after verification)
// app.use("/users", expressUserHandler);

// New Fastify handler
await fastify.register(registerUserHandler);
```

**Проверка:**

```bash
$ rtk test
✅ PASS (17 tests, 52ms)
```

---

## Шаг 4: Удаление старого кода

После подтверждения что всё работает, агент удаляет Express handler:

```bash
$ rtk npm uninstall express
$ rm user-handler-express.ts
```

**Финальная проверка:**

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

## Шаг 5: Code Review

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

## Финал

```bash
$ rtk git commit -m "refactor: migrate user-handler from Express to Fastify

- Added 4 contract tests as safety net
- Replaced Express handler with Fastify equivalent
- Removed Express dependency from user module
- All 17 tests pass, no behavior changes"

$ bd close "bd-c7d8e9" "Refactored: Express → Fastify, 17 tests green"
```

**Статус:**
```
✅ Session Summary — 2026-04-05 16:45 UTC
   → Refactoring complete: Express → Fastify
   → Tests: 17/17 pass (4 new contract tests added)
   → Lines: -41 removed, +25 added (net -16)
   → Tokens saved (rtk): ~3200
```

---

## Анти-паттерны — что агент НЕ делал

| Анти-паттерн | Что было бы | Что сделал агент |
|--------------|-------------|-----------------|
| Рефакторинг без тестов | Сломал бы behaviour unnoticed | 4 contract tests BEFORE refactoring |
| Большой commit | 45 files, невозможно ревью | 4 files, один commit |
| "Должно работать" | Без проверки | 17 тестов после каждого шага |
| Частичное удаление | Express остался бы в dependencies | `npm uninstall express` |
| Без contract tests | API changes unnoticed | 4 tests фиксируют API contract |

---

## Ключевой принцип

> **Рефакторинг = изменение структуры без изменения поведения.**
> Тесты — единственный способ доказать что поведение не изменилось.

AI Toolbox обеспечивает это через:
1. **TDD Rules** — characterization tests перед рефакторингом
2. **Code Review Checklist** — проверка что поведение сохранено
3. **rtk** — каждый прогон тестов виден без token flooding
4. **Status Reporting** — видно прогресс на каждом шаге
