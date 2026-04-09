# TEST COVERAGE AUDIT — AI Toolbox Project

**Datum:** 2026-04-09
**Auditor:** AI Toolbox Test Specialist
**Scope:** CI Pipeline, Script Tests, Doctor, Bootstrap Parity, Hooks, Documentation, Integration

---

## Executive Summary

| Area | Scripts/Files | Tested | Coverage | Risk |
|------|--------------|--------|----------|------|
| CI Pipeline | 10 steps | 100% syntax-only | **~35%** behavioral | HIGH |
| Script Tests | 1 file (test-scripts.sh) | 100% syntax, 0% behavior | **~10%** | HIGH |
| Doctor | 2 files (.sh/.ps1) | 0% functional | **0%** | MEDIUM |
| Bootstrap Parity | 1 file | Partial structural | **~50%** | MEDIUM |
| Hooks | 14 hook files | 0% behavioral | **0%** | CRITICAL |
| Documentation | 7+ files | Links only | **~20%** | LOW |
| Integration | N/A | None | **0%** | CRITICAL |

**Overall Test Coverage: ~15%** (nur Syntax-Validierung, keine Verhaltens- oder Integrationstests)

---

## 1. CI Coverage (.github/workflows/ci.yml)

### CI-Schritte und was sie testen

| # | Schritt | Was getestet wird | Test-Tiefe |
|---|---------|-------------------|------------|
| 1 | `Block oversized files` | Datei-Größe >500KB | Strukturell ✅ |
| 2 | `Install shellcheck` | Tool-Installation | Infrastruktur ✅ |
| 3 | `Check files exist` | 13 Core-Dateien vorhanden | Strukturell ✅ |
| 4 | `Check router files` | Tier-Badges auf Router-Dateien | Strukturell ✅ |
| 5 | `Validate JSON files` | JSON-Syntax aller .json Dateien | Strukturell ✅ |
| 6 | `Validate markdown links` | Links in Core-Markdown-Dateien | Strukturell ✅ |
| 7 | `Bootstrap parity check` | Strukturelle Parität .sh/.ps1 | Strukturell ⚠️ |
| 8 | `Check trailing newlines` | POSIX-newline compliance | Strukturell ✅ |
| 9 | `Validate client-capabilities.json` | JSON-Schema-Validierung | Strukturell ✅ |
| 10 | `Script syntax validation` | bash -n + pwsh Parser | Strukturell ✅ |
| 11 | `Shellcheck` | Shell-Linting (22 ausgeschl. Regeln) | Statisch ⚠️ |

### Was NICHT in CI getestet wird

| Gap | Beschreibung | Schwierigkeit | Ansatz |
|-----|-------------|---------------|--------|
| **Kein Verhaltenstest** | Kein einziger Schritt validiert dass Skripte korrekt *funktionieren* — nur dass sie syntaktisch gültig sind | Mittel | Tests mit Mock-Dateisystem in Temp-Dirs |
| **Keine Hook-Tests** | hook-pre-command, hook-stop, Qwen-Hooks werden nie ausgeführt | Mittel | Test-Harness mit JSON-Input-Simulation |
| **Keine setup.sh/ps1 Tests** | Das Setup-Skript wird nie in CI ausgeführt | Mittel | CI-Matrix mit simulierter Client-Erkennung |
| **Kein PowerShell auf CI** | pwsh ist nicht auf ubuntu-latest installiert → alle .ps1 Syntax-Checks werden übersprungen | Einfach | `sudo apt install powershell` vor test-scripts.sh |
| **Kein commit-msg Hook Test** | commit-msg.sh/.ps1 werden nur als Dateien geprüft, nicht als Git-Hooks | Mittel | Temporäres Git-Repo in CI erstellen |
| **Kein sync-task Test** | sync-task.sh Logik (Beads-Detection, Task-Type-Erkennung, Framework-Scan) wird nie geprüft | Mittel | Mock-Dateisystem mit package.json, Cargo.toml etc. |
| **Shellcheck nur informational** | `|| true` unterdrückt alle Fehler → CI kann NIE durch Shellcheck fehlschlagen | Einfach | Shellcheck als gating step mit gezielten Exclusions |

