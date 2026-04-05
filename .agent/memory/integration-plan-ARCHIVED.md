# Integration Plan: Template Bridge + MCP + Superpowers Ensemble

## Vision

Alle externen Tools arbeiten zusammen wie ein Ensemble:
- **Beads** = WAS (Task-Erstellung, Status-Tracking, Session-Persistenz)
- **Superpowers** = WIE (Methodik: TDD, Brainstorming, Debugging, Review, Verification)
- **Template Bridge** = WANN/WER (Workflow-Orchestrierung + 413+ Specialist Templates)
- **rtk** = Token-Optimierung (auto-Hooks, 60-90% weniger Tokens)
- **MCP** = WORÜBER (externe Ressourcen: Docs, Web, GitHub, Memory)

Der User muss **nichts** manuell orchestrieren — das Ensemble arbeitet automatisch.

---

## Analyse: Was Template Bridge liefert

| Komponente | Zweck | Status in AI Toolbox |
|---|---|---|
| **unified-workflow** Skill | 9-Schritte-Prozess: bd create → brainstorm → plan → TDD → review → verify → finish → bd close | ❌ FEHLT |
| **template-catalog** Skill | On-Demand-Zugriff auf 413+ Specialist Templates | ❌ FEHLT |
| **browse-templates** Command | `/browse-templates` für interaktive Template-Suche | ❌ FEHLT |
| **SessionStart/PreCompact Hooks** | Auto-lädt `bd prime` bei Session-Start und vor Context-Kompaktierung | ⚠️ TEILWEISE (nur sync-task) |
| **CLAUDE.md** (9-Schritte-Workflow) | System-Prompt mit striktem Workflow | ⚠️ TEILWEISE (in AGENT.md kodiert, aber nicht als harter Prozess) |
| **TDD als HARTE Regel** | RED → Verify RED → GREEN → Verify GREEN → REFACTOR → COMMIT | ❌ FEHLT (nur "test-first when possible") |

---

## Plan: 5 Phasen

### Phase 1: Superpowers Skills vollständig kodieren

**Ziel:** Alle 11 Superpowers Skills als AI Toolbox Rules/Workflows verfügbar machen.

#### 1.1 `.agent/rules/tdd-rules.md` — Harte TDD-Regel (NEU)

```markdown
# Test-Driven Development (TDD) Rules

Core rule: NEVER write production code without a failing test first.

## RED-GREEN-REFACTOR Cycle

1. **RED:** Write a failing test that demonstrates the desired behavior
2. **VERIFY RED:** Run the test — it MUST fail. If it passes, the test is wrong.
3. **GREEN:** Write the MINIMAL code to make the test pass
4. **VERIFY GREEN:** Run the test — it MUST pass
5. **REFACTOR:** Clean up the code while keeping tests green
6. **COMMIT:** Only after all tests pass

## Anti-Patterns (NEVER do these)
- Writing production code before a failing test exists
- Skipping the "verify red" step (assuming the test fails without running it)
- Writing more code than needed to pass the current test
- Refactoring before all tests pass
- Committing with failing tests
```

**Wo verankert:**
- Referenziert in `AGENT.md` §8 (Verification Rules)
- Referenziert in `testing-rules.md` (ersetzt "test-first when possible")

#### 1.2 `.agent/workflows/code-review.md` — Review-Gate (NEU)

```markdown
# Code Review Workflow

Before merging or marking a task complete:

## Pre-Review Checklist
- [ ] All tests pass (verified with rtk test)
- [ ] No console.log/debug statements left
- [ ] Code follows project style (checked via rtk lint)
- [ ] No TODO comments without issue references
- [ ] Changes match the original plan (check .agent/memory/current-task.md)

## Review Process
1. Summarize what was changed and why
2. List any risks or edge cases not covered
3. Run verification one final time
4. If issues found → fix and re-verify
5. If clean → proceed to finish
```

**Wo verankert:**
- Referenziert in `multi-agent.md` (Sub-Agent Output muss Review-Gate passieren)
- Referenziert in `bug-fix.md` Phase 4 (Verify)

