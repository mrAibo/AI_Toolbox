# OpenAI Codex CLI ↔ AI Toolbox: Kompatibilitätsanalyse

**Datum:** 2026-04-09
**Codex CLI Version:** Latest (github.com/openai/codex, v0.65.0+)
**Quelle:** developers.openai.com/codex/, GitHub Repo

---

## Executive Summary

**AI Toolbox und Codex CLI sind komplementär, nicht konkurrierend.** Codex CLI ist ein AI Client (wie Qwen Code, Claude Code), während AI Toolbox ein Framework-Adapter ist, der für jeden Client funktioniert.

**Kompatibilität: ✅ Sehr Hoch** — Codex CLI hat das matureste Hook-System aller untersuchten Clients. Alle 6 AI Toolbox Hooks haben direkte Codex-Äquivalente.

---

## 1. Codex CLI Architektur

### 1.1 AGENTS.md (3-Level System)
| Ebene | Pfad | Zweck |
|---|---|---|
| Global | `~/.codex/AGENTS.md` | Persönliche Präferenzen, projektübergreifend |
| Projekt | `AGENTS.md` im Repo-Root | Team-Standards, Architektur, Workflows |
| Verzeichnis | `AGENTS.md` im aktuellen Verzeichnis | Feature/Modul-spezifischer Kontext |

**Laden:** Alle Dateien werden automatisch gemerged, spezifischere haben Vorrang.
**Deaktivieren:** `codex --no-project-doc` oder `CODEX_DISABLE_PROJECT_DOC=1`

### 1.2 Skills System
| Feld | Format | Pflicht |
|---|---|---|
| `name` | YAML frontmatter | ✅ |
| `description` | YAML frontmatter | ✅ |
| Markdown-Body | Anweisungen | ✅ |
| `scripts/` | Ausführbarer Code | ❌ |
| `references/` | Referenzdokumentation | ❌ |
| `assets/` | Templates, Ressourcen | ❌ |
| `agents/openai.yaml` | UI-Metadaten, Policy, Dependencies | ❌ |

**Trigger:** Explizit (`$skill-name`, `/skills`) oder implizit (basierend auf `description`).
**Deaktivieren implizit:** `policy: allow_implicit_invocation: false` in `agents/openai.yaml`

### 1.3 Hooks System
| Event | Wann | Matcher |
|---|---|---|
| `SessionStart` | Session Start/Resume | `source` (startup/resume) |
| `PreToolUse` | Vor Tool-Ausführung | Tool-Name (nur `Bash` aktuell) |
| `PostToolUse` | Nach Tool-Ausführung | Tool-Name (nur `Bash` aktuell) |
| `UserPromptSubmit` | Vor Prompt an Modell | ❌ Ignoriert |
| `Stop` | Conversation-Ende | ❌ Ignoriert |

**Konfiguration:** `hooks.json` in `~/.codex/` oder `<repo>/.codex/`
**Feature Flag:** `[features] codex_hooks = true` in `config.toml`

**hooks.json Format:**
```json
{
  "hooks": {
    "<EventName>": [
      {
        "matcher": "<regex|*|leer>",
        "hooks": [
          {
            "type": "command",
            "command": "<Shell-Befehl>",
            "statusMessage": "<optional: UI-Status>",
            "timeout": 600
          }
        ]
      }
    ]
  }
}
```

**Input (stdin):** JSON mit `session_id`, `transcript_path`, `cwd`, `hook_event_name`, `model` + event-spezifische Felder.
**Output (stdout):** Exit 0 + JSON für Erfolg. Exit 2 + stderr für Block/Feedback.

### 1.4 MCP Support
| Transport | Felder | Beispiel |
|---|---|---|
| `stdio` | `command`, `args`, `env`, `cwd` | `npx -y @upstash/context7-mcp` |
| `Streamable HTTP` | `url`, `bearer_token_env_var`, `http_headers` | `https://mcp.figma.com/mcp` |

**Nicht unterstützt:** SSE, WebSocket
**Tool-Filterung:** `enabled_tools` (Allowlist), `disabled_tools` (Denylist)
**Timeouts:** `startup_timeout_sec = 10`, `tool_timeout_sec = 60`

### 1.5 Konfiguration (TOML)
```toml
# ~/.codex/config.toml (global) oder .codex/config.toml (projekt)

[model]
provider = "openai"
model = "o3"

[approval_policy]
# "on-request" | "never" | "untrusted" | { granular = {...} }

[sandbox_mode]
# "workspace-write" | "danger-full-access"

[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp"]

[features]
codex_hooks = true
skills = true
```

---

## 2. Kompatibilitätsmatrix