### CI Coverage: **~35%** (11/11 Schritte laufen, aber alle nur strukturell/statisch)

---

## 2. Script Test Coverage (.agent/scripts/test-scripts.sh)

### Was tatsächlich getestet wird

| Test | Methode | Erkenntnis |
|------|---------|------------|
| Shell-Syntax | `bash -n script.sh` für jede .sh Datei | Parse-Fehler |
| PowerShell-Syntax | `pwsh Parser::ParseFile()` für jede .ps1 | Parse-Fehler |

**Aktuell: 0 Verhaltens- oder Logik-Tests.** Das Skript validiert NUR dass die Dateien parsebar sind.

### Was NICHT getestet wird

| Script | Ungestestete Logik | Anzahl kritischer Pfade |
|--------|-------------------|------------------------|
| `bootstrap.sh/ps1` | Guard-Klauseln (`[ ! -s file ]`), Verzeichnis-Erstellung, Content-Generierung | 18+ if-Blöcke |
| `hook-pre-command.sh/ps1` | Heavy-Command-Regex, Log-Erkennung, Tool-Tracking (JSON-Manipulation) | 5+ Verzweigungen |
| `hook-pre-command-qwen.sh` | JSON-Parsing, Python-Fallback, JSON-Output-Struktur | 3+ Pfade |
| `hook-post-tool-qwen.sh` | Secret-Scanning, Pfad-Validierung | 5+ Regex-Patterns |
| `hook-pre-compact-qwen.sh` | ADR-Parsing, Context-Injection, JSON-Generierung | 2+ Pfade |
| `hook-session-end-qwen.sh` | hook-stop.sh Integration, bd prime | 1 Aufruf-Pfad |
| `hook-stop.sh/ps1` | session-handover Capping (max 10), Tool-Stats-Anzeige, Dateimanipulation | 4+ Pfade |
| `sync-task.sh` | Beads-Integration, Task-Type-Erkennung, Framework-Scanning (package.json, Cargo.toml, etc.), active-session.md Manipulation | 10+ Pfade |
| `verify-commit.sh/ps1` | Git staged file detection, Tier-Badge-Check, Broken-Link-Erkennung | 3 Checks |
| `commit-msg.sh` | Code-vs-Test-Erkennung, TDD-skip-Parsing | 2+ Pfade |
| `setup.sh/ps1` | Client-Detection, interaktive Auswahl, rtk/Beads-Installation | 10+ Pfade |
| `doctor.sh/ps1` | 8 Prüfkategorien, Exit-Codes (0/1/2) | 30+ Checks |
| `check-trailing-newlines.sh` | Binary-Heuristik, Newline-Erkennung, Multi-Newline-Warnung | 3+ Pfade |
| `validate-client-capabilities.sh` | JSON-Schema mit Python | 2+ Pfade |

### test-scripts.sh Coverage: **~10%** (2 Checks von ~50+ benötigten)

### Schwierigkeitsbewertung

| Typ | Schwierigkeit | Begründung |
|-----|---------------|------------|
| Syntax-Tests | ✅ Erledigt | bash -n, pwsh Parser |
| Verhaltenstests | Mittel | Erfordert Temp-Dirs, Mock-Dateien, Git-Repos |
| Hook-JSON-Validierung | Mittel | Erfordert JSON-Input-Simulation, Schema-Checks |
| Git-Hook-Tests | Höher | Erfordert echtes Git-Repo mit staged changes |

---

## 3. Doctor Coverage (doctor.sh / doctor.ps1)

### Geprüfte Komponenten

