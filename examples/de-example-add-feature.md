# Beispiel: Neue Funktion hinzufügen — Unified Workflow

Vollständiger Zyklus zum Hinzufügen einer Funktion durch den 9-Schritte-Workflow.

---

## Die Aufgabe

> "Füge einen GET /users/:id Endpoint hinzu, der Benutzerdaten aus der Datenbank zurückgibt."

---

## Schritt 1: TASK (Beads)

```bash
$ bd create "GET /users/:id endpoint" -p high
Created task bd-a1b2c3

$ bd ready
bd-a1b2c3: GET /users/:id endpoint [high]
```

**Was passiert ist:** Beads hat die Aufgabe im Graph gespeichert. `sync-task.sh` hat sie automatisch in `.agent/memory/current-task.md` synchronisiert.

**Status-Ausgabe:**
```
🔧 ACTIVE: Entering Step 1/9 — TASK
   → Task: GET /users/:id endpoint (bd-a1b2c3)
   → Priority: high
```

---

## Schritt 2: BRAINSTORM (Superpowers → AGENT.md §7)

Der Agent analysiert die Anfrage:

```
## Ansätze
1. Direkte DB-Abfrage im Handler (einfach, aber eng gekoppelt)
2. Repository Pattern (testbar, entspricht Projektmustern)
3. Service Layer (Overkill für einen Endpoint)

## Entscheidung: Repository Pattern
- Entspricht der Projektarchitektur
- Testbar ohne echte DB
- Wird in architecture-decisions.md festgehalten
```

**Status-Ausgabe:**
```
🔧 ACTIVE: Entering Step 2/9 — BRAINSTORM
   → Skill: AGENT.md §7 (Brainstorming rules)
   → Decision: Repository pattern
```

---

## Schritt 3: PLAN (Superpowers → AGENT.md §3)

```
## Unteraufgaben
1. UserRepository Interface definieren (2 Min)
2. In-Memory Repository für Tests implementieren (3 Min)
3. Handler mit GET /users/:id schreiben (3 Min)
4. Integrationstest schreiben (2 Min)
5. Router verbinden (1 Min)
```

**Status-Ausgabe:**
```
🔧 ACTIVE: Entering Step 3/9 — PLAN
   → Subtasks: 5 (2-5 Min each)
   → Stored in: .agent/memory/current-task.md
```

---

## Schritt 4: ISOLATE (optional)

Für diese Aufgabe nicht nötig — wir arbeiten im aktuellen Branch.

---

## Schritt 5: IMPLEMENT (TDD → .agent/rules/tdd-rules.md)

### Unteraufgabe 1: UserRepository Interface

**RED:** Zuerst einen fehlschlagenden Test schreiben.

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

rtk hat die Ausgabe komprimiert: 50 Zeilen → 8 Zeilen.

**Status-Ausgabe:**
```
📋 Applying: .agent/rules/tdd-rules.md — RED phase
🔧 Using: rtk test — compressed 50 lines → 8 lines (84% saved)
```

**GREEN:** Minimaler Code zum Bestehen des Tests.

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

*Schritte 1-6 wiederholen sich für jede Unteraufgabe.*

---

## Schritt 6: REVIEW (.agent/workflows/code-review.md)

```
## Changes
- user-repository.ts: Interface + In-Memory Implementierung
- user-handler.ts: GET /users/:id Handler
- router.ts: Neuer Endpoint verbunden
- user-repository.test.ts: 4 Tests (Happy Path + Fehlerfälle)

## Checklist
✅ Alle Tests bestanden (rtk test — Exit Code 0)
✅ Keine Lint-Fehler (rtk lint — Exit Code 0)
✅ Keine Debug-Aufrufe
✅ Änderungen entsprechen dem Plan
✅ Edge Cases behandelt (User nicht gefunden, ungültige ID)
```

**Status-Ausgabe:**
```
🔧 ACTIVE: Entering Step 6/9 — REVIEW
   → Workflow: .agent/workflows/code-review.md
   → Checks: 5/5 passed
```

---

## Schritt 7: VERIFY (Superpowers → testing-rules.md)

```bash
$ rtk test
✅ PASS (12 tests, 45ms)

$ rtk lint
✅ No issues
```

**Status-Ausgabe:**
```
🔧 ACTIVE: Entering Step 7/9 — VERIFY
   → rtk test: 12 tests pass
   → rtk lint: 0 issues
```

---

## Schritt 8: FINISH (.agent/workflows/branch-finish.md)

Session Handover aktualisiert:

```markdown
## Completed this session
- GET /users/:id Endpoint mit Repository Pattern
- 4 Dateien geändert, 12 Tests hinzugefügt
- Alle Tests bestanden, keine Lint-Fehler
```

**Status-Ausgabe:**
```
🔧 ACTIVE: Entering Step 8/9 — FINISH
   → session-handover.md updated
   → Ready for merge
```

---

## Schritt 9: CLOSE (Beads)

```bash
$ bd close "bd-a1b2c3" "Completed: GET /users/:id endpoint with repository pattern"
Task bd-a1b2c3 closed.

$ bd ready
bd-d4e5f6: Add POST /users endpoint [high]
```

**Status-Ausgabe:**
```
✅ Session Summary — 2026-04-05 14:32 UTC
   → Steps completed: 9/9
   → Subtasks done: 5/5
   → Tokens saved (rtk): ~4000
   → Next task: bd-d4e5f6 (POST /users)
```

---

## Werkzeug-Aktivitätsübersicht

| Werkzeug | Wann aktiv | Was es tat |
|----------|------------|------------|
| **Beads** | Schritte 1,9 | Aufgabe erstellt, Fortschritt getrackt, nächste Aufgabe gegeben |
| **Superpowers** | Schritte 2,3,6,7 | Brainstorming, Planning, Review, Verification |
| **TDD Rules** | Schritt 5 | RED-GREEN-REFACTOR für jede Unteraufgabe erzwungen |
| **rtk** | Jeder Test/Build | Ausgabe um 60-90% komprimiert (~4000 Tokens gespart) |
| **MCP context7** | Auf Anfrage | Express.js Doku geliefert |
| **Templates** | Nicht benötigt | Bestehende Skills waren ausreichend |
| **Hooks** | Automatisch | Pre-command blockierte unsafe Commands, stop-hook startete bd prime |

**Gesamtzeit:** ~20 Minuten
**Tokens durch rtk gespart:** ~4000
**Manuelle Orchestrierung:** Keine — alle Werkzeuge haben automatisch zusammengearbeitet.
