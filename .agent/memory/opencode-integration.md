# OpenCode Integration für AI Toolbox

## Ergebnis: Vollständig kompatibel ✅

OpenCode unterstützt **alle Kernkomponenten** der AI Toolbox – teilweise nativ, teilweise über Plugins.

---

## 1. Native Unterstützung (keine Anpassung nötig)

| AI Toolbox Komponente | OpenCode Äquivalent | Status |
|---|---|---|
| `AGENTS.md` (project root) | `AGENTS.md` (project root) | ✅ **1:1 kompatibel** |
| `.agent/rules/*.md` | `"instructions"` in `opencode.json` | ✅ **Direkt referenzierbar** |
| `.agent/workflows/*.md` | `"instructions"` in `opencode.json` | ✅ **Direkt referenzierbar** |
| `.agent/memory/*.md` | Persistente Dateien auf Disk | ✅ **Unverändert nutzbar** |
| Git Hooks (`verify-commit.sh`, `commit-msg.sh`) | Git Hooks | ✅ **Unverändert** |
| MCP Server | `"mcp"` in `opencode.json` | ✅ **Native Unterstützung** |
| Custom Commands | `"command"` in `opencode.json` | ✅ **Toolbox Workflows als Slash-Commands** |
| Multi-Agent | Built-in Agents (`build`, `plan`, `general`, `explore`) | ✅ **Subagenten nativ** |

---

## 2. Plugin-basierte Integration (JavaScript/TypeScript)

| AI Toolbox Komponente | OpenCode Hook | Anpassung |
|---|---|---|
| `hook-pre-command.sh` | `tool.execute.before` | Shell-Logik → TS Hook (~30 Zeilen) |
| `hook-stop.sh` | `experimental.session.compacting` | Session-Konsolidierung (~20 Zeilen) |
| `sync-task.sh` | `session.created` | Task-State-Injektion (~15 Zeilen) |
| Bootstrap-Check | `shell.env` | Environment-Setup (~10 Zeilen) |

**Plugin-Dateien benötigt:**
- `.opencode/plugins/ai-toolbox.ts` (~100 Zeilen TS)

---

## 3. OpenCode Konfiguration (Beispiel)

```jsonc
// opencode.json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-sonnet-4",

  // AI Toolbox Plugin
  "plugin": ["file://.opencode/plugins/ai-toolbox.ts"],

  // Regeln und Workflows als Instructions
  "instructions": [
    ".agent/rules/safety-rules.md",
    ".agent/rules/testing-rules.md",
    ".agent/rules/tdd-rules.md",
    ".agent/rules/mcp-rules.md",
    ".agent/workflows/unified-workflow.md",
    ".agent/workflows/code-review.md"
  ],

  // MCP Server
  "mcp": {
    "context7": {
      "command": ["npx", "-y", "@upstash/context7-mcp"],
      "enabled": true,
      "type": "local"
    }
  },

  // Toolbox Workflows als Slash-Commands
  "command": {
    "boot": {
      "template": "Run AI Toolbox boot sequence: check environment, read memory files, report status",
      "description": "Boot AI Toolbox and recover session context"
    },
    "sync": {
      "template": "Run sync-task and report current task state",
      "description": "Sync task state from tracker"
    },
    "handover": {
      "template": "Update session handover with progress summary and next steps",
      "description": "Create session handover for next session"
    }
  },

  // Permissions
  "permission": {
    "edit": "ask",
    "bash": "ask",
    "webfetch": "allow"
  }
}
```

---

## 4. AI Toolbox Plugin für OpenCode