#### 1.3 `.agent/workflows/branch-finish.md` — Branch/Merge Workflow (NEU)

```markdown
# Finishing a Development Branch

When a feature or fix is complete:

## Steps
1. Run final verification: rtk test (all tests pass)
2. Run lint: rtk lint (no errors)
3. Check diff: rtk diff (review all changes)
4. Update session-handover.md with summary
5. Close task: bd close "<ID>" "Completed: <summary>"
6. Decide: Merge, create PR, or keep branch
```

**Wo verankert:**
- Referenziert in AGENT.md §10 (End-of-session behavior)

#### 1.4 `AGENT.md` aktualisieren

Neue Sections:
- §7.1: TDD Rules → verweist auf `.agent/rules/tdd-rules.md`
- §8.1: Code Review → verweist auf `.agent/workflows/code-review.md`
- §10.1: Branch Finish → verweist auf `.agent/workflows/branch-finish.md`

**Betroffene Dateien:**
- `AGENT.md`
- `.agent/rules/testing-rules.md` (verweist jetzt auf tdd-rules.md)
- `.agent/rules/tdd-rules.md` (NEU)
- `.agent/workflows/code-review.md` (NEU)
- `.agent/workflows/branch-finish.md` (NEU)

---

### Phase 2: Template Bridge Integration

**Ziel:** 413+ Specialist Templates als On-Demand-Ressource verfügbar machen.

#### 2.1 `.agent/rules/template-usage.md` — Template-Nutzungsregeln (NEU)

```markdown
# Template Usage Rules

When to use specialist templates:
1. Existing skills (TDD, Planning, Debugging) don't cover the need
2. Working with a specialized technology (Rust, Go, Kubernetes, etc.)
3. Need established patterns instead of improvising

How to access templates:
- Claude Code: /browse-templates command
- Other clients: Browse https://github.com/maslennikov-ig/template-bridge
- Direct: npx claude-code-templates@latest --agent <category/name> --yes

Template categories (26 total):
- ai-specialists, api-graphql, api-rest, blockchain-web3
- database, devops-infrastructure, mobile, programming-languages
- security, ui-analysis, and 16 more...

Rule: Always document which template was used in architecture-decisions.md
```

**Wo verankert:**
- Referenziert in `tool-integrations.md` (ersetzt vagen Template Bridge Hinweis)
- Referenziert in `AGENT.md` §13 (External Project Integrations)

#### 2.2 `.agent/workflows/use-template.md` — Template-Nutzungs-Workflow (NEU)

```markdown
# Template Usage Workflow

When you need a specialist template:

1. **Identify need:** What task can't existing skills handle?
2. **Search:** Use /browse-templates or npx claude-code-templates@latest
3. **Select:** Choose the most relevant template
4. **Adapt:** Apply template to current task, adjust for project context
5. **Document:** Record in architecture-decisions.md which template was used
6. **Execute:** Follow the template's guidance
```

**Betroffene Dateien:**
- `.agent/rules/template-usage.md` (NEU)
- `.agent/workflows/use-template.md` (NEU)
- `.agent/rules/tool-integrations.md` (Template Bridge Sektion erweitert)
- `install.md` (Template Bridge Setup konkretisiert)

---

### Phase 3: MCP Vollintegration

**Ziel:** MCP-Setup für ALLE 8 Clients, nicht nur Claude Code + Qwen Code.

#### 3.1 `.agent/templates/mcp/` — Client-spezifische MCP Configs (NEU)

Neue Dateien:
- `mcp-cursor.json` — Cursor MCP config
- `mcp-clinerules.json` — RooCode/Cline MCP config
- `mcp-windsurf.json` — Windsurf MCP config
- `mcp-gemini.json` — Gemini CLI MCP config
- `mcp-aider.json` — Aider MCP config

Jede Datei enthält die MCP-Server-Konfiguration im jeweiligen Client-Format.

#### 3.2 `docs/mcp-guide.md` erweitern

Neue Sections:
- Setup für Cursor (JSON config in `.cursor/settings.json`)
- Setup für RooCode/Cline (`.clinerules` MCP section)
- Setup für Windsurf (`.windsurfrules` MCP section)
- Setup für Gemini CLI (JSON config)
- Setup für Aider (`.aider.conf.yml` MCP section)