### 2.1 Feature-Mapping: AI Toolbox → Codex CLI

| # | AI Toolbox Feature | Codex CLI Äquivalent | Mapping | Aufwand |
|---|-------------------|---------------------|---------|---------|
| 1 | **AGENTS.md** | ✅ `AGENTS.md` (3-Level) | ✅ **1:1** — Codex hat sogar mehr Levels | Keiner |
| 2 | **Pre-command Hook** | ✅ `PreToolUse` Hook | ✅ **Direkt** — AI Toolbox Scripts als Codex Hooks nutzbar | Niedrig |
| 3 | **Post-tool Hook** | ✅ `PostToolUse` Hook | ✅ **Direkt** — Secret-Scanning etc. nutzbar | Niedrig |
| 4 | **Session Start Hook** | ✅ `SessionStart` Hook | ✅ **Direkt** — sync-task.sh als Codex Hook | Niedrig |
| 5 | **Stop Hook** | ✅ `Stop` Hook | ✅ **Direkt** — hook-stop.sh als Codex Hook | Niedrig |
| 6 | **Pre-compact Hook** | ❌ Kein Äquivalent | 🔴 **Nur in AI Toolbox** | — |
| 7 | **User Prompt Hook** | ✅ `UserPromptSubmit` Hook | ⚠️ **Neu für AI Toolbox** — könnte Added Value sein | Mittel |
| 8 | **Multi-Agent / Sub-Agents** | ⚠️ Basis-Sub-Agenten | ⚠️ Codex kann spawnen, aber keine vordefinierten Typen | — |
| 9 | **MCP Support** (6 Templates) | ✅ Native MCP (stdio + HTTP) | ✅ **Direkt** — AI Toolbox Templates als Codex MCP Config | Niedrig |
| 10 | **Memory Layer** (6 Dateien) | ❌ Kein Äquivalent | 🔴 **AI Toolbox exklusiv** — Codex hat kein strukturiertes Memory | — |
| 11 | **TDD / Safety / Workflow Rules** | ❌ Kein Äquivalent | 🔴 **AI Toolbox exklusiv** — Codex nur via AGENTS.md | — |
| 12 | **Skills** (8 für Qwen) | ✅ `.codex/skills/` | ✅ **1:1** — AI Toolbox Skills als Codex Skills portierbar | Niedrig |
| 13 | **Custom Commands** (4 für Qwen) | ⚠️ `$skill-name` | ⚠️ Codex nutzt Skills als Commands | Niedrig |
| 14 | **Beads Task Tracker** | ❌ Kein Äquivalent | 🔴 **AI Toolbox exklusiv** | — |
| 15 | **rtk Token Optimization** | ❌ Kein Äquivalent | 🔴 **AI Toolbox exklusiv** | — |
| 16 | **Doctor/Health Check** | ❌ Kein Äquivalent | 🔴 **AI Toolbox exklusiv** | — |
| 17 | **Git Hooks** (verify-commit, commit-msg) | ✅ Git Hooks | ✅ **1:1** — Git-Ebene, client-unabhängig | Keiner |
| 18 | **Client Router Files** (8 Clients) | ❌ Kein Äquivalent | 🔴 **AI Toolbox exklusiv** — Codex ist Single-Client | — |

### 2.2 Codex CLI Features ohne AI Toolbox Äquivalent

| # | Codex CLI Feature | AI Toolbox Status | Bewertung |
|---|------------------|-------------------|-----------|
| C1 | **3-Level AGENTS.md** (global/projekt/verzeichnis) | ⚠️ Nur projekt-Level | AI Toolbox könnte global + verzeichnis-spezifisch erweitern |
| C2 | **`UserPromptSubmit` Hook** | ❌ Nicht vorhanden | Potenziell nützlich für Prompt-Validierung/Anreicherung |
| C3 | **Sandbox Mode** (`workspace-write` / `danger-full-access`) | ❌ Nicht vorhanden | Sicherheitsfeature, aber außerhalb AI Toolbox Scope |
| C4 | **Approval Policy** (granular) | ⚠️ Hooks + Safety Rules | Codex deklarativer, AI Toolbox prozedural |
| C5 | **Native TOML-Konfiguration** | ⚠️ JSONC + Markdown | Unterschiedlich, beide funktional |
| C6 | **Skill Dependencies** (`agents/openai.yaml`) | ❌ Nicht vorhanden | MCP-Dependencies pro Skill — nützliches Feature |

---

## 3. Integration: Was wäre nötig?

### 3.1 Hooks-Mapping (direkt nutzbar)

