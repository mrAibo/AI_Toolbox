# `ai-toolbox` CLI Reference

The `ai-toolbox` command is the unified entry point introduced in v1.5. It is a
thin dispatcher (bash + PowerShell parity) that routes subcommands to scripts
under [`.agent/scripts/`](../.agent/scripts/). The interface is **stable**: a
future binary implementation can replace the shim without breaking call sites.

## Invocation

```bash
# Linux / macOS
./ai-toolbox <subcommand> [flags...]

# Windows
pwsh ./ai-toolbox.ps1 <Subcommand> [-Flags]
```

The shim resolves its own location (following symlinks), so it can be invoked
from anywhere — including via a PATH-installed symlink.

## Subcommand Map

The hard cap is **9 top-level verbs**. Additional functionality is added as
flags or sub-subcommands, never as new top-level verbs (see [the plan](../.agent/memory/architecture-decisions.md) for the rationale).

| Subcommand  | Status | Forwards to                                  | Purpose                                            |
|-------------|--------|----------------------------------------------|----------------------------------------------------|
| `doctor`    | ✅ v1.5 | [doctor.sh](../.agent/scripts/doctor.sh) / [doctor.ps1](../.agent/scripts/doctor.ps1) | Health check across structure, hooks, memory, parity |
| `sync`      | ✅ v1.5 | [sync-task.sh](../.agent/scripts/sync-task.sh) / [sync-task.ps1](../.agent/scripts/sync-task.ps1) | Refresh `.agent/memory/current-task.md` from Beads |
| `setup`     | ✅ v1.5 | [setup.sh](../.agent/scripts/setup.sh) / [setup.ps1](../.agent/scripts/setup.ps1) | Interactive client detection + tool install        |
| `bootstrap` | ✅ v1.5 | [bootstrap.sh](../.agent/scripts/bootstrap.sh) / [bootstrap.ps1](../.agent/scripts/bootstrap.ps1) | Idempotent file generation (silent, CI-safe)       |
| `validate`  | ✅ v1.5 | [validate-toolbox-config.sh](../.agent/scripts/validate-toolbox-config.sh) | Schema-validate `.ai-toolbox/config.json`          |
| `migrate`   | ✅ v1.5 | [migrate.sh](../.agent/scripts/migrate.sh) / [migrate.ps1](../.agent/scripts/migrate.ps1) | Advance `toolbox_version`, run migration scripts   |
| `context`   | 🚧 Phase C | _planned_ `.agent/scripts/context-build.sh`     | Heuristic file selector + `context show` viewer    |
| `simulate`  | 🚧 Phase C | _planned_ `.agent/scripts/run.sh`               | Pipeline dry-run (intent → routing → context → policies) |
| `stats`     | 🚧 Phase C | _planned_ `.agent/scripts/stats.sh`             | Audit-log analyzer                                 |

Phase-C subcommands accept their flags but exit with status 60 and a clear
message until their implementation lands.

## Global Flags

These flags follow the same convention everywhere they are accepted:

| Flag         | Where         | Effect                                                        |
|--------------|---------------|---------------------------------------------------------------|
| `--json`     | doctor, sync, validate, stats, simulate | Machine-readable output per [`schema/doctor-output.schema.json`](../.agent/schema/doctor-output.schema.json) and siblings. Suppresses text output. |
| `--dry-run`  | bootstrap, migrate                       | Show planned filesystem changes without writing.              |
| `--explain`  | doctor                                   | Append a `Fix:` line under each warning/error in text mode.   |
| `--verbose`  | simulate                                 | Show internal pipeline steps (intent, route, context, rules). |
| `--silent`   | setup                                    | Suppress prompts; safe in CI.                                 |

PowerShell uses the same flag names with leading capital and a single dash:
`-Json`, `-DryRun`, `-Explain`, `-Verbose`, `-Silent`.

## Exit Codes

The shim itself uses two:

- `2`  — unknown subcommand
- `60` — missing implementation script (`IO_ERROR`)

All other exit codes are forwarded from the underlying script. Structured codes
are defined in [`error-codes.json`](../.agent/contracts/error-codes.json):

| Code | Meaning |
|------|---------|
| 0    | Success |
| 1    | Doctor: warnings only |
| 2    | Doctor: errors found |
| 10   | `CONFIG_ERROR` |
| 11   | `CONFIG_MISSING_FIELD` |
| 20   | `CONTRACT_VIOLATION` |
| 30   | `DETERMINISM_ERROR` |
| 40   | `MIGRATION_ERROR` |
| 41   | `MIGRATION_VERSION_MISMATCH` |
| 50   | `PLUGIN_ERROR` |
| 51   | `PLUGIN_CONFLICT` |
| 60   | `IO_ERROR` |
| 90   | `INTERNAL_ERROR` |

See [`error-codes.md`](../.agent/contracts/error-codes.md) for full descriptions.

## Examples

```bash
# Quick health check
./ai-toolbox doctor

# Same, with fix instructions for each warning
./ai-toolbox doctor --explain

# CI-friendly machine output
./ai-toolbox doctor --json | jq .status

# What would migrate change?
./ai-toolbox migrate --dry-run

# Validate config, fail CI on schema violations
./ai-toolbox validate

# Get the current toolbox version
./ai-toolbox --version
```

## Stability Contract

The CLI surface is part of the toolbox's public contract. Breaking changes:

- **Patch (1.5.x):** new subcommands, new flags. Existing flags retain meaning.
- **Minor (1.x):** flag *defaults* may change with explicit migration notes.
- **Major (2.x):** subcommand renames or removals.

The shim is intentionally thin so the contract is small. If you find yourself
adding logic to the shim itself rather than to a backing script, that's a smell —
push it into the script so the shim stays diff-free.

## Adding a Subcommand

1. Land the implementation script under [`.agent/scripts/`](../.agent/scripts/) with both `.sh` and `.ps1` parity.
2. Add the route in [`ai-toolbox`](../ai-toolbox) and [`ai-toolbox.ps1`](../ai-toolbox.ps1).
3. Update this table and the help block in both shims.
4. Add a CI smoke test (`./ai-toolbox <new-cmd> --help` should exit 0).

Hard rule: **no more than 9 top-level verbs.** New verbs require removing one
or arguing the case in [`architecture-decisions.md`](../.agent/memory/architecture-decisions.md).