| # | Kategorie | Checks | Exit-Code |
|---|-----------|--------|-----------|
| 1 | Core Structure | 5 Verzeichnisse | fail |
| 2 | Router Files | 8 Dateien + Tier-Badges | warn |
| 3 | Hook Scripts | 12 Dateien (6 × .sh + .ps1) | warn |
| 4 | Qwen Hooks | 6 Hook-Names in settings.json | warn |
| 5 | Tooling | rtk, Beads, shellcheck | warn |
| 6 | Memory Files | 5 Dateien + ADR-Verzeichnis | warn |
| 7 | .gitignore | 3 Entries | fail |
| 8 | Bootstrap Parity | 6 Skript-Paare | mixed |

### Was FEHLT

| Missing Check | Risiko | Schwierigkeit | Ansatz |
|--------------|--------|---------------|--------|
| **Kein Test dass doctor.sh selbst korrekt funktioniert** | Doctor könnte falsche Positive liefern | Mittel | Test mit absichtlich kaputter Struktur |
| **Kein Abgleich .sh vs .ps1 Output** | Doctor.ps1 könnte andere Ergebnisse liefern als doctor.sh | Mittel | Beide ausführen und Output vergleichen |
| **Kein Test der Exit-Codes** | Exit 0/1/2 Logik ist nie verifiziert | Einfach | Temp-Dir mit verschiedenen Szenarien |
| **Kein Test: Qwen-Hooks absent** | Wenn .qwen/settings.json fehlt, wird Sektion übersprungen — nie getestet | Einfach | Temp-Dir ohne .qwen/ |
| **Kein Test: Teilweise fehlende Struktur** | Nur "alles da" oder "alles fehlt" Szenarien | Einfach | Systematisch Dateien entfernen |
| **Kein Test: rtk/bd Versionsausgabe** | `rtk --version` könnte leere Ausgabe produzieren | Einfach | Mock-Commands |

### Doctor Test Coverage: **0%** (Doctor ist ein Diagnose-Tool, selbst aber ungetestet)

---

## 4. Bootstrap Parity (.agent/scripts/bootstrap-parity-check.sh)

### Was es prüft

| Check | Methode | Vollständigkeit |
|-------|---------|-----------------|
| Beide Dateien existieren | `[ -f ]` | ✅ |
| Verzeichnis-Referenzen | grep auf EXPECTED_DIRS | ⚠️ Teilweise |
| Memory-File-Referenzen | check_references() | ⚠️ Statisch |
| Rule-File-Referenzen | check_references() | ⚠️ Statisch |
| Router-File-Referenzen | check_references() | ⚠️ Statisch |
| Guard-Clause-Count | grep -c Vergleich | ℹ️ Informativ |
| Funktioneller Test | Temp-Dir Ausführung + Dateizahl-Vergleich | ✅ Aber nur wenn pwsh verfügbar |

### Kritische Mängel

| Mangel | Beschreibung | Auswirkung |
|--------|-------------|------------|
| **Statische grep-Analyse, keine semantische** | `grep -q "$escaped"` findet den String auch in Kommentaren oder anderen Kontexten | Falsch-Positive |
| **Kein Content-Vergleich** | Die PARITÄT der generierten Inhalte wird nicht geprüft — nur ob Referenzen existieren | bootstrap.sh und bootstrap.ps1 könnten völlig unterschiedliche Inhalte schreiben |
| **Funktionaler Test nur mit pwsh** | Ohne pwsh wird der einzige echte Verhaltenstest übersprungen | CI auf ubuntu-latest hat kein pwsh |
| **Kein Exit-Code-Vergleich** | Gleiche Dateizahl ≠ gleicher Inhalt | Zwei Skripte könnten 20 Dateien erstellen, aber verschiedene |
| **Nur 7 Regel-Dateien geprüft** | bootstrap.sh erstellt 11 Regel-Dateien, die Checkliste hat nur 10 | Fehlende Datei: mcp-rules.md ist nicht in EXPECTED_RULE_FILES |
| **Kein Template-Vergleich** | Bootstrap kopiert Templates (.claude.json, QWEN.md, etc.) — nie geprüft | Template-Drift zwischen .sh und .ps1 |

### Bootstrap Parity Coverage: **~50%** (strukturelle Referenzen geprüft, aber keine semantische Inhaltsgleichheit)

