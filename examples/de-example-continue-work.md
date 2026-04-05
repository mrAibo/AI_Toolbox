# Beispiel: Arbeit nach Pause fortsetzen — Session Handover

Wie AI Toolbox Kontext nach einer Pause wiederherstellt (über Nacht, Wochenende, Urlaub).

---

## Das Szenario

Du hast gestern an einem Feature gearbeitet. Session geschlossen. Heute morgen — weitermachen.

**Ohne AI Toolbox:** 20-30 Minuten Code nachlesen, Kontext wiederherstellen, erinnern was gemacht wurde.

**Mit AI Toolbox:** 30 Sekunden — der Agent erinnert sich an alles.

---

## Was gestern passiert ist

Du hast am `POST /users` Endpoint gearbeitet. Die Session endete beim IMPLEMENT Schritt (TDD GREEN Phase).

`hook-stop.sh` hat automatisch geschrieben:

```markdown
## Session Handover — 2026-04-04 18:30 UTC

### Completed
- POST /users Handler geschrieben (Fastify)
- 3 Tests hinzugefügt: Happy Path, duplizierte E-Mail, fehlender Name
- Alle 16 Tests bestanden

### In Progress
- Step 5/9: IMPLEMENT (TDD GREEN Phase)
- Next: Validation Middleware für Request Body schreiben

### Next Step
- Request Validation Middleware hinzufügen (Joi Schema)
- Dann: Integrationstest mit echter DB

### Notes
- Joi für Validation (gegen Zod entschieden — einfacher für diesen Fall)
- DB Tests nutzen In-Memory SQLite — langsam aber funktioniert
```

`active-session.md` wurde auch aktualisiert:

```markdown
# Active Session — 2026-04-04 18:30 UTC

## Current Step
- **Workflow:** Unified Workflow (Step 5/9 — IMPLEMENT)
- **Task:** POST /users endpoint (bd-d4e5f6)
- **Phase:** GREEN — Implementation geschrieben, braucht Validation

## Progress
- Steps completed: 4/9
- Subtasks done: 2/4
- Tokens saved (rtk): ~1800
```

---

## Heute morgen: Boot Sequence

Du öffnest das Terminal und startest den AI-Agent.

### Schritt 1: Environmental Check

```
🔍 Checking: .agent/ folder exists ✅
🔍 Checking: rtk binary available ✅
🔍 Checking: bd binary available ✅
```

### Schritt 2: Context Recovery

```
📖 Reading: .agent/memory/architecture-decisions.md
   → 43 ADRs geladen (neueste: ADR-0043 — Null check for findById)

📖 Reading: .agent/memory/integration-contracts.md
   → 2 API Contracts geladen (Users API, Auth API)
```

### Schritt 3: Work-in-Progress Check

```
📖 Reading: .agent/memory/session-handover.md
   → "POST /users handler geschrieben, 3 Tests hinzugefügt"
   → "Next: Validation Middleware für Request Body"
   → "Joi für Validation (gegen Zod entschieden)"
```

### Schritt 4: Task Synchronization

```
🔄 Running: .agent/scripts/sync-task.sh
   → Beads: bd-d4e5f6 "POST /users endpoint" [in_progress]
   → Exported to: .agent/memory/current-task.md
```

### Schritt 5: Summarization

```
✅ Context Restored — 2026-04-05 09:00 UTC

### Yesterday's Progress
- Task: POST /users endpoint (bd-d4e5f6)
- Completed: Handler geschrieben, 3 Tests hinzugefügt
- Stopped at: Step 5/9 — IMPLEMENT (GREEN phase)
- Next: Request validation middleware (Joi)

### Architecture Context
- 43 ADRs verfügbar
- Repository Pattern für Datenzugriff
- Fastify für HTTP Layer
- Joi für Validation

### Ready to continue? [y/n]
```

---

## Weitermachen

Du drückst `y`. Der Agent macht genau dort weiter wo er aufgehört hat:

```
🔧 ACTIVE: Resuming Step 5/9 — IMPLEMENT
   → Task: POST /users endpoint (bd-d4e5f6)
   → Phase: Request Validation Middleware hinzufügen

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
    Received: 201 (user created with missing name)
```

**Status-Ausgabe:**
```
🔧 RED confirmed — now writing Joi validation middleware
```

---

## Was wenn du mehrere Tage verpasst hast?

Der Agent prüft `session-handover.md` und `architecture-decisions.md` auf Änderungen:

```
📖 Reading: .agent/memory/session-handover.md
   → Last session: 2026-04-01 (3 days ago)
   → "POST /users handler geschrieben, stopped at validation"

📖 Reading: .agent/memory/architecture-decisions.md
   → 2 new ADRs since last session:
     ADR-0044: Von Joi zu Zod gewechselt (einfachere TypeScript Integration)
     ADR-0045: Rate Limiting für alle POST Endpoints hinzugefügt

⚠️ DECISION CHANGE DETECTED:
   → ADR-0044: Validation library von Joi zu Zod gewechselt
   → Previous session used Joi — should I switch to Zod? [y/n]
```

Der Agent **macht nicht blind weiter** — er prüft ob sich der Kontext geändert hat.

---

## Was wenn die Aufgabe schon geschlossen wurde?

```
📖 Reading: .agent/memory/session-handover.md
   → "POST /users yesterday by another session abgeschlossen"

🔄 Running: sync-task.sh
   → Beads: bd-d4e5f6 [closed] — "POST /users complete"
   → Next ready: bd-f6g7h8 "Rate limiting für POST /users" [high]

✅ Task bd-d4e5f6 is closed. Picking up next task:
   → bd-f6g7h8: Rate limiting für POST /users hinzufügen

Ready to start? [y/n]
```

---

## Vergleich

| Szenario | Ohne AI Toolbox | Mit AI Toolbox |
|----------|----------------|---------------|
| Pause über Nacht | 20-30 Min Kontext wiederherstellen | 30 Sekunden |
| 3 Tage verpasst | 1+ Stunde nachlesen | 2 Minuten (ADRs prüfen) |
| Aufgabe von anderem geschlossen | Würde es erst nach Coding merken | Sieht es sofort, nimmt nächste |
| Kontext geändert | Würde nach altem Kontext coden | Prüft ADRs vor Start |

---

## Wie es technisch funktioniert

| Datei | Rolle | Aktualisiert von |
|------|-------|-----------------|
| `session-handover.md` | Was gemacht wurde, wo wir stehen | hook-stop.sh/ps1 |
| `active-session.md` | Live-Status der Session | Agent bei jedem Schritt |
| `current-task.md` | Aktuelle Aufgabe aus Beads | sync-task.sh/ps1 |
| `architecture-decisions.md` | Architekturentscheidungen | Agent bei neuen Entscheidungen |
| `integration-contracts.md` | API-Verträge | Agent bei API-Änderungen |

Die Boot Sequence liest diese Dateien **in dieser Reihenfolge** bei jedem Session-Start.
