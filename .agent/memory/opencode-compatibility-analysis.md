# OpenCode (anomalyco/opencode) ↔ AI Toolbox: Kompatibilitätsanalyse

**Datum:** 2026-04-09
**OpenCode Version:** Latest (github.com/anomalyco/opencode)

---

## Executive Summary

**AKTUELLER STATUS: ❌ KEINE OpenCode-Integration vorhanden.**

Im Gegensatz zu Qwen Code, Claude Code und Codex CLI gibt es **NULL** Dateien, Templates oder Dokumentation für OpenCode im AI Toolbox Projekt.

**Kompatibilität: ✅ Hoch** — OpenCode hat ein ausgereiftes Plugin- und Skills-System.

---

## 1. OpenCode CLI Architektur

### 1.1 Konfiguration (`opencode.json` / `opencode.jsonc`)
| Ebene | Pfad | Zweck |
|---|---|---|
| Global | `~/.config/opencode/opencode.json` | Persönliche Einstellungen |
| Projekt | `./opencode.json` im Projektroot | Projekt-spezifische Konfiguration |
| Format | JSON oder JSONC (mit Kommentaren) | |

### 1.2 Konfigurations-Sektionen
| Sektion | Zweck | AI Toolbox Mapping |
|---|---|---|
| `provider` | LLM-Provider (OpenAI, Anthropic, etc.) | Nicht relevant (client-agnostisch) |
| `model` | Standard-Modell | Nicht relevant |
| `agents` | Custom Agent-Definitionen | → AI Toolbox Sub-Agenten |
| `commands` | Custom Slash-Commands | → AI Toolbox Commands |
| `modes` | Betriebsmodi (build, plan, etc.) | → AI Toolbox Tiers |
| `plugins` | Plugin-Liste (npm-Pakete) | → AI Toolbox als Plugin |
| `skills` | Skill-Definitionen | → AI Toolbox Skills |
| `tools` | Tool-Konfiguration | → AI Toolbox rtk/Beads |
| `mcp` | MCP Server Konfiguration | → AI Toolbox MCP Templates |
| `permissions` | Berechtigungen (edit, bash, etc.) | → AI Toolbox Safety Rules |
| `keybinds` | Tastenkombinationen | Nicht relevant |
| `themes` | UI-Themes | Nicht relevant |

### 1.3 Skills-System
| Feld | Format | Pflicht |
|---|---|---|
| `name` | String | ✅ |
| `description` | String | ✅ |
| `SKILL.md` | Markdown mit Anweisungen | ✅ |
| Verzeichnis | `.opencode/skills/<name>/` oder global | ✅ |
| Trigger | Implizit (basierend auf description) | ✅ |

**Skill-Format ist kompatibel mit AI Toolbox Qwen Skills** (YAML frontmatter + Markdown).

### 1.3 Hooks-System
| Hook-Typ | Wann | Zweck |
|---|---|---|
| `event` | Session/Message/File-Edit Events | Real-time Benachrichtigungen |
| `config` | Beim Config-Laden | Konfiguration anpassen |
| `tool` | Vor/Nach Tool-Ausführung | Tool-Verhalten modifizieren |

**Weniger granular als Codex/Qwen** — kein PreToolUse/PostToolUse als separate Events, aber tool-Hooks können ähnlich genutzt werden.

### 1.4 Plugin-System
- Plugins sind npm-Pakete (`@opencode-ai/plugin`)
- Können Custom Tools, Hooks, Skills, Commands hinzufügen
- Version-pinning: `"plugin": ["my-plugin@0.0.3"]`
- Plugins laufen im OpenCode-Prozess (keine externen Prozesse)

### 1.5 Sub-Agenten
- Built-in: `@general` für komplexe Suchen/Multi-Step-Aufgaben
- Custom Agents in `opencode.json` definierbar
- Keine festen Agent-Typen wie AI Toolbox (Explore, general-purpose)

### 1.6 MCP Support
- Konfiguration in `opencode.json` unter `"mcp"`-Sektion
- Ähnlich wie Codex CLI (stdio + HTTP)
- Tool-spezifische Permissions möglich

---

## 2. Kompatibilitätsmatrix

