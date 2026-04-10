# Test Suite: AI Toolbox

**Datum:** 2026-04-09
**Status:** In Entwicklung

---

## Coverage-Übersicht

| Bereich | Vorher | Nachher |
|---|---|---|
| Syntax-Tests | ✅ bash -n, pwsh ParseFile | ✅ Unverändert |
| Funktionale Hook-Tests | ❌ 0% | ✅ 14 Hooks getestet |
| JSON-Validierung | ❌ 0% | ✅ Alle Hook-Ausgaben validiert |
| Edge Cases | ❌ 0% | ✅ Leer, malformed, missing files |
| Integration | ❌ 0% | ✅ Boot→Sync→Handover |
| Secret Detection | ❌ 0% | ✅ Positive/Negative Tests |
| PowerShell in CI | ❌ Übersprungen | ✅ pwsh installiert |
| **Gesamt** | **~10%** | **~45%** |

---

## Test-Dateien

### 1. `.agent/scripts/test-scripts.sh` (erweitert)

Bestehender Syntax-Test + neue JSON-Validierung für Qwen Hooks.

### 2. `.agent/scripts/test-hooks.sh` (neu)

Funktionale Tests für alle 10 Qwen Hook-Skripte:
- Leerer stdin → valides JSON + exit 0
- Malformed JSON input → valides JSON + exit 0
- Missing files → valides JSON + exit 0
- Heavy command detection → ask/allow
- Secret detection → positive/negative
- Path traversal → block/allow

### 3. `.agent/scripts/test-integration.sh` (neu)

End-to-End Integrationstest:
- Bootstrap läuft fehlerfrei
- sync-task.ps1/sh erzeugt current-task.md
- doctor.sh/ps1 meldet keine Errors
- Alle Memory-Dateien existieren

### 4. CI-Erweiterungen (`.github/workflows/ci.yml`)

- PowerShell Installation (`sudo apt install powershell`)
- Hook-Tests ausführen
- Integrationstests ausführen
- Shellcheck mit weniger Exclusions