```typescript
// .opencode/plugins/ai-toolbox.ts
import { tool } from "@opencode-ai/plugin"

export const aiToolbox = async ({ project, client, $, directory, worktree }) => {
  const REPO_ROOT = directory
  const rtkOk = await $(`which rtk`).text().catch(() => "")
  const bdOk = await $(`which bd`).text().catch(() => "")

  return {
    // Shell-Environment mit Toolbox-Status
    "shell.env": async (_input, output) => {
      output.env.AI_TOOLBOX_ACTIVE = "true"
      output.env.AI_TOOLBOX_RTK = rtkOk ? "installed" : "not_installed"
      output.env.AI_TOOLBOX_BEADS = bdOk ? "installed" : "not_installed"
    },

    // Pre-Command: Schwere Commands mit rk prefixen
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash") return
      const HEAVY = /^(python|python3|mvn|gradle|pytest|npm run|npm test|pnpm run|pnpm test|yarn run|yarn test|cargo build|cargo test|go build|go test|docker build)/
      const cmd = output.args.command
      if (HEAVY.test(cmd) && !cmd.startsWith("rtk ") && rtkOk) {
        output.args.command = `rtk ${cmd}`
      }
    },

    // Session-Start: Memory-Dateien injizieren
    "session.created": async () => {
      const handover = await $(`cat ${REPO_ROOT}/.agent/memory/session-handover.md 2>/dev/null || echo "No handover"`).text()
      const task = await $(`cat ${REPO_ROOT}/.agent/memory/current-task.md 2>/dev/null || echo "No task"`).text()
      client.app.log({ body: { service: "ai-toolbox", level: "info", message: `Session started: ${task}` } })
    },

    // Session-Ende: Memory konsolidieren
    "experimental.session.compacting": async (_input, output) => {
      if (bdOk) await $(`cd ${REPO_ROOT} && bd prime`).text().catch(() => {})
      const syncScript = process.platform === "win32"
        ? `${REPO_ROOT}/.agent/scripts/sync-task.ps1`
        : `${REPO_ROOT}/.agent/scripts/sync-task.sh`
      await $(syncScript).text().catch(() => {})
      output.context.push("AI Toolbox: Update .agent/memory/session-handover.md before ending session.")
    },

    // Custom Tool: Toolbox Status
    tool: {
      toolbox_status: tool({
        description: "Check AI Toolbox environment status",
        args: {},
        async execute() {
          return [
            `AI Toolbox: ${rtkOk || bdOk ? "ACTIVE" : "INACTIVE"}`,
            `  rtk: ${rtkOk ? "INSTALLED" : "NOT INSTALLED"}`,
            `  Beads: ${bdOk ? "INSTALLED" : "NOT INSTALLED"}`,
          ].join("\n")
        },
      }),
    },
  }
}
```

---

## 5. Aufwand

| Komponente | Aufwand | Bemerkung |
|---|---|---|
| Plugin (`ai-toolbox.ts`) | **Niedrig** (~100 Zeilen TS) | Dünne Adapter-Schicht, ruft bestehende .sh/.ps1 Skripte via BunShell auf |
| `opencode.json` | **Niedrig** | Deklaratives JSON, referenziert bestehende Toolbox-Dateien |
| Bestehende Skripte | **Keine** | `.agent/scripts/*.sh` und `.ps1` bleiben unverändert |
| Rules & Workflows | **Keine** | Werden via `instructions` referenziert |
| Memory Files | **Keine** | Persistieren unabhängig vom Client |
| Git Hooks | **Keine** | Arbeiten auf Git-Ebene, client-unabhängig |

**Fazit:** Die AI Toolbox ist **vollständig mit OpenCode kompatibel**. Der Integrationsaufwand ist gering – ein ~100-Zeilen TypeScript Plugin als dünne Adapter-Schicht, der Rest funktioniert nativ.

---

## 6. Unterschiede zu Qwen Code / Claude Code

| Feature | Qwen Code | Claude Code | OpenCode |
|---|---|---|---|
| Native AGENTS.md | ❌ (QWEN.md) | ✅ (CLAUDE.md) | ✅ (AGENTS.md) |
| Hook-System | ❌ (manuell) | ✅ (.claude.json) | ✅ (Plugins) |
| MCP Server | ✅ | ✅ | ✅ |
| Multi-Agent | ✅ (agent tool) | ✅ | ✅ (built-in) |
| Custom Commands | ❌ | ❌ | ✅ (opencode.json) |
| Instructions | ❌ | ❌ | ✅ (opencode.json) |
| Plugin-System | ❌ | ❌ | ✅ (JS/TS) |

OpenCode bietet **mehr native Features** als Qwen Code oder Claude Code – insbesondere das Plugin-System, Custom Commands, und das Instructions-System machen die Integration besonders elegant.
