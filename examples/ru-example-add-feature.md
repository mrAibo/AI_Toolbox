# Пример: Добавление новой функции — Unified Workflow

Полный цикл добавления функции через 9-шаговый Unified Workflow.

---

## Задача

> "Добавь endpoint GET /users/:id, который возвращает данные пользователя из базы."

---

## Шаг 1: TASK (Beads)

```bash
$ bd create "GET /users/:id endpoint" -p high
Created task bd-a1b2c3

$ bd ready
bd-a1b2c3: GET /users/:id endpoint [high]
```

**Что произошло:** Beads сохранил задачу в граф. `sync-task.sh` автоматически синхронизировал её в `.agent/memory/current-task.md` при старте сессии.

**Статус:**
```
🔧 ACTIVE: Entering Step 1/9 — TASK
   → Task: GET /users/:id endpoint (bd-a1b2c3)
   → Priority: high
```

---

## Шаг 2: BRAINSTORM (Superpowers → AGENT.md §7)

Агент аналирует запрос:

```
## Подходы
1. Прямой DB-запрос в handler (просто, но tight coupling)
2. Repository pattern (тестируемо, соответствует проекту)
3. Service layer (overkill для одного endpoint)

## Решение: Repository pattern
- Совпадает с архитектурой проекта
- Тестируемо без реальной БД
- Записано в architecture-decisions.md
```

**Статус:**
```
🔧 ACTIVE: Entering Step 2/9 — BRAINSTORM
   → Skill: AGENT.md §7 (Brainstorming rules)
   → Decision: Repository pattern
```

---

## Шаг 3: PLAN (Superpowers → AGENT.md §3)

```
## Подзадачи
1. Определить интерфейс UserRepository (2 мин)
2. Реализовать in-memory репозиторий для тестов (3 мин)
3. Написать handler с GET /users/:id (3 мин)
4. Написать интеграционный тест (2 мин)
5. Подключить роутер (1 мин)
```

**Статус:**
```
🔧 ACTIVE: Entering Step 3/9 — PLAN
   → Subtasks: 5 (2-5 min each)
   → Stored in: .agent/memory/current-task.md
```

---

## Шаг 4: ISOLATE (опционально)

Для этой задачи не нужен — работаем в текущей ветке.

---

## Шаг 5: IMPLEMENT (TDD → .agent/rules/tdd-rules.md)

### Подзадача 1: Интерфейс UserRepository

**RED:** Пишем падающий тест первым.

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

rtk сжал вывод: 50 строк → 8 строк.

**Статус:**
```
📋 Applying: .agent/rules/tdd-rules.md — RED phase
🔧 Using: rtk test — compressed 50 lines → 8 lines (84% saved)
```

**GREEN:** Минимальный код для прохождения теста.

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

*Шаги 1-6 повторяются для каждой подзадачи.*

---

## Шаг 6: REVIEW (.agent/workflows/code-review.md)

```
## Changes
- user-repository.ts: Интерфейс + in-memory реализация
- user-handler.ts: GET /users/:id handler
- router.ts: Подключен новый endpoint
- user-repository.test.ts: 4 теста (happy path + ошибки)

## Checklist
✅ Все тесты проходят (rtk test — exit code 0)
✅ Нет lint-ошибок (rtk lint — exit code 0)
✅ Нет debug-вызовов
✅ Изменения соответствуют плану
✅ Edge cases обработаны (user not found, invalid ID)
```

**Статус:**
```
🔧 ACTIVE: Entering Step 6/9 — REVIEW
   → Workflow: .agent/workflows/code-review.md
   → Checks: 5/5 passed
```

---

## Шаг 7: VERIFY (Superpowers → testing-rules.md)

```bash
$ rtk test
✅ PASS (12 tests, 45ms)

$ rtk lint
✅ No issues
```

**Статус:**
```
🔧 ACTIVE: Entering Step 7/9 — VERIFY
   → rtk test: 12 tests pass
   → rtk lint: 0 issues
```

---

## Шаг 8: FINISH (.agent/workflows/branch-finish.md)

Session handover обновлён:

```markdown
## Completed this session
- GET /users/:id endpoint с repository pattern
- 4 файла изменено, 12 тестов добавлено
- Все тесты проходят, lint-ошибок нет
```

**Статус:**
```
🔧 ACTIVE: Entering Step 8/9 — FINISH
   → session-handover.md updated
   → Ready for merge
```

---

## Шаг 9: CLOSE (Beads)

```bash
$ bd close "bd-a1b2c3" "Completed: GET /users/:id endpoint with repository pattern"
Task bd-a1b2c3 closed.

$ bd ready
bd-d4e5f6: Add POST /users endpoint [high]
```

**Статус:**
```
✅ Session Summary — 2026-04-05 14:32 UTC
   → Steps completed: 9/9
   → Subtasks done: 5/5
   → Tokens saved (rtk): ~4000
   → Next task: bd-d4e5f6 (POST /users)
```

---

## Сводка активности инструментов

| Инструмент | Когда активен | Что сделал |
|------------|---------------|------------|
| **Beads** | Шаги 1,9 | Создал задачу, tracked прогресс, дал следующую |
| **Superpowers** | Шаги 2,3,6,7 | Brainstorming, Planning, Review, Verification |
| **TDD Rules** | Шаг 5 | Принудил RED-GREEN-REFACTOR для каждой подзадачи |
| **rtk** | Каждый test/build | Сжал вывод на 60-90% (сэкономил ~4000 токенов) |
| **MCP context7** | По запросу | Дал документацию Express.js когда спросили |
| **Templates** | Не нужны | Существующих skills хватило |
| **Hooks** | Автоматически | Pre-command блокировал unsafe команды, stop-hook запустил bd prime |

**Итого время:** ~20 минут
**Токенов сэкономлено rtk:** ~4000
**Ручная оркестрация:** Ноль — все инструменты работали вместе автоматически.
