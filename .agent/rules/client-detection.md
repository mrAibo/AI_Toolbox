# Client Detection Rules (PR5)

This file documents the canonical priority order for AI client detection in AI Toolbox.

---

## Priority Order

```
1. primary_client in .ai-toolbox/config.json   ← wins always
2. Autodetection (command -v, path heuristics) ← fallback only
3. Interactive selection (multiple clients)    ← last resort
4. Selection is written back to config (1)     ← loop closes
```

**Explicit config always beats autodetection.**
Autodetection is a convenience for first-time setup, not a runtime guarantee.

---

## How to Set the Primary Client

Edit `.ai-toolbox/config.json` and set `primary_client`:

```json
{
  "primary_client": "claude"
}
```

Valid values: `claude`, `qwen`, `gemini`, `aider`, `cursor`, `cline`, `windsurf`, `codex`, `opencode`

Set to `null` to re-enable autodetection.

---

## Autodetection Mechanisms (Fallback)

| Client | Detection method |
|--------|-----------------|
| claude | `command -v claude` / `Get-Command claude` |
| qwen | `command -v qwen` / `Get-Command qwen` |
| gemini | `command -v gemini` / `Get-Command gemini` |
| aider | `command -v aider` / `Get-Command aider` |
| cursor | `command -v cursor` OR `~/.cursor/`, `~/.config/cursor/`, `$LOCALAPPDATA\Programs\Cursor` |
| cline | `command -v cline` OR `~/.cline/`, `~/.roocode/`, `~/.vscode/extensions/*cline*` or `*roo*` |
| windsurf | `command -v windsurf` OR `~/.windsurf/`, `~/.config/windsurf/`, `$LOCALAPPDATA\Programs\Windsurf` |

Detection is purely a fallback. It is intentionally defensive — it does NOT decide which
client to use if the explicit config is set.

---

## Behaviour with Multiple Installed Clients

When autodetection finds **more than one** client:

1. The user is prompted to select interactively.
2. The selection is written to `primary_client` in `.ai-toolbox/config.json`.
3. Future runs skip detection entirely and use the saved value.

To reset and re-run detection: set `"primary_client": null` in the config.

---

## Scope of the Primary Client Setting

The `primary_client` value controls:
- Which client's hooks are configured (setup.sh / setup.ps1 Step 7)
- Which MCP servers are installed (Step 6)
- The summary output at the end of setup

It does **not** control:
- Which router files are created (those are created for **all** clients unconditionally)
- `bootstrap.sh` / `bootstrap.ps1` per-client hook configuration (those react to client presence, not primary_client)

---

## Files Involved

| File | Role |
|------|------|
| `.ai-toolbox/config.json` | Source of truth — contains `primary_client` field |
| `.agent/scripts/setup.sh` | Reads + writes `primary_client`; runs autodetect if null |
| `.agent/scripts/setup.ps1` | Same as above, Windows variant |
| `.agent/scripts/bootstrap.sh` | Configures per-client hooks on presence; does not read `primary_client` |
| `.agent/scripts/bootstrap.ps1` | Same as above, Windows variant |

---

## Migration Note (PR5)

Before PR5, `setup.sh` and `setup.ps1` always ran full autodetection on every invocation
and never persisted the result. This caused:

- Unpredictable behaviour when multiple clients are installed
- Silent different selections between runs
- No way to pin a client without editing scripts

After PR5, the first `setup.sh` / `setup.ps1` run writes the selection to config.
All subsequent runs read from config and skip detection. To change clients, edit the
config explicitly — the intent is now auditable and version-controllable.

**Backwards compatibility:** If `.ai-toolbox/config.json` does not exist or
`primary_client` is `null`, behaviour is identical to pre-PR5.
