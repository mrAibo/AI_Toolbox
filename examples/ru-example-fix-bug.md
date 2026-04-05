# Пример: Исправление бага — Structured Debugging Workflow

Как AI Toolbox находит и исправляет баги систематически, а не наугад.

---

## Задача

> "Endpoint GET /users/:id иногда возвращает 500 вместо 404 для несуществующих пользователей."

---

## Фаза 1: REPRODUCE (Bug-Fix Workflow §1)

**Цель:** Подтвердить баг и понять триггер.

Агент пишет тест для воспроизведения:

```typescript
// bug-repro.test.ts
it("should return 404 for non-existent user, not 500", async () => {
  const response = await request(app).get("/users/nonexistent-id");
  expect(response.status).toBe(404); // Currently returns 500
});
```

Запускает:

```bash
$ rtk test -- bug-repro.test.ts
❌ FAIL bug-repro.test.ts
  GET /users/:id › should return 404 for non-existent user
    Expected: 404
    Received: 500
```

**Статус:**
```
🔧 ACTIVE: Bug Fix — Phase 1/5: REPRODUCE
   → Bug: GET /users/:id returns 500 instead of 404
   → Repro: Test case with nonexistent ID
   → Actual: 500 Internal Server Error
   → Expected: 404 Not Found
```

---

## Фаза 2: IDENTIFY (Bug-Fix Workflow §2)

**Цель:** Найти корень проблемы.

Агент идёт backwards от ошибки:

```
## Трассировка
1. 500 приходит из Express error handler
2. Handler: user-handler.ts line 23
3. Там: const user = await repo.findById(id)
4. Если user === null → код падает при user.toJSON()

## Корень
findById возвращает null для несуществующих ID.
Код не проверяет null перед вызовом .toJSON().
```

Проверяет `git log`:

```bash
$ rtk git log --oneline -5 -- user-handler.ts
a1b2c3 feat: add GET /users/:id endpoint
```

Это не регрессия — баг был с момента создания endpoint.

**Статус:**
```
🔧 ACTIVE: Bug Fix — Phase 2/5: IDENTIFY
   → Root Cause: Missing null check before .toJSON()
   → Affected: user-handler.ts:23
   → Risk: Low — one-line fix
```

---

## Фаза 3: FIX (Bug-Fix Workflow §3)

**Цель:** Минимальное исправление.

```typescript
// BEFORE (line 23)
const user = await repo.findById(id);
res.json(user.toJSON()); // 💥 crashes if user is null

// AFTER
const user = await repo.findById(id);
if (!user) return res.status(404).json({ error: "User not found" });
res.json(user.toJSON());
```

Только 2 строки добавлены. Никакого рефакторинга.

**Статус:**
```
🔧 ACTIVE: Bug Fix — Phase 3/5: FIX
   → Changed: 2 lines in user-handler.ts
   → No refactoring — minimal fix only
```

---

## Фаза 4: VERIFY (Bug-Fix Workflow §4)

**Цель:** Подтвердить исправление, проверить регрессии.

```bash
$ rtk test
✅ PASS (13 tests, 48ms)
   → bug-repro.test.ts: NOW PASSES
   → All 12 existing tests: still pass

$ rtk lint
✅ No issues
```

Агент также проверяет edge cases:

```typescript
it("should return 400 for invalid UUID format", async () => {
  const response = await request(app).get("/users/not-a-uuid");
  expect(response.status).toBe(400);
});
```

**Статус:**
```
🔧 ACTIVE: Bug Fix — Phase 4/5: VERIFY
   → Repro test: NOW PASSES ✅
   → All 13 tests: pass
   → Lint: clean
   → Edge case (invalid UUID): handled
```

---

## Фаза 5: RECORD (Bug-Fix Workflow §5)

**Цель:** Задокументировать, чтобы баг не вернулся.

Агент записывает в `architecture-decisions.md`:

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

**Статус:**
```
🔧 ACTIVE: Bug Fix — Phase 5/5: RECORD
   → ADR-0043 recorded in architecture-decisions.md
   → Added to code-review checklist
```

---

## Готово

```bash
$ rtk git commit -m "fix: return 404 for non-existent users instead of 500

Added null check in user-handler.ts before calling .toJSON().
Added regression test. Recorded ADR-0043."

$ bd close "bd-a1b2c3" "Fixed: 500 → 404 for non-existent users"
```

**Статус:**
```
✅ Session Summary — 2026-04-05 15:10 UTC
   → Bug fixed: 500 → 404 for non-existent users
   → Root cause: Missing null check
   → Tests: 13/13 pass (1 new regression test)
   → ADR: ADR-0043 recorded
   → Tokens saved (rtk): ~800
```

---

## Анти-паттерны — что агент НЕ делал

| Анти-паттерн | Что было бы | Что сделал агент |
|--------------|-------------|-----------------|
| Fix без reproducing | Исправил бы случайно, не зная причины | Написал тест, подтвердил баг |
| Refactor во время fix | Переписал бы весь handler | 2 строки — только fix |
| Без verification | Сказал бы "должно работать" | Запустил 13 тестов |
| Без documentation | Баг вернулся бы | ADR + regression test |
| Suppress ошибки | Скрыл бы 500 пустым ответом | Вернул корректный 404 |

---

## Инструменты в этом примере

| Инструмент | Роль |
|------------|------|
| **TDD Rules** | Regression test написан ПЕРЕД фиксом |
| **rtk** | Сжал вывод тестов 60→6 строк |
| **Bug-Fix Workflow** | 5 фаз: Repro → Identify → Fix → Verify → Record |
| **Code Review** | Checklist перед коммитом |
| **Status Reporting** | Каждая фаза была видна |
