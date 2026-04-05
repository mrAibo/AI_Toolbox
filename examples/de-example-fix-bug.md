# Beispiel: Bugfix — Strukturierter Debugging-Workflow

Wie AI Toolbox Bugs systematisch findet und behebt — nicht durch Raten.

---

## Die Aufgabe

> "Der GET /users/:id Endpoint gibt manchmal 500 statt 404 für nicht existierende Benutzer zurück."

---

## Phase 1: REPRODUCE (Bug-Fix Workflow §1)

**Ziel:** Bug bestätigen und Auslöser verstehen.

Der Agent schreibt einen Reproduktionstest:

```typescript
// bug-repro.test.ts
it("should return 404 for non-existent user, not 500", async () => {
  const response = await request(app).get("/users/nonexistent-id");
  expect(response.status).toBe(404); // Gibt aktuell 500 zurück
});
```

Startet ihn:

```bash
$ rtk test -- bug-repro.test.ts
❌ FAIL bug-repro.test.ts
  GET /users/:id › should return 404 for non-existent user
    Expected: 404
    Received: 500
```

**Status-Ausgabe:**
```
🔧 ACTIVE: Bug Fix — Phase 1/5: REPRODUCE
   → Bug: GET /users/:id gibt 500 statt 404 zurück
   → Repro: Test Case mit nicht-existierender ID
   → Actual: 500 Internal Server Error
   → Expected: 404 Not Found
```

---

## Phase 2: IDENTIFY (Bug-Fix Workflow §2)

**Ziel:** Ursache finden.

Der Agent trace-t rückwärts vom Fehler:

```
## Trace
1. 500 kommt vom Express Error Handler
2. Handler: user-handler.ts Zeile 23
3. Dort: const user = await repo.findById(id)
4. Wenn user === null → Code crasht bei user.toJSON()

## Ursache
findById gibt null für nicht-existierende IDs zurück.
Code prüft null nicht bevor .toJSON() aufgerufen wird.
```

Prüft `git log`:

```bash
$ rtk git log --oneline -5 -- user-handler.ts
a1b2c3 feat: add GET /users/:id endpoint
```

Keine Regression — Bug existiert seit Erstellung des Endpoints.

**Status-Ausgabe:**
```
🔧 ACTIVE: Bug Fix — Phase 2/5: IDENTIFY
   → Root Cause: Fehlende Null-Prüfung vor .toJSON()
   → Affected: user-handler.ts:23
   → Risk: Low — einzeiliger Fix
```

---

## Phase 3: FIX (Bug-Fix Workflow §3)

**Ziel:** Minimaler Fix.

```typescript
// BEFORE (Zeile 23)
const user = await repo.findById(id);
res.json(user.toJSON()); // 💥 crasht wenn user null ist

// AFTER
const user = await repo.findById(id);
if (!user) return res.status(404).json({ error: "User not found" });
res.json(user.toJSON());
```

Nur 2 Zeilen hinzugefügt. Kein Refactoring.

**Status-Ausgabe:**
```
🔧 ACTIVE: Bug Fix — Phase 3/5: FIX
   → Changed: 2 Zeilen in user-handler.ts
   → No refactoring — minimal fix only
```

---

## Phase 4: VERIFY (Bug-Fix Workflow §4)

**Ziel:** Fix bestätigen, auf Regressionen prüfen.

```bash
$ rtk test
✅ PASS (13 tests, 48ms)
   → bug-repro.test.ts: BESTEHT JETZT
   → Alle 12 existierenden Tests: bestehen immer noch

$ rtk lint
✅ No issues
```

Der Agent prüft auch Edge Cases:

```typescript
it("should return 400 for invalid UUID format", async () => {
  const response = await request(app).get("/users/not-a-uuid");
  expect(response.status).toBe(400);
});
```

**Status-Ausgabe:**
```
🔧 ACTIVE: Bug Fix — Phase 4/5: VERIFY
   → Repro test: BESTEHT JETZT ✅
   → All 13 tests: pass
   → Lint: clean
   → Edge case (invalid UUID): behandelt
```

---

## Phase 5: RECORD (Bug-Fix Workflow §5)

**Ziel:** Fix dokumentieren damit er nicht zurückkehrt.

Der Agent schreibt in `architecture-decisions.md`:

```markdown
### ADR-0043: Null check erforderlich für findById Ergebnisse
- Status: accepted
- Date: 2026-04-05
- Context: GET /users/:id gab 500 für nicht-existierende Benutzer zurück
  weil findById null zurückgibt und Code .toJSON() darauf aufrief.
- Decision: Alle findById-Aufrüfer müssen auf null prüfen.
  Null-Prüfung in user-handler.ts hinzugefügt.
- Root Cause: Fehlende defensive Prüfung bei nullable Rückgabewert.
- Consequences: Alle zukünftigen Handler müssen auf null prüfen.
  Zur Code-Review Checklist hinzugefügt.
```

**Status-Ausgabe:**
```
🔧 ACTIVE: Bug Fix — Phase 5/5: RECORD
   → ADR-0043 in architecture-decisions.md festgehalten
   → Zur Code-Review Checklist hinzugefügt
```

---

## Fertig

```bash
$ rtk git commit -m "fix: return 404 for non-existent users instead of 500

Added null check in user-handler.ts before calling .toJSON().
Added regression test. Recorded ADR-0043."

$ bd close "bd-a1b2c3" "Fixed: 500 → 404 for non-existent users"
```

**Status-Ausgabe:**
```
✅ Session Summary — 2026-04-05 15:10 UTC
   → Bug behoben: 500 → 404 für nicht-existierende Benutzer
   → Ursache: Fehlende Null-Prüfung
   → Tests: 13/13 bestanden (1 neuer Regressionstest)
   → ADR: ADR-0043 festgehalten
   → Tokens gespart (rtk): ~800
```

---

## Anti-Patterns — Was der Agent NICHT getan hat

| Anti-Pattern | Was passiert wäre | Was der Agent stattdessen tat |
|--------------|-------------------|------------------------------|
| Fix ohne Reproduktion | Hätte zufällig gefixt, Ursache unbekannt | Test geschrieben, Bug bestätigt |
| Refactoring während Fix | Hätte gesamten Handler umgeschrieben | 2 Zeilen — nur Fix |
| Ohne Verifikation | Hätte "sollte funktionieren" gesagt | 13 Tests ausgeführt |
| Ohne Dokumentation | Bug wäre zurückgekehrt | ADR + Regressionstest |
| Fehler unterdrückt | Hätte 500 mit leerer Antwort versteckt | Korrektes 404 zurückgegeben |

---

## Werkzeuge in diesem Beispiel

| Werkzeug | Rolle |
|----------|-------|
| **TDD Rules** | Regressionstest VOR dem Fix geschrieben |
| **rtk** | Test-Ausgabe 60→6 Zeilen komprimiert |
| **Bug-Fix Workflow** | 5 Phasen: Repro → Identify → Fix → Verify → Record |
| **Code Review** | Checklist vor dem Commit |
| **Status Reporting** | Jede Phase war sichtbar |
