# Test Coverage: Road to 100%

**Datum:** 2026-04-09
**Aktuell:** ~45%
**Ziel:** 100%

---

## Aktueller Stand

| Bereich | Coverage | Lücke |
|---|---|---|
| Syntax-Tests (.sh) | ✅ 100% | — |
| Syntax-Tests (.ps1) | ✅ 100% | — (mit pwsh in CI) |
| Hook Functional (.sh) | ✅ 100% | — |
| Hook Functional (.ps1) | ❌ 0% | 22 SKIP-Tests → müssen mit pwsh laufen |
| Integration (Bootstrap) | ⚠️ 50% | Nur Datei-Existenz, keine Inhalte |
| Integration (Doctor) | ⚠️ 50% | Nur Sections, keine spezifischen Werte |
| Integration (JSON) | ⚠️ 50% | Nur Syntax, keine Schemata |
| Integration (Markdown) | ⚠️ 50% | Nur Links, keine Inhalte |
| Git Hook Tests | ❌ 0% | verify-commit.sh, commit-msg.sh ungetestet |
| Memory Content Tests | ❌ 0% | Template-Inhalte nicht validiert |
| Rule Content Tests | ❌ 0% | Regel-Inhalte nicht validiert |
| Workflow Content Tests | ❌ 0% | Workflow-Schritte nicht validiert |
| Router Content Tests | ❌ 0% | AGENT.md-Referenzen nicht validiert |
| MCP Schema Tests | ❌ 0% | MCP-Configs nur JSON, kein Schema |
| **Gesamt** | **~45%** | **55% Lücke** |

---

## Plan: 100% Coverage

### Phase 1: PowerShell Hooks aktivieren (~100 Zeilen)

| Datei | Tests | Aufwand |
|---|---|---|
| test-hooks.sh | 22 SKIP → PASS | Niedrig |

Da pwsh jetzt in CI installiert ist, müssen die 22 SKIP-Tests laufen.

### Phase 2: Git Hook Tests (~150 Zeilen)

| Datei | Tests | Aufwand |
|---|---|---|
| test-git-hooks.sh | verify-commit.sh: 8 Tests | Mittel |
| test-git-hooks.sh | commit-msg.sh: 8 Tests | Mittel |

**Test-Szenarien:**
- verify-commit.sh: Tier Badge check, broken links, staged files
- commit-msg.sh: TDD-skip detection, test file detection, non-test warning

### Phase 3: Content Validation (~300 Zeilen)

| Datei | Tests | Aufwand |
|---|---|---|
| test-content.md.sh | 16 Rule files: required sections | Mittel |
| test-content.md.sh | 11 Workflow files: required steps | Mittel |
| test-content.md.sh | 8 Router files: AGENT.md reference | Mittel |
| test-content.md.sh | 6 Memory files: required headers | Mittel |

**Test-Szenarien:**
- Jede Rule-Datei hat mindestens: Beschreibung, Regeln, Ausnahmen
- Jede Workflow-Datei hat mindestens: Schritte, Verifikation, Abschluss
- Jede Router-Datei referenziert AGENT.md
- Jede Memory-Datei hat korrekte Header

### Phase 4: MCP Schema Tests (~100 Zeilen)

| Datei | Tests | Aufwand |
|---|---|---|
| test-mcp-schema.sh | 6 MCP configs: required fields | Mittel |

**Test-Szenarien:**
- Jeder MCP-Server hat: command/url, args/env
- Keine unpinned @latest Versionen
- Filesystem-Server hat eingeschränkte Pfade

### Phase 5: Bootstrap Content Tests (~150 Zeilen)

| Datei | Tests | Aufwand |
|---|---|---|
| test-bootstrap-content.sh | 32 erstellte Dateien: Inhalte | Mittel |

**Test-Szenarien:**
- Router-Dateien enthalten korrekte Tier-Badges
- Memory-Dateien haben Seed-Content
- Rule-Dateien sind nicht leer
- Workflow-Dateien haben alle Schritte

### Phase 6: CI Integration (~50 Zeilen)

| Datei | Änderung | Aufwand |
|---|---|---|
| .github/workflows/ci.yml | Neue Test-Schritte hinzufügen | Niedrig |

---

## Aufwandsschätzung

| Phase | Dateien | Zeilen | Aufwand |
|---|---|---|---|
| Phase 1: PS Hooks | 1 | ~100 | 30 Min |
| Phase 2: Git Hooks | 1 | ~150 | 45 Min |
| Phase 3: Content | 1 | ~300 | 60 Min |
| Phase 4: MCP Schema | 1 | ~100 | 30 Min |
| Phase 5: Bootstrap | 1 | ~150 | 45 Min |
| Phase 6: CI | 1 | ~50 | 15 Min |
| **Total** | **6** | **~850** | **3.75 Stunden** |

---

## Realistische Einschätzung

**100% Coverage ist erreichbar** aber bedeutet:
- Jede .sh Datei: alle code paths getestet
- Jede .ps1 Datei: alle code paths getestet (mit pwsh)
- Jede .md Datei:required sections validiert
- Jede .json Datei: Schema validiert
- Jeder Workflow: end-to-end getestet

**Empfehlung:** Ja, durchziehen. Der Aufwand ist moderat (~850 Zeilen Tests) und der Nutzen hoch:
- Keine silent failures mehr möglich
- Jede Änderung wird sofort getestet
- Neue Contributors können sicher arbeiten

**Soll ich starten?**
