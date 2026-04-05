# Beispiel: Sicheres Refactoring — Verification Before Completion

Wie AI Toolbox Code refactored ohne bestehende Funktionalität zu brechen.

---

## Die Aufgabe

> "Schreibe user-handler.ts von Express auf Fastify um. Alle Tests müssen grün bleiben."

---

## Pre-Check: Ausgangszustand festhalten

Vor dem Refactoring hält der Agent den aktuellen Stand fest:

```bash
$ rtk test
✅ PASS (13 tests, 48ms)

$ rtk lint
✅ No issues

$ rtk git diff HEAD
# clean — keine uncommitteten Änderungen
```

**Status-Ausgabe:**
```
🔧 ACTIVE: Refactoring user-handler.ts (Express → Fastify)
   → Baseline: 13 tests pass, 0 lint issues
   → Goal: Gleiches Verhalten, anderes Framework
```

---

## Schritt 1: Characterization Tests

Der Agent schreibt Tests die aktuelles Verhalten festhalten (auch wenn es noch keine gibt):

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
✅ PASS (4 neue Contract Tests)
```

Diese Tests sind das Sicherheitsnetz für das Refactoring.

**Status-Ausgabe:**
```
📋 Applying: .agent/rules/tdd-rules.md — characterization tests
🔧 Added 4 contract tests as safety net for refactoring
```

---

## Schritt 2: Refactoring — Kleine Schritte

Der Agent ändert eins nach dem anderen, prüft Tests nach jedem Schritt.

### Schritt 2a: Fastify installieren

```bash
$ rtk npm install fastify @fastify/cors
```

### Schritt 2b: Neuer Fastify Handler

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

**Prüfung nach jedem Schritt:**

```bash
$ rtk test
✅ PASS (17 tests, 52ms)
   → 13 originale Tests: bestanden
   → 4 Contract Tests: bestanden
```

**Status-Ausgabe:**
```
🔧 ACTIVE: Refactoring — Step 2b: Fastify handler written
   → Tests: 17/17 pass (no regressions)
```

---

## Schritt 3: Paralleler Betrieb

Der Agent schaltet den neuen Handler neben den alten:

```typescript
// router.ts
// Alter Express Handler (temporär — wird nach Verifikation entfernt)
// app.use("/users", expressUserHandler);

// Neuer Fastify Handler
await fastify.register(registerUserHandler);
```

**Prüfung:**

```bash
$ rtk test
✅ PASS (17 tests, 52ms)
```

---

## Schritt 4: Alten Code entfernen

Nach Bestätigung dass alles funktioniert, entfernt der Agent den Express Handler:

```bash
$ rtk npm uninstall express
$ rm user-handler-express.ts
```

**Finale Prüfung:**

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

## Schritt 5: Code Review

```
## Changes
- Express Handler durch Fastify ersetzt
- 4 Dateien geändert, 25 Insertions, 41 Deletions
- Alle 17 Tests bestanden (13 original + 4 Contract Tests)

## Checklist
✅ Alle Tests bestanden (rtk test — Exit Code 0)
✅ Keine Lint-Fehler (rtk lint — Exit Code 0)
✅ Keine Debug-Aufrufe
✅ Verhalten unverändert (Contract Tests verifizieren)
✅ Alter Code vollständig entfernt

## Risiken
- Fastify Error Format leicht anders — geprüft, Consumer nicht betroffen
- CORS Headers erhalten — durch Contract Test verifiziert
```

---

## Fertig

```bash
$ rtk git commit -m "refactor: migrate user-handler from Express to Fastify

- Added 4 contract tests as safety net
- Replaced Express handler with Fastify equivalent
- Removed Express dependency from user module
- All 17 tests pass, no behavior changes"

$ bd close "bd-c7d8e9" "Refactored: Express → Fastify, 17 tests green"
```

**Status-Ausgabe:**
```
✅ Session Summary — 2026-04-05 16:45 UTC
   → Refactoring abgeschlossen: Express → Fastify
   → Tests: 17/17 bestanden (4 neue Contract Tests)
   → Zeilen: -41 entfernt, +25 hinzugefügt (netto -16)
   → Tokens gespart (rtk): ~3200
```

---

## Anti-Patterns — Was der Agent NICHT getan hat

| Anti-Pattern | Was passiert wäre | Was der Agent stattdessen tat |
|--------------|-------------------|------------------------------|
| Refactoring ohne Tests | Hätte Verhalten unbemerkt gebrochen | 4 Contract Tests VOR dem Refactoring |
| Big-Bang Commit | 45 Dateien, unmöglich zu reviewen | 4 Dateien, ein Commit |
| "Sollte funktionieren" | Ohne Prüfung | 17 Tests nach jedem Schritt |
| Teilweises Entfernen | Express bliebe in Dependencies | `npm uninstall express` |
| Ohne Contract Tests | API-Änderungen unbemerkt | 4 Tests fixieren API-Vertrag |

---

## Schlüsselprinzip

> **Refactoring = Struktur ändern ohne Verhalten zu ändern.**
> Tests sind der einzige Beweis dass sich Verhalten nicht geändert hat.

AI Toolbox stellt das sicher durch:
1. **TDD Rules** — Characterization Tests vor dem Refactoring
2. **Code Review Checklist** — Verifikation dass Verhalten erhalten bleibt
3. **rtk** — Jeder Testlauf sichtbar ohne Token-Flutung
4. **Status Reporting** — Fortschritt bei jedem Schritt sichtbar