#### 3.3 `install.md` Step 4 erweitern

Statt nur `claude mcp add` Commands:
- Plattform-Erkennung: "Which AI client are you using?"
- Client-spezifische MCP-Setup-Anweisungen
- Fallback: Manuelle JSON-Konfiguration für alle Clients

**Betroffene Dateien:**
- `.agent/templates/mcp/mcp-cursor.json` (NEU)
- `.agent/templates/mcp/mcp-clinerules.json` (NEU)
- `.agent/templates/mcp/mcp-windsurf.json` (NEU)
- `.agent/templates/mcp/mcp-gemini.json` (NEU)
- `.agent/templates/mcp/mcp-aider.json` (NEU)
- `docs/mcp-guide.md` (erweitert)
- `install.md` (Step 4 erweitert)

---

### Phase 4: Unified Workflow — Das Ensemble

**Ziel:** Alle Tools arbeiten als EIN orchestrierter Prozess.

#### 4.1 `.agent/workflows/unified-workflow.md` — Der Master-Workflow (NEU)

```markdown
# Unified Development Workflow

This is the PRIMARY workflow. All tools work together automatically.

## The 9-Step Process

### 1. TASK (Beads)
- `bd create "feature" -p high` — Task erstellen
- Auto-geladen via sync-task.sh bei Session-Start

### 2. BRAINSTORM (Superpowers → AGENT.md §7)
- Analyse, Constraints, 2-3 Ansätze
- Wenn unklar: `.agent/workflows/multi-agent.md` für parallele Analyse

### 3. PLAN (Superpowers → AGENT.md §3)
- Arbeit in 2-5 Min Tasks zerlegen
- Jeder Task: klarer Input, Output, Verification

### 4. ISOLATE (optional)
- Bei komplexen Tasks: Git Worktree oder Feature Branch
- `.agent/workflows/branch-finish.md` für Merge-Prozess

### 5. IMPLEMENT (TDD → .agent/rules/tdd-rules.md)
Für JEDEN Sub-Task:
  a. RED: Failing test schreiben
  b. VERIFY RED: `rtk test` — MUSS fehlschlagen
  c. GREEN: Minimaler Code zum Bestehen
  d. VERIFY GREEN: `rtk test` — MUSS bestehen
  e. REFACTOR: Code säubern (Tests bleiben grün)
  f. COMMIT: `rtk git commit`

### 6. REVIEW (.agent/workflows/code-review.md)
- Pre-Review Checklist durchgehen
- Bei Multi-Agent: Sub-Agent Output prüfen

### 7. VERIFY (Superpowers → testing-rules.md)
- Letzter Verification-Lauf: `rtk test`, `rtk lint`
- Exit Code und Output prüfen

### 8. FINISH (.agent/workflows/branch-finish.md)
- Session-Handover aktualisieren
- Task schließen: `bd close "<ID>" "Completed: <summary>"`

### 9. CLOSE (Beads)
- Task als abgeschlossen markieren
- Nächster Task: `bd ready`

## Tool Coordination Matrix

| Step | Primary Tool | Auto-Trigger | Manual Override |
|------|-------------|-------------|-----------------|
| TASK | Beads | sync-task.sh | bd create |
| BRAINSTORM | Superpowers/AGENT.md | AGENT.md §7 | prompts/01-planning.md |
| PLAN | Superpowers/AGENT.md | AGENT.md §3 | - |
| IMPLEMENT | TDD + rtk | hook-pre-command | rtk test |
| REVIEW | AI Toolbox Rules | code-review.md | - |
| VERIFY | rtk + Superpowers | testing-rules.md | rtk test |
| FINISH | Beads + Memory | hook-stop.sh | bd close |
```

**Wo verankert:**
- AGENT.md §3 verweist hierher als PRIMARY workflow
- README.md Core Stack zeigt diesen Workflow
- `prompts/02-execution.md` verweist hierher

#### 4.2 `hook-stop.sh/ps1` erweitern — Auto-Sync bei Session-End