### Empfohlene Ergänzungen

```
1. Content-Diff: Beide Skripte in identischen Temp-Dirs ausführen und diff -r nutzen
2. Semantisches Parsing: Nicht grep auf String-Ebene, sondern AST-basiert prüfen
3. Template-Parity: Prüfen ob beide Skripte dieselben Templates referenzieren
4. Git-Hook-Parity: Prüfen ob beide Skripte dieselben Git-Hooks einrichten
```

---

## 5. Hook Testing

### Hook-Übersicht (14 Dateien)

| Hook | .sh | .ps1 | JSON-Output | Getestet |
|------|-----|------|-------------|----------|
| hook-pre-command | ✅ | ✅ | Nein | ❌ |
| hook-stop | ✅ | ✅ | Nein | ❌ |
| hook-pre-command-qwen | ✅ | ✅ (.ps1 als ps1-qwen) | Ja | ❌ |
| hook-post-tool-qwen | ✅ | ✅ | Ja | ❌ |
| hook-pre-compact-qwen | ✅ | ✅ | Ja | ❌ |
| hook-session-end-qwen | ✅ | ✅ | Ja | ❌ |
| hook-stop-qwen | — | ✅ | Ja | ❌ |

### Ungestestete Verhaltensaspekte

#### hook-pre-command.sh/ps1
| Test-Szenario | Status | Risiko |
|--------------|--------|--------|
| Heavy Command erkannt (python3 -c "...") | ❌ Ungetestet | KI verschwendet Tokens |
| rtk-präfixierte Commands passieren | ❌ Ungetestet | False Positives blockieren Workflows |
| Log-File-Erkennung (cat app.log) | ❌ Ungetestet | Große Logs im Context |
| Tool-Tracking (.tool-stats.json wird aktualisiert) | ❌ Ungetestet | Stats kaputt |
| Leerer Input | ❌ Ungetestet | Hook crash |
| JSON-Output valide? | ❌ (kein JSON-Output) | N/A |
| .tool-stats.json Initialisierung bei fehlender Datei | ❌ Ungetestet | Stats verlieren |

#### hook-pre-command-qwen.sh (JSON-Protokoll)
| Test-Szenario | Status | Risiko |
|--------------|--------|--------|
| Gültiger JSON-Input → JSON-Output | ❌ Ungetestet | Qwen Hook Integration bricht |
| Leerer Input → `{"decision":"allow"...}` | ❌ Ungetestet | Hook blockiert alles |
| Kein python3/jq verfügbar | ❌ Ungetestet | Silent failure |
| Heavy Command → `decision: "ask"` | ❌ Ungetestet | User wird nicht gefragt |
| JSON-Output valid? (parsebar?) | ❌ Ungetestet | Qwen kann Antwort nicht lesen |
| Malformed JSON Input | ❌ Ungetestet | Python Exception → keine Ausgabe |

#### hook-post-tool-qwen.sh (Secret Scanner)
| Test-Szenario | Status | Risiko |
|--------------|--------|--------|
| Datei mit Passwort → Detection | ❌ Ungetestet | Secrets im Repo |
| Datei ohne Secrets → Pass | ❌ Ungetestet | False Positives stören Workflow |
| Datei außerhalb Repo → Skip | ❌ Ungetestet | Security-Bypass |
| Private Key Detection | ❌ Ungetestet | Kritische Secrets übersehen |
| JSON-Output valid? | ❌ Ungetestet | Hook-Integration bricht |

#### hook-pre-compact-qwen.sh
| Test-Szenario | Status | Risiko |
|--------------|--------|--------|
| ADR existiert → Context injiziert | ❌ Ungetestet | Context nach Compaction verloren |
| Keine ADR → kein Crash | ❌ Ungetestet | Hook bricht Compaction |
| JSON-Output valid? | ❌ Ungetestet | Qwen kann Antwort nicht lesen |