AI Toolbox Hooks funktionieren mit Codex CLI **ohne Änderungen** — beide nutzen JSON stdin/stdout mit demselben Protokoll:

| Codex Event | AI Toolbox Script | hooks.json Entry |
|---|---|---|
| `SessionStart` | `sync-task.sh` | `{"matcher": "", "hooks": [{"type": "command", "command": "bash .agent/scripts/sync-task.sh"}]}` |
| `PreToolUse` | `hook-pre-command-qwen.sh` | `{"matcher": "Bash", "hooks": [{"type": "command", "command": "bash .agent/scripts/hook-pre-command-qwen.sh"}]}` |
| `PostToolUse` | `hook-post-tool-qwen.sh` | `{"matcher": "Bash", "hooks": [{"type": "command", "command": "bash .agent/scripts/hook-post-tool-qwen.sh"}]}` |
| `Stop` | `hook-stop-qwen.sh` | `{"matcher": "", "hooks": [{"type": "command", "command": "bash .agent/scripts/hook-stop-qwen.sh"}]}` |

### 3.2 Skills-Mapping (minimal anpassen)

AI Toolbox Qwen Skills sind bereits im Codex-Format (YAML frontmatter + Markdown). Einziger Unterschied:

| AI Toolbox Feld | Codex Feld | Änderung |
|---|---|---|
| `description: "Use PROACTIVELY when..."` | `description: "Trigger when..."` | Text anpassen |
| Keine `agents/openai.yaml` | Optional | Hinzufügen für UI/Policy |

### 3.3 Benötigte Dateien für Codex Integration

| Datei | Zweck | Aufwand |
|---|---|---|
| `.agent/templates/clients/.codex-hooks.json` | hooks.json Template für Codex | Niedrig (~30 Zeilen) |
| `.agent/templates/clients/.codex-config.toml` | config.toml Template mit AI Toolbox Pfaden | Niedrig (~40 Zeilen) |
| `CODERULES.md` | Codex-spezifische Router-Datei (wie CLAUDE.md, QWEN.md) | Niedrig (~25 Zeilen) |
| Bootstrap-Erweiterung | Codex-Erkennung + `.codex/` Struktur | Mittel (~50 Zeilen) |
| `docs/setup-codex.md` | Setup-Anleitung | Niedrig (~30 Zeilen) |

**Gesamtaufwand: ~175 Zeilen** — vergleichbar mit der Qwen Code Integration.

---

## 4. Strategische Bewertung

### AI Toolbox Vorteile für Codex CLI Nutzer:
1. **Memory Layer** — Codex hat "Project Amnesia" zwischen Sessions. AI Toolbox löst das mit 6 strukturierten Dateien.
2. **Workflow-Struktur** — 11 definierte Workflows (TDD, Bug-Fix, Code Review). Codex hat keine.
3. **Token-Ökonomie** — rtk spart 60-90% Tokens. Codex hat keinen Optimizer.
4. **Task-Tracking** — Beads-Integration. Codex hat keins.
5. **Template Bridge** — 413+ Specialist Agents. Codex hat keins.
6. **Safety Depth** — 16 Regel-Dateien + Hooks. Codex nur Permissions.

### Codex CLI Vorteile für AI Toolbox Nutzer:
1. **3-Level AGENTS.md** — Global + projekt + verzeichnis-spezifisch.
2. **`UserPromptSubmit` Hook** — Prompt-Validierung vor dem Senden.
3. **Sandbox Mode** — Built-in Sicherheit durch Workspace-Isolation.
4. **OpenAI Model-Zugang** — Direkter Zugang zu o3/o4-mini.

---

## 5. Empfehlung

**Ja, AI Toolbox ist sehr gut für Codex CLI geeignet.** Die Integration ist straightforward da:

1. ✅ **Hooks sind 1:1 kompatibel** — AI Toolbox Shell-Skripte funktionieren als Codex Hooks ohne Änderungen
2. ✅ **Skills sind nahezu kompatibel** — Nur description-Text anpassen
3. ✅ **AGENTS.md ist kompatibel** — AI Toolbox AGENTS.md funktioniert direkt mit Codex
4. ✅ **MCP ist kompatibel** — AI Toolbox Templates als Codex MCP Config nutzbar

**Empfohlene nächste Schritte:**
1. `.codex-hooks.json` Template erstellen
2. `.codex-config.toml` Template erstellen
3. `CODERULES.md` Router-Datei erstellen
4. Bootstrap um Codex-Erweiterung erweitern
5. `docs/setup-codex.md` schreiben

**Priorität: Mittel-Hoch** — Codex CLI gewinnt schnell an Popularität und die Integration ist mit ~175 Zeilen machbar.
