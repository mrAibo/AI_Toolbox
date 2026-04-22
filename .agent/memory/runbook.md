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

---

## 6. Audit log

The audit log records security-relevant hook decisions and shared-state mutations.

**Location:** `.agent/memory/audit.log` (gitignored via `*.log` — local only, never committed)

**Format:** one line per event — `TIMESTAMP | EVENT | CONTEXT`

```
2026-04-22T10:05:00Z | heavy_cmd_blocked    | tool=python
2026-04-22T10:15:00Z | secret_scan_bypassed | hook=verify-commit
2026-04-22T10:20:00Z | session_handover_written | file=session-handover.md
```

**Recorded events:**

| Event | Trigger | Hook |
|-------|---------|------|
| `heavy_cmd_blocked` | AI tried to run a heavy command without rtk | `hook-pre-command.sh/.ps1` |
| `secret_scan_bypassed` | `SKIP_SECRET_SCAN=true` was set at commit time | `verify-commit.sh/.ps1` |
| `session_handover_written` | Session state written to `session-handover.md` | `hook-stop.sh/.ps1` |

**Reading the log:**
```bash
# Show all entries
cat .agent/memory/audit.log

# Show only bypass events
grep secret_scan_bypassed .agent/memory/audit.log

# Show last 20 entries
tail -20 .agent/memory/audit.log
```

**Retention:** The log is local-only and append-only. There is no automatic rotation.
If it grows large, truncate with: `> .agent/memory/audit.log` (clears while preserving the file).

---

## 7. Common failure paths

### Hook not running
**Symptom:** Heavy commands are not blocked; secret scan bypass is not audited.
**Cause:** Claude Code (or other client) hook is not wired to the hook scripts.
**Fix:** Run `bash .agent/scripts/doctor.sh` to check hook presence and configuration.
Re-run `bash .agent/scripts/setup.sh` or `bash .agent/scripts/bootstrap.sh` to reinstall.

### `lib-audit.sh` not found on source
**Symptom:** `hook-pre-command.sh: lib-audit.sh: No such file or directory`
**Cause:** Script run from a directory other than its own, or partial checkout.
**Fix:** The hook derives its path via `BASH_SOURCE[0]` — this is always correct when
invoked by Claude Code. If invoking manually, use the full path:
`bash /path/to/.agent/scripts/hook-pre-command.sh "cmd"`.

### `sync-task.ps1` exits non-zero
**Symptom:** `[sync-task] bd available but not initialized`
**Cause:** Beads is installed but `bd init` was not run in this repo.
**Fix:** `bd init --mode server` (Windows) or `bd init` (Unix) in the repo root.
Toolbox functions without Beads — this is a warning, not a blocker.

### Handover file growing unbounded
**Symptom:** `.agent/memory/session-handover.md` is very large.
**Cause:** `hook-stop` cap logic (10 entries) may not run if active-session.md is a template stub.
**Fix:** Check that `active-session.md` has real content (not `[Date]` placeholders).
Manually trim: keep the header section + the last 10 `## Session Summary` blocks.

### Secret scan false positive
**Symptom:** Commit blocked on a line that is clearly a placeholder.
**Cause:** Regex matched despite the placeholder filter (e.g., unusual quoting style).
**Fix:** Inspect the flagged line with `git diff --cached`. If safe, bypass explicitly:
```bash
SKIP_SECRET_SCAN=true git commit -m "reason: intentional fixture"
```
The bypass is logged in `audit.log` and visible in shell history.

### `doctor.sh` exits 2 (errors)
**Symptom:** `🔴 N error(s) found — action required`
**Cause:** A required file or directory is missing.
**Fix:** Re-run bootstrap: `bash .agent/scripts/bootstrap.sh` to restore the full structure.
Check `.gitignore` — required gitignore entries missing is a common cause.
