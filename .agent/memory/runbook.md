# Runbook

This file stores recurring operational knowledge for the repository.
Use it for setup notes, recovery steps, repeated commands, and maintenance procedures.

## 1. Startup procedure
1. Read `AGENT.md`
2. Read `.agent/memory/architecture-decisions.md`
3. Read `.agent/memory/integration-contracts.md`
4. Read `.agent/memory/session-handover.md` if present
5. Check Beads for current task state (`.agent/memory/current-task.md`)
6. Continue with the next ready task

## 2. Verification procedure
- Run tests if tests exist
- If no tests exist, run the most relevant verification command
- Inspect the actual output
- Do not mark work as complete without verification

## 3. Terminal procedure
- Prefer concise command output
- Use `rtk` for heavy test/build commands where available (e.g. `rtk test`, `rtk build`)
- Avoid raw long log dumps into model context

## 4. Memory maintenance
- Record architecture changes in `architecture-decisions.md`
- Record integration expectations in `integration-contracts.md`
- Record current unfinished state in `session-handover.md`

## 5. Config and template validation

### Validated artifacts
| Artifact | Validator | What is checked |
|---|---|---|
| `.ai-toolbox/config.json` | `validate-toolbox-config.sh` + `generate_client_files.py` | JSON parse, required keys (`_meta`, `clients`, `tiers`), tier values, `primary_client` consistency |
| `.agent/config/client-capabilities.json` | `validate-client-capabilities.sh` | JSON parse, `clients` key, tier values (deprecated file — kept for compatibility) |
| `**/*.json` (all) | CI `Validate JSON files` step | JSON parseability |
| `**/*.toml` (all) | CI `Validate TOML files` step | TOML parseability |
| `.agent/templates/mcp/*.json` | `test-mcp-schema.sh` | MCP structure, server definitions, pinned versions |
| `.agent/memory/adrs/*.md` | `validate-adr.sh` | Required fields, status values, ISO-8601 date |

### ADR metadata convention
Required fields: `Status`, `Date`, `Context`, `Decision`, `Consequences`
Valid Status values: `proposed` | `accepted` | `rejected` | `replaced` | `deprecated`
Date format: ISO-8601 (`YYYY-MM-DD`)
Optional fields: `Deciders`, `Rejected alternatives`
Field format: `- **Field:** value` (bold label, consistent with existing ADR-0000)

### On validation failure
- Shell validators print `FAIL <file>: <reason>` and exit 1 — CI blocks the PR.
- `generate_client_files.py` prints `CONFIG ERROR: <reason>` to stderr and exits 2 — `--check` and `--sync` both abort without writing any file.
