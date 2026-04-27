# AI Toolbox Error Codes

This is the canonical, human-readable companion to [error-codes.json](error-codes.json).
Every script that emits a structured error MUST use a code defined here.
Adding a new code? Edit `error-codes.json` (single source of truth) and re-document below.

## Why structured errors

Without a fixed registry, scripts emit ad-hoc strings. Tools, dashboards, and AI agents
cannot reliably react to failures, and exit codes collide silently across scripts.

This contract gives every error class:

- a stable identifier (`SCREAMING_SNAKE_CASE`)
- a unique exit code (≥ 10, to avoid colliding with `0`/`1`/`2`)
- a category for grouping
- a fix template for `--explain` output
- the toolbox version it was introduced in

## Emission format

Scripts in `--json` mode emit a single JSON object on stdout:

```json
{
  "error": "CONFIG_ERROR",
  "message": "Missing field: context.max_files",
  "fix": "Add to .ai-toolbox/config.json: { \"context\": { \"max_files\": 5 } }"
}
```

…and exit with the code listed in the registry.

In text mode, scripts print the message + fix and exit with the same code.

## Categories

| Category      | When it applies                                                |
|---------------|----------------------------------------------------------------|
| `config`      | Configuration file is missing, malformed, or violates schema   |
| `contract`    | Hook output diverges from `hook-protocol.json`                 |
| `determinism` | Identical inputs produced different outputs                    |
| `migration`   | `ai-toolbox migrate` cannot advance the toolbox_version        |
| `plugin`      | Plugin manifest invalid, missing, or in conflict               |
| `io`          | Filesystem operation failed                                    |
| `internal`    | Unexpected condition — toolbox bug                             |

## Code reference

| Code                          | Exit | Category    | Description                                                                 |
|-------------------------------|------|-------------|-----------------------------------------------------------------------------|
| `CONFIG_ERROR`                | 10   | config      | Configuration violates schema or is malformed                               |
| `CONFIG_MISSING_FIELD`        | 11   | config      | A required config field is absent                                           |
| `CONTRACT_VIOLATION`          | 20   | contract    | Hook output does not match `hook-protocol.json` for its client              |
| `DETERMINISM_ERROR`           | 30   | determinism | Two identical runs produced different outputs                               |
| `MIGRATION_ERROR`             | 40   | migration   | Migration script missing or failed                                          |
| `MIGRATION_VERSION_MISMATCH`  | 41   | migration   | Recorded `toolbox_version` differs from expected                            |
| `PLUGIN_ERROR`                | 50   | plugin      | Plugin manifest invalid or requires newer toolbox                           |
| `PLUGIN_CONFLICT`             | 51   | plugin      | Conflicting plugins, at least one with `conflict_resolution: fail`          |
| `IO_ERROR`                    | 60   | io          | Filesystem read/write/mkdir failure                                         |
| `INTERNAL_ERROR`              | 90   | internal    | Unexpected condition — should be filed as an issue                          |

## Adding a new code

1. Pick the next free exit code in the appropriate category band:
   - `1x` — config, `2x` — contract, `3x` — determinism, `4x` — migration,
   - `5x` — plugin, `6x` — io, `9x` — internal.
2. Add the entry to `error-codes.json` with the schema-required fields.
3. Re-run `bash .agent/scripts/validate-toolbox-config.sh` (CI also validates).
4. Update this table above.

## Conventions for emitters

- **Always emit the code, never the exit number directly.** Scripts source the
  registry and look up the exit code, so a code rename in JSON propagates to all
  call sites without per-script edits.
- **Fix messages are imperative and actionable.** "Run: …" or "Add … to …",
  not "you should consider possibly …".
- **Use `INTERNAL_ERROR` only as a last resort.** If you find yourself emitting
  it, the right move is usually to add a more specific code instead.