Aktuell: erinnert an Memory-Konsolidierung.
Neu: führt automatisch `bd prime` aus (wie Template Bridge SessionStart/PreCompact Hooks).

**Betroffene Dateien:**
- `.agent/workflows/unified-workflow.md` (NEU)
- `.agent/scripts/hook-stop.sh` (erweitert: `bd prime`)
- `.agent/scripts/hook-stop.ps1` (erweitert: `bd prime`)
- `AGENT.md` §3 (verweist auf unified-workflow.md)

---

### Phase 5: Dokumentation & Examples

**Ziel:** User versteht das Ensemble auf einen Blick.

#### 5.1 `README.md` aktualisieren

Neuer Abschnitt nach Core Stack:

```markdown
### 🎻 How the Ensemble Works

All tools work together automatically:

1. **You describe a feature** → Beads creates the task
2. **AI brainstorms** → Superpowers skills guide the analysis
3. **AI plans** → Tasks broken into 2-5 min steps
4. **AI implements with TDD** → RED → GREEN → REFACTOR (enforced by rules)
5. **rtk optimizes** → Every test/build uses 60-90% fewer tokens
6. **MCP provides resources** → Docs, web content, GitHub on demand
7. **Templates fill gaps** → 413+ specialist agents when needed
8. **AI reviews itself** → Code Review Workflow before finish
9. **Beads tracks progress** → Task closed, next one ready

No manual orchestration needed. Just describe what you want.
```

#### 5.2 `examples/ensemble-walkthrough.md` — End-to-End Beispiel (NEU)

Ein komplettes Beispiel: "Build a REST API endpoint" — zeigt jeden Schritt mit:
- Welches Tool wann aktiv wird
- Welche Commands ausgeführt werden
- Welche Files geschrieben werden
- Wie die Tools zusammenarbeiten

#### 5.3 `prompts/02-execution.md` aktualisieren

Statt generischem "continue work" Prompt:

```
"We're continuing our work. Execute the Unified Workflow:
1. Read AGENT.md §3 (unified-workflow.md)
2. Run sync-task to get current state
3. Read session-handover.md
4. Execute the next step in the 9-step process"
```

**Betroffene Dateien:**
- `README.md` (Ensemble-Abschnitt)
- `examples/ensemble-walkthrough.md` (NEU)
- `prompts/02-execution.md` (aktualisiert)

---

## Implementierungs-Reihenfolge

| # | Phase | Dateien (neu) | Dateien (bearbeitet) | Aufwand |
|---|-------|---------------|---------------------|---------|
| 1 | Superpowers Skills | tdd-rules.md, code-review.md, branch-finish.md | AGENT.md, testing-rules.md | Gering |
| 2 | Template Bridge | template-usage.md, use-template.md | tool-integrations.md, AGENT.md, install.md | Gering |
| 3 | MCP Vollintegration | 5 Client-Configs | mcp-guide.md, install.md | Mittel |
| 4 | Unified Workflow | unified-workflow.md | hook-stop.sh/ps1, AGENT.md | Gering |
| 5 | Doku & Examples | ensemble-walkthrough.md | README.md, prompts/02-execution.md | Mittel |

**Gesamt:** ~18 neue Dateien, ~10 bearbeitete Dateien.

---

## Erfolgskriterien

Nach der Integration:

| Kriterium | Vorher | Nachher |
|-----------|--------|---------|
| TDD erzwungen? | ❌ "when possible" | ✅ RED-GREEN-REFACTOR als harte Regel |
| Review-Gate? | ❌ Fehlt | ✅ code-review.md vor jedem Finish |
| Templates nutzbar? | ❌ Nur Link | ✅ template-usage.md + use-template.md |
| MCP für alle Clients? | ❌ Nur Claude/Qwen | ✅ Alle 8 Clients mit Configs |
| Ensemble sichtbar? | ❌ Nur Tool-Liste | ✅ unified-workflow.md + ensemble-walkthrough.md |
| Hooks vollständig? | ⚠️ Nur pre-command | ✅ pre-command + stop (mit bd prime) |