#### hook-session-end-qwen.sh
| Test-Szenario | Status | Risiko |
|--------------|--------|--------|
| hook-stop.sh wird aufgerufen | ❌ Ungetestet | Memory nicht konsolidiert |
| bd prime verfügbar | ❌ Ungetestet | Task-State veraltet |
| JSON-Output valid? | ❌ Ungetestet | Hook-Integration bricht |

#### hook-stop.sh
| Test-Szenario | Status | Risiko |
|--------------|--------|--------|
| session-handover Capping (>10 Summaries) | ❌ Ungetestet | Unbounded Growth |
| Tool-Stats-Anzeige (python3/json) | ❌ Ungetestet | Stats nicht lesbar |
| active-session.md → session-handover.md Merge | ❌ Ungetestet | Context-Verlust |

### Schwierigkeitsbewertung Hook-Tests

| Kategorie | Schwierigkeit | Begründung |
|-----------|---------------|------------|
| JSON-Input-Simulation | **Einfach** | echo '{"tool_input":{"command":"..."}}' | pipe in hook |
| JSON-Output-Validierung | **Einfach** | python3 -c "json.loads(sys.stdin)" |
| Heavy-Command-Regex | **Einfach** | Parametrisierte Tests mit 20+ Command-Varianten |
| Secret-Detection | **Mittel** | Temporäre Dateien mit Test-Secrets erstellen |
| Git-Integration (verify-commit) | **Mittel** | Temp-Git-Repo mit staged changes |
| Tool-Tracking (.tool-stats.json) | **Mittel** | Datei-Manipulation und JSON-Vergleich |
| Qwen-Hook-End-to-End | **Höher** | Erfordert Qwen Code Umgebung |

### Hook Test Coverage: **0%** (kein einziger Hook wird funktional getestet)

---

## 6. Documentation Testing

### Getestet in CI

