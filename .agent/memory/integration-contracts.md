# Integration Contracts

Documents external tool expectations, version assumptions, and fallback behavior.
Load this file before any API/integration work.

---

## 1. rtk (Rust Token Killer)

| Property | Value |
|----------|-------|
| Status | **Required** for heavy-command policy enforcement |
| Install | `cargo install --git https://github.com/rtk-ai/rtk` |
| Min tested version | 0.30.0 (current in use: 0.35.0) |
| Hook consumers | `hook-pre-command.sh`, `hook-pre-command.ps1` |

**Contract:** The pre-command hooks allow any command prefixed with `rtk` unconditionally.
If rtk is missing, the hooks still block heavy commands — the AI must prefix manually.

**Fallback:** Without rtk, the AI receives a `[WARN]` block and must either install rtk
or prefix the command with `rtk` (no-op if rtk is absent).

**Compatibility assumption:** rtk CLI accepts arbitrary subcommands as pass-through (`rtk <cmd>`).
Breaking this assumption would cause the bypass path to fail silently.

---

## 2. Beads (bd) — Task Tracking

| Property | Value |
|----------|-------|
| Status | **Recommended** — toolbox functional without it |
| Install | `go install github.com/steveyegge/beads@latest` (requires Go) |
| Min tested version | 0.60.0 (current in use: 0.63.3) |
| Hook consumers | `hook-stop.sh`, `hook-stop.ps1`, `sync-task.sh`, `sync-task.ps1` |

**Contract:** `bd prime` is called at session end to refresh task context. `bd list` is used
by sync-task to export state to `current-task.md`. Both are expected to be idempotent and
exit 0 even when no tasks exist.

**Fallback:** If `bd` is absent, sync-task writes an empty stub to `current-task.md`.
Hook-stop silently skips the `bd prime` step. No functionality is lost; task tracking
falls back to manual updates of `current-task.md`.

---

## 3. shellcheck — Shell Script Linting

| Property | Value |
|----------|-------|
| Status | **Optional** — CI gate only |
| Install | `apt install shellcheck` / `brew install shellcheck` |
| Min tested version | 0.8.0 |
| CI step | `.github/workflows/` static-analysis job |

**Contract:** CI runs `shellcheck` on all `.sh` files in `.agent/scripts/`. Exit 0 = clean.
Annotations are warnings; only errors block the CI gate (configured via `-S error`).

**Fallback:** Without shellcheck, CI job is skipped and local linting is unavailable.
No runtime behavior is affected.

---

## 4. MCP Servers — External Resources

| Server | Status | Purpose |
|--------|--------|---------|
| `context7` | Optional | On-demand library documentation |
| `sequential-thinking` | Optional | Structured multi-step reasoning |
| `filesystem` | Optional | File system access outside repo |
| `fetch` | Optional | HTTP requests from the AI |
| `github` | Optional | GitHub API access |
| `memory` | Optional | Cross-session persistent memory |

**Contract:** MCP servers connect when the AI client starts. If a server is unavailable,
the AI client must degrade gracefully — no server is required for core toolbox function.

**Version assumption:** MCP servers follow the Model Context Protocol spec. No pinned
versions are required; the `test-mcp-schema.sh` script validates server definitions at CI time.
See `.agent/templates/mcp/` for reference configurations.

**Fallback:** Without MCP servers, the AI operates without external resource access.
`context7` absence means documentation must be fetched via web search instead.

---

## 5. GitHub Actions — CI/CD

| Property | Value |
|----------|-------|
| Status | Optional (required for automated CI gates) |
| Config | `.github/workflows/` |
| Relevant jobs | `static-analysis`, `validate-json`, `validate-toml`, `changelog` |

**Contract:** All CI jobs are expected to be additive — a failing job blocks the PR but
does not affect local development. Jobs are written to be idempotent.

**Fallback:** Without GitHub Actions, run validators locally:
```bash
bash .agent/scripts/validate-toolbox-config.sh
bash .agent/scripts/validate-adr.sh
bash .agent/scripts/validate-client-capabilities.sh
```

---

## 6. Python 3 — Script Support

| Property | Value |
|----------|-------|
| Status | **Optional** — used by `generate_client_files.py` and stats display |
| Min tested version | 3.8 |
| Consumers | `generate_client_files.py`, `hook-stop.sh` (stats display only) |

**Contract:** `generate_client_files.py` is the authoritative client file generator.
It reads `.ai-toolbox/config.json` and writes client router files.

**Fallback:** Without Python 3, `hook-stop.sh` falls back to `cat` for stats display.
Client files can be generated via the PowerShell equivalent (`generate-client-files.ps1`).

---

## Potential Conflicts

- rtk ≥ 0.35 changed the `rtk --version` output format; `doctor.sh` uses `|| echo 'installed'` to be resilient.
- Beads `bd prime` was added in 0.60 — earlier versions will exit non-zero; hook-stop wraps in `|| true`.
- MCP server `context7` may rate-limit heavy documentation requests; no retry logic exists in hooks.