| # | AI Toolbox Feature | OpenCode Äquivalent | Status | Aufwand |
|---|-------------------|---------------------|--------|---------|
| 1 | **AGENTS.md** | ✅ `AGENTS.md` (via `/init`) | ✅ **1:1** | Keiner |
| 2 | **Pre-command Hook** | ⚠️ Tool-Hooks | ⚠️ **Teilweise** | Mittel |
| 3 | **Post-tool Hook** | ⚠️ Tool-Hooks | ⚠️ **Teilweise** | Mittel |
| 4 | **Session Start Hook** | ⚠️ Event-Hooks | ⚠️ **Teilweise** | Mittel |
| 5 | **Stop Hook** | ⚠️ Event-Hooks | ⚠️ **Teilweise** | Mittel |
| 6 | **Multi-Agent / Sub-Agents** | ✅ `@general` + custom agents | ⚠️ **Basis** | Niedrig |
| 7 | **MCP Support** | ✅ Native MCP | ✅ **Direkt** | Niedrig |
| 8 | **Skills** (8 für Qwen) | ✅ `.opencode/skills/` | ✅ **1:1** | Niedrig |
| 9 | **Custom Commands** (4 für Qwen) | ✅ `commands` in opencode.json | ✅ **Direkt** | Niedrig |
| 10 | **Memory Layer** (6 Dateien) | ❌ Kein Äquivalent | 🔴 **AI Toolbox exklusiv** | — |
| 11 | **TDD / Safety / Workflow Rules** | ❌ Kein Äquivalent | 🔴 **AI Toolbox exklusiv** | — |
| 12 | **Template Bridge** (413+ Templates) | ❌ Kein Äquivalent | 🔴 **AI Toolbox exklusiv** | — |
| 13 | **Beads Task Tracker** | ❌ Kein Äquivalent | 🔴 **AI Toolbox exklusiv** | — |
| 14 | **rtk Token Optimierung** | ❌ Kein Äquivalent | 🔴 **AI Toolbox exklusiv** | — |
| 15 | **Doctor/Health Check** | ❌ Kein Äquivalent | 🔴 **AI Toolbox exklusiv** | — |
| 16 | **Git Hooks** | ✅ Git-Ebene | ✅ **1:1** | Keiner |
| 17 | **Client Router Files** | ❌ Kein Äquivalent | 🔴 **AI Toolbox exklusiv** | — |
| 18 | **Plugin-System** | ✅ npm-basiert | ⚠️ **AI Toolbox könnte Plugin sein** | Hoch |

---

## 3. Was fehlt: OpenCode Integration

### 3.1 Benötigte Dateien

| Datei | Zweck | Aufwand |
|---|---|---|
| `.agent/templates/clients/opencode-config.json` | opencode.json Template mit AI Toolbox Integration | Niedrig (~40 Zeilen) |
| `.agent/templates/clients/opencode-config.toml` | Falls TOML-Option existiert | Niedrig (~30 Zeilen) |
| `OPENCODERULES.md` | OpenCode-spezifische Router-Datei | Niedrig (~25 Zeilen) |
| `docs/setup-opencode.md` | Setup-Anleitung für OpenCode | Niedrig (~40 Zeilen) |
| Bootstrap-Erweiterung | OpenCode-Erkennung + `.opencode/` Struktur | Mittel (~50 Zeilen) |
| `.agent/templates/mcp/mcp-opencode.json` | MCP Config für OpenCode | Niedrig (~20 Zeilen) |

### 3.2 Herausforderungen

| Challenge | Beschreibung | Lösung |
|---|---|---|
| Hooks weniger granular | OpenCode hat nur event/config/tool hooks, nicht PreToolUse/PostToolUse | AI Toolbox Hooks als plugin tool registrieren |
| Kein natives Shell-Hook-System | OpenCode Hooks laufen im Prozess, nicht als externe Skripte | AI Toolbox als Plugin entwickeln ODER commands nutzen |
| Plugin-System erfordert npm-Paket | AI Toolbox ist kein npm-Paket | Alternative: Skills + Commands ohne Plugin nutzen |

### 3.3 Empfohlener Integrations-Ansatz

**Option A: Skills + Commands (einfach, kein Plugin nötig)**
- AI Toolbox Skills als OpenCode Skills portieren
- AI Toolbox Commands als OpenCode Commands definieren
- MCP Server über opencode.json konfigurieren
- Hooks über event-Hooks lösen (eingeschränkt)

**Option B: Vollständiges Plugin (aufwändiger, aber vollständig)**
- AI Toolbox als `@ai-toolbox/opencode-plugin` npm-Paket
- Volle Hook-Integration
- Custom Tools für rtk und Beads
- Alle Skills und Commands eingebaut

**Empfehlung: Option A zuerst** — schnell umsetzbar (~150 Zeilen), Plugin später als Enhancement.

---

## 4. Integration: Was wäre nötig? (~205 Zeilen)

| Datei | Zweck | Zeilen |
|---|---|---|
| `.agent/templates/clients/opencode-config.json` | opencode.json mit AI Toolbox Integration | ~50 |
| `.agent/templates/mcp/mcp-opencode.json` | MCP Config Template | ~20 |
| `OPENCODERULES.md` | OpenCode Router-Datei | ~25 |
| `docs/setup-opencode.md` | Setup-Anleitung | ~50 |
| Bootstrap-Erweiterung (sh + ps1) | OpenCode-Erkennung + Struktur | ~60 |

---

## 5. Strategische Bewertung

### OpenCode Vorteile für AI Toolbox Nutzer:
1. **Plugin-System** — AI Toolbox könnte als Plugin verteilt werden
2. **JSONC Konfiguration** — Kommentare erlaubt, einfacher zu pflegen
3. **Built-in @general Sub-Agent** — Kein extra Setup nötig

### AI Toolbox Vorteile für OpenCode Nutzer:
1. **Memory Layer** — OpenCode hat kein strukturiertes Memory
2. **Workflow-Struktur** — 11 definierte Workflows
3. **Token-Ökonomie** — rtk spart 60-90%
4. **Task-Tracking** — Beads-Integration
5. **Template Bridge** — 413+ Specialist Agents
6. **Multi-Client** — OpenCode-Nutzer können auch andere Clients nutzen

---

## 6. Empfehlung

**Ja, OpenCode-Integration ist sinnvoll.** Der Aufwand ist mit ~205 Zeilen moderat. Die Integration erfolgt primär über Skills + Commands (Option A), Plugin später als Enhancement.

**Soll ich die OpenCode Integration jetzt erstellen?**