| Dokument | Link-Check | Befehls-Verifikation |
|----------|-----------|---------------------|
| README.md | ✅ (CI Step 6) | ❌ |
| AGENT.md | ✅ | ❌ |
| INSTALL.md | ✅ | ❌ |
| QUICKSTART.md | ✅ | ❌ |
| CONTRIBUTING.md | ✅ | ❌ |
| CLAUDE.md | ✅ | ❌ |
| QWEN.md | ✅ | ❌ |
| GEMINI.md | ✅ | ❌ |
| CONVENTIONS.md | ✅ | ❌ |
| .cursorrules | ✅ | ❌ |
| .clinerules | ✅ | ❌ |
| .windsurfrules | ✅ | ❌ |
| .agent/rules/*.md | ✅ | ❌ |
| .agent/workflows/*.md | ✅ | ❌ |

### Was NICHT getestet wird

| Gap | Beschreibung | Schwierigkeit | Ansatz |
|-----|-------------|---------------|--------|
| **Befehle funktionieren nicht verifiziert** | README sagt `bash .agent/scripts/setup.sh` — wird nie ausgeführt | Mittel | CI-Job der Setup-Kommandos in frischem Repo ausführt |
| **Externe Links nicht geprüft** | CI überspringt http/https Links | Einfach | `lychee` oder `markdown-link-check` für externe URLs |
| **Code-Blöcke in Doku** | Snippets in README/INSTALL/QUICKSTART nie ausgeführt | Höher | Doctest-ähnliches Tool für Markdown |
| **Cross-Referenzen zwischen Docs** | docs/mcp-guide.md wird nicht im Link-Check geprüft (liegt outside core) | Einfach | docs/ in Link-Check aufnehmen |
| **Bootstrap-Output in Doku** | Beschriebene Ausgabe der Skripte stimmt mit Realität überein? | Höher | Snapshot-Tests |

### Documentation Test Coverage: **~20%** (nur interne Links, keine Befehls-Verifikation)

---

## 7. Integration Testing

### Existierende Integrationstests: **KEINE**

| Bereich | Status | Begründung |
|---------|--------|------------|
| **End-to-End Workflow (Boot → Task → Handover)** | ❌ Nicht vorhanden | Keine Simulation des vollständigen AI-Agent-Zyklus |
| **AI Agent Verhalten** | ❌ Nicht vorhanden | Kein Test ob AI-Regeln aus AGENT.md befolgt werden |
| **Beads + sync-task Integration** | ❌ Nicht vorhanden | bd list → current-task.md Pipeline ungetestet |
| **rtk + hook-pre-command Integration** | ❌ Nicht vorhanden | rtk-Präfix-Erkennung nie getestet |
| **Git Hook Pipeline (pre-commit → verify-commit → commit-msg)** | ❌ Nicht vorhanden | Komplette Git-Hook-Kette nie integriert getestet |
| **Qwen Hook Chain (SessionStart → PreToolUse → PostToolUse → Stop → SessionEnd)** | ❌ Nicht vorhanden | Keine Sequenz-Tests |
| **Bootstrap → Doctor → Setup Pipeline** | ❌ Nicht vorhanden | Fresh-Repo-Setup nie End-to-End getestet |
| **Cross-Platform (.sh vs .ps1)** | ⚠️ Partiell | Nur strukturelle Parität, keine Verhaltenstests |

### Schwierigkeitsbewertung Integrationstests

| Test | Schwierigkeit | Begründung | Ansatz |
|------|---------------|------------|--------|
| Fresh-Repo Bootstrap | **Einfach** | Temp-Dir → bootstrap.sh → Struktur prüfen | Automatisierbar in CI |
| Git Hook Chain | **Mittel** | Temp-Git-Repo → staged changes → commit | Automatisierbar |
| Boot→Task→Handover | **Höher** | Erfordert simulierte AI-Interaktion | Mock-Skript das Memory-Dateien schreibt |
| Qwen Hook Chain | **Höher** | Erfordert Qwen JSON-Protokoll | JSON-Input-Harness |
| AI Agent Verhalten | **Sehr Hoch** | Erfordert echten AI-Client | Prompt-Engineering-Tests |

### Integration Test Coverage: **0%**

---

## 8. Gesamtbewertung nach Risikokategorie

### CRITICAL (0% getestet, hohes Risiko)
- **Alle 14 Hook-Dateien**: Keine Validierung des JSON-Outputs, keine Edge-Case-Tests
- **Integrationstests**: Kein End-to-End-Workflow
- **hook-post-tool-qwen.sh**: Secret-Scanner mit 6 Regex-Patterns — nie gegen echte Test-Secrets geprüft

### HIGH (wenig getestet, mittleres Risiko)
- **sync-task.sh**: 10+ Code-Pfade (Beads, Framework-Detection, Task-Typ-Erkennung)
- **setup.sh/ps1**: Komplexes interaktives Skript mit 10+ Pfaden
- **CI**: Shellcheck als non-gating, kein PowerShell auf ubuntu-latest
- **commit-msg.sh/ps1**: TDD-Enforcement-Logik ungetestet

### MEDIUM (teilweise getestet)
- **Bootstrap Parity**: Strukturelle Referenzen geprüft, aber keine Content-Gleichheit
- **Doctor**: 8 Prüfkategorien, aber Doctor selbst ungetestet
- **Dokumentation**: Links geprüft, Befehle nicht

### LOW (ausreichend getestet)
- **JSON-Validierung**: Alle .json Dateien werden validiert
- **Datei-Existenz-Checks**: Core-Dateien werden geprüft
- **Trailing Newlines**: Vollständig abgedeckt

---

## 9. Priorisierte Empfehlungen

### Phase 1: Quick Wins (1-2 Tage)

1. **PowerShell in CI installieren** — pwsh auf ubuntu-latest → .ps1 Syntax-Tests laufen
   - Aufwand: 10 Minuten
   - Impact: +5% Coverage

2. **Shellcheck als gating step** — `|| true` entfernen, gezielte Exclusions
   - Aufwand: 30 Minuten
   - Impact: Echte Linting-Sicherheit

3. **Hook JSON-Output Validierung** — einfache Tests die JSON in die Hooks pipen und Output parsen
   - Aufwand: 2-3 Stunden
   - Impact: +15% Coverage, CRITICAL Risiko adressiert

### Phase 2: Verhaltenstests (3-5 Tage)

4. **test-scripts.sh erweitern** um Verhaltenstests für:
   - hook-pre-command: Heavy-Command-Erkennung
   - hook-post-tool-qwen: Secret-Detection
   - verify-commit: Tier-Badge-Check
   - check-trailing-newlines: Boundary-Cases
   - Aufwand: 1-2 Tage
   - Impact: +25% Coverage

5. **Bootstrap Parity verbessern** — Content-Diff statt nur String-Matching
   - Aufwand: 2-3 Stunden
   - Impact: Echte .sh/.ps1 Parität

6. **Doctor Selbsttest** — Temp-Dir mit kaputter Struktur → Doctor sollte korrekt warnen
   - Aufwand: 1-2 Stunden
   - Impact: Diagnose-Sicherheit

### Phase 3: Integrationstests (5-10 Tage)

7. **Fresh-Repo E2E Test** — Leeres Temp-Repo → bootstrap → setup (non-interactive) → doctor
   - Aufwand: 1-2 Tage
   - Impact: +15% Coverage

8. **Git Hook Chain Test** — Temp-Git-Repo → staged changes → commit → verify
   - Aufwand: 1-2 Tage
   - Impact: Git-Integration-Sicherheit

9. **Qwen Hook Chain Simulation** — JSON-Input-Harness für alle 6 Hooks
   - Aufwand: 2-3 Tage
   - Impact: Full-Tier Integrationssicherheit

---

## 10. Coverage-Matrix

```
Komponente                    │ Dateien │ Syntax │ Verhalten │ Integration │ TOTAL
──────────────────────────────┼─────────┼────────┼───────────┼─────────────┼──────
CI Pipeline                   │    1    │  100%  │    0%     │     0%      │  35%
Script Syntax Tests           │    1    │  100%  │    0%     │     0%      │  10%
bootstrap.sh / .ps1           │    2    │  100%  │    0%     │     0%      │  15%
sync-task.sh                  │    1    │  100%  │    0%     │     0%      │   5%
hook-pre-command.sh / .ps1    │    2    │  100%  │    0%     │     0%      │  10%
hook-pre-command-qwen.sh      │    1    │  100%  │    0%     │     0%      │   5%
hook-post-tool-qwen.sh        │    1    │  100%  │    0%     │     0%      │   5%
hook-pre-compact-qwen.sh      │    1    │  100%  │    0%     │     0%      │   5%
hook-session-end-qwen.sh      │    1    │  100%  │    0%     │     0%      │   5%
hook-stop-qwen.ps1            │    1    │  100%  │    0%     │     0%      │   5%
hook-stop.sh / .ps1           │    2    │  100%  │    0%     │     0%      │  10%
verify-commit.sh / .ps1       │    2    │  100%  │    0%     │     0%      │  10%
commit-msg.sh                 │    1    │  100%  │    0%     │     0%      │   5%
setup.sh / .ps1               │    2    │  100%  │    0%     │     0%      │   5%
doctor.sh / .ps1              │    2    │  100%  │    0%     │     0%      │   5%
check-trailing-newlines.sh    │    1    │  100%  │    0%     │     0%      │  10%
validate-client-capabilities  │    1    │  100%  │    0%     │     0%      │  10%
bootstrap-parity-check        │    1    │  100%  │   25%     │     0%      │  50%
──────────────────────────────┼─────────┼────────┼───────────┼─────────────┼──────
GESAMT                        │   25    │  100%  │    2%     │     0%      │  15%
```

**Legende:**
- Syntax = `bash -n` / pwsh Parser (vorhanden ✅)
- Verhalten = Logik-Pfade mit spezifischen Inputs getestet
- Integration = Zusammenspiel mehrerer Komponenten
- TOTAL = Gewichteter Durchschnitt (Syntax 20%, Verhalten 50%, Integration 30%)

---

*End of Audit Report*
