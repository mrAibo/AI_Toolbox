# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

---

## [v1.5.0] — 2026-04-27

### Added — Phase A: declarative contracts
- `.agent/schema/` — seven JSON Schemas (Draft 2020-12): `config`, `client`,
  `plugin-manifest`, `hook-protocol`, `doctor-output`, `context-bundle`,
  `error-codes`. All meta-validated in CI.
- `.agent/contracts/hook-protocol.json` + `hook-protocol.md` — per-client
  hook capabilities with explicit `guarantees` block (`can_block`,
  `can_modify_input`, `can_modify_output`, `can_inject_context`). Codex
  declared as block-only — a system limit, not an implementation gap.
- `.agent/contracts/error-codes.json` + `error-codes.md` — registry of 10
  structured error classes with stable exit codes (≥10) per category:
  `CONFIG_ERROR`, `CONTRACT_VIOLATION`, `DETERMINISM_ERROR`,
  `MIGRATION_ERROR`, `PLUGIN_ERROR`, `IO_ERROR`, `INTERNAL_ERROR`, …
- `.agent/scripts/lib-errors.sh` — structured error emit helper with
  text and JSON modes, variable substitution into fix templates.
- `.agent/migrations/1.4-to-1.5.sh` + `.ps1` — first idempotent migration
  (adds `$schema` reference, `toolbox_version`, `context` budgets).
- `.agent/scripts/migrate.sh` + `.ps1` — versioned migrator with `--dry-run`
  and audit-log entries.
- `.agent/scripts/test-hook-contract.sh` — per-client × per-event simulation
  with `--json` output for CI consumption.
- `.ai-toolbox/config.json` — `$schema` reference and required
  `toolbox_version: "1.5"`.

### Added — Phase B: unified surface, plugins, dry-run
- `ai-toolbox` (bash) and `ai-toolbox.ps1` (PowerShell) — top-level
  dispatcher with 9 stable verbs: `doctor`, `setup`, `bootstrap`, `validate`,
  `migrate`, `sync`, plus reserved `context`/`simulate`/`stats` (Phase C).
- `docs/cli-reference.md` — interface contract and stability policy
  (hard cap: 9 top-level verbs).
- `.agent/plugins/` — file-based plugin convention. Drop a directory with
  `manifest.json` and `rules.md`; bootstrap enumerates and references them
  from `AGENT.md`. Schema-validated.
- `.agent/plugins/nodejs/` and `.agent/plugins/python/` — two reference
  plugins.
- `.agent/scripts/render-plugins.py` — idempotent enumerator with
  `--check` (CI drift guard) and `--dry-run` modes; detects rule-file
  conflicts when `conflict_resolution: fail` is declared.
- `tests/test_render_plugins.py` — 8 unit tests covering rendering,
  idempotency, drift detection, dry-run, conflict resolution, name/dir
  validation, and the empty-plugins case.
- `bootstrap.sh` / `bootstrap.ps1` — `--dry-run` flag previewing every
  filesystem write. Bash overrides `mkdir`/`cp`/`mv`/`touch`/`chmod`/`ln`;
  30 heredoc-write sites use the new `_dr_writeto` helper. PowerShell
  overrides the equivalent cmdlets via global function override.

### Added — CI
- Matrix job `hook-contract` runs `test-hook-contract.sh` for every
  Full-Tier client (Claude, Qwen, Codex, OpenCode); fails fast on contract
  drift. Results uploaded as artifacts.
- Schema meta-validation: every `.agent/schema/*.schema.json` must be a
  valid JSON Schema.
- Instance validation: hook-protocol, error-codes, and every plugin
  manifest validated against their schema on every push.
- AGENT.md drift check via `render-plugins.py --check`.

### Changed
- `doctor.sh` / `doctor.ps1` — new `--json` output (schema-conformant per
  `doctor-output.schema.json`) and `--explain` flag (appends fix
  instructions to every warning/error). Two new sections: "Schema &
  Contracts" and "Toolbox Version".
- `validate-toolbox-config.sh` — switched to the `jsonschema` +
  `referencing` API with defensive fallback to `RefResolver` on older
  installations.
- `AGENT.md` — new section 16 documenting plugins, with the auto-managed
  `<!-- AI_TOOLBOX_PLUGINS:START/END -->` marker block.

### Carried over from prior unreleased work
- `PI.md` — Basic-Tier router file for Pi (Inflection AI, pi.ai); web-only
  client, soft reminders, manual context paste workflow.
- `docs/setup-pi.md` — Pi setup guide: session start/end flow, manual
  context workflow, limitations table.
- `.ai-toolbox/config.json` — Pi client entry (tier: basic, no hooks,
  no autodetect).
- `bootstrap.sh` / `bootstrap.ps1` — generate `PI.md` when missing
  (idempotent, matching Gemini pattern).
- `test-content.sh` — `PI.md` added to router-file check list.
- `USE_AS_TEMPLATE.md` — expanded with full step-by-step GitHub Template
  flow (7 steps), Template vs Clone vs Fork comparison table, client
  router-file reference table, per-client setup guide links.
- `INSTALL.md` — added GitHub Template as Option A with `USE_AS_TEMPLATE.md`
  link, added Pi client section.
- `README.md` — rewritten for v1.5: leads with the problem-it-solves,
  highlights the new declarative-contracts and plugin layers, links to
  the unified CLI and per-client hook guarantees.

---

## [v1.2.0] — 2026-04-23

### Fixed
- `release.yml` — replaced invalid pinned SHA `softprops/action-gh-release@4685be8...` with `@v2`; Release workflow now succeeds on tag push
- `bootstrap.sh` / `bootstrap.ps1` — QWEN fallback template still had 5-file memory list; replaced with 1-line `memory-index.md` reference (consistent with TS2 live-file fix)
- `docs/setup-claude.md` — added "What's New in v1.1.0" section covering cache stability, doctor script, Next Steps checklist, input context budget

### Added
- `test-content.sh` — cache-prefix marker check for all router files alongside existing tier-badge check (162/162 tests pass)

### Changed
- `README.md` — rewritten from 467 → ~150 lines: removed duplicate sections, collapsed architecture tree to key-files list, replaced verbose scenario A/B/C with two copy-paste prompts

---

## [v1.1.0] — 2026-04-23

### Token Cost Reduction (TS1 + TS2 + TS3)

#### Added
- `<!-- cache-prefix -->` marker on line 2 of all 8 router files (CLAUDE.md, QWEN.md, GEMINI.md, CONVENTIONS.md, CODERULES.md, OPENCODERULES.md, SKILL.md, .cursorrules/.clinerules/.windsurfrules) — signals stable prefix boundary for prompt-cache hits
- `Cache Policy` section in `AGENT.md` — explains why the Critical Session Rules block must stay unmodified across sessions
- `doctor.sh` / `doctor.ps1` — now verifies `cache-prefix` presence in router files; warns if missing after manual edit
- `diff-editing.md` — new **Input Context Budget** section: decision table for diff/symbol/outline vs. full-file reads, with explicit escape-hatch rule
- `hook-pre-command.sh` / `hook-pre-command.ps1` — advisory warning (non-blocking, exit 0) when `cat`-ing source files >200 lines; recommends `git diff` or symbol context

#### Changed
- `bootstrap.sh` / `bootstrap.ps1` — all router file templates now include the `cache-prefix` marker so newly bootstrapped repos inherit it automatically
- `QWEN.md`, `CODERULES.md`, `OPENCODERULES.md`, `CONVENTIONS.md` — replaced verbatim 4–6 file memory-load list with single-line reference to `memory-index.md` (~30 lines of duplication removed)
- `AGENT.md` §4 Execution Rules — added `Context discipline` reference to `diff-editing.md`

---

### Bootstrap Client-Config Merge

#### Fixed
- `bootstrap.sh` — Codex (`.codex/hooks.json`) and OpenCode (`opencode.json`) now merge AI Toolbox hooks/keys into existing configs instead of silently skipping them (marker-check + Python3 merge, matching `.ps1` behavior)
- `bootstrap.ps1` — Qwen, Codex, OpenCode merges already in place; all three clients now idempotent

---

### Setup Automation & Post-Setup Diagnostics

#### Fixed
- `setup.ps1` / `setup.sh` — corrected `go install` path from `beads@v0.63.3` to `beads/cmd/bd@v0.63.3` (main package)
- `setup.ps1` — after `go install`, GOPATH/bin is now added to current session PATH and persisted to user PATH automatically
- `setup.ps1` — `bd init` now auto-falls back to `--server` mode when embedded CGO is unavailable (Windows); if dolt is not yet in PATH, searches `C:\Program Files\Dolt\bin` and similar paths and adds them automatically
- `setup.ps1` — detects and removes stale npm `bd` shim (Node.js wrapper pointing to missing `bd.js`)
- `setup.ps1` / `setup.sh` — added `$NextSteps` / `NEXT_STEPS` array: any step that fails or requires manual action is appended and printed as a numbered checklist at the end of setup
- `setup.ps1` / `setup.sh` — Summary section now shows ✅/⚠️ per component; "Next Steps" block only appears when manual action is needed; suppressed when everything succeeded

---

### Claude Code & OpenCode Implementation Review

#### Added
- `.agent/rules/claude-code.md` — Claude Code-specific rule extensions: hook events, MCP integration, sub-agent orchestration, plan mode, session boot
- `docs/setup-claude.md` — Claude Code setup guide parallel to `docs/setup-opencode.md`; covers prerequisites, MCP servers, slash commands, hooks reference, troubleshooting

#### Fixed
- `setup.sh` / `setup.ps1` — added OpenCode to client autodetection scan (Step 2)
- `setup.sh` — added `opencode` case to Step 7 hook registration; copies `opencode-config.json` template if `opencode.json` absent
- `setup.ps1` — added `opencode` case to Step 7 hook registration (parity with `setup.sh`)
- `.agent/memory/memory-index.md` — added `claude-code.md` to Rules Index

---

### Project Review Fixes

#### Fixed
- `AGENT.md` Step 9 — added `security-policy.md` and `client-detection.md` to on-demand rules list (were orphaned since PR5/PR7)
- `tdd-rules.md` Step 5 — added scope clarification: TDD refactoring is limited to code touched by the current test cycle; unrelated code requires a separate task
- `bootstrap.sh` / `bootstrap.ps1` — create `SKILL.md` (Antigravity Full-Tier router) when missing; previously config.json listed Antigravity as Full-Tier but bootstrap never created its router file
- `doctor.sh` / `doctor.ps1` — added `flock` availability check; warns when absent (atomic rename fallback active, weaker guarantee under parallel agents)

---

### Git Hooks Opt-in

#### Changed
- `setup.sh` / `setup.ps1` — added interactive prompt before bootstrap: "Install Git commit hooks (TDD enforcement + secret scan)? [Y/n]"
- `bootstrap.sh` / `bootstrap.ps1` — respect `AITB_INSTALL_GIT_HOOKS=false` env var to skip hook installation; direct bootstrap calls remain unaffected (default: install hooks)

---

### Coding Discipline Rules (adapted from Karpathy guidelines)

#### Added
- `.agent/rules/coding-discipline.md` — two coding principles adapted from Andrej Karpathy's LLM pitfall observations:
  - **Simplicity First:** no speculative code, no premature abstractions, minimum code that solves the stated problem
  - **Surgical Changes:** change only the reported lines, no opportunistic refactoring or adjacent cleanup
- `AGENT.md` — linked `coding-discipline.md` in Boot Sequence step 9 (on-demand rules)

---

### PR9 — GitHub Template Support

#### Added
- `USE_AS_TEMPLATE.md` — onboarding guide: new-user flow, Template vs `setup.sh` / `bootstrap.sh` / sync comparison, `/generate` flow docs, template suitability notes, migration note for existing users
- README: "Use as GitHub Template" entry point (step 0) linking to `USE_AS_TEMPLATE.md`

---

### PR8 — Audit Trail & Operations Diagnostics

#### Added
- `lib-audit.sh` / `lib-audit.ps1` — append-only local audit log library; emits structured events to `.agent/memory/audit.log`
- Audit events in `hook-pre-command` (`heavy_cmd_blocked`), `verify-commit` (`secret_scan_bypassed`), `hook-stop` (`handover_written`)
- `test-audit.sh` — functional tests for audit trail (emit, append, format)
- `doctor.sh` / `.ps1` — added Audit section: shows last 5 events and log path

#### Changed
- `integration-contracts.md`, `runbook.md` — documented audit trail schema and operational procedures

---

### PR7 — Hook Security Hardening

#### Added
- `.agent/rules/security-policy.md` — documented security rules, bypass procedures, and PS1/sh parity requirements

#### Changed
- All pre-command hooks — normalized `npm`/`npx`/`yarn`/`pnpm`/`bun` command detection; consistent regex across bash and PowerShell
- `verify-commit.ps1` — full secret-scan parity with `verify-commit.sh` (closes PS1 coverage gap)
- Qwen Code bash pre-command hook — aligned with Claude Code regex patterns

---

### PR6 — Config Validation & Typed ADR Metadata

#### Added
- `validate-toolbox-config.sh` — validates `.ai-toolbox/config.json` structure; CI blocks malformed configs
- `validate-adr.sh` — validates ADR required fields (Status, date, deciders); CI blocks invalid ADRs
- `test-integration.sh` — extended with config and ADR validation tests (Test 10)

#### Changed
- `generate_client_files.py` — added schema validation for generated client artifacts
- `.agent/templates/adr-template.md` — typed required fields with allowed values

---

### PR5 — Explicit Client Selection

#### Added
- `.agent/rules/client-detection.md` — documents four-step priority: config → autodetect → interactive → persist

#### Changed
- `setup.sh` / `setup.ps1` — explicit config wins over autodetect; client choice persisted to `.ai-toolbox/config.json`; second run skips detection prompt
- `.ai-toolbox/config.json` — added `primary_client` field

---

### PR4 — Central Client Config & Generator

#### Added
- `.ai-toolbox/config.json` — single source of truth for all 10 clients across 3 tiers; replaces ~250 lines of per-client bootstrap duplication
- `generate_client_files.py` — stdlib-only Python generator with dry-run, sync, and validate modes
- `generate-client-files.sh` / `generate-client-files.ps1` — CI wrapper scripts

---

### PR3 — Hardened Core Rules & Bootstrap Seeds

#### Added
- `PSScriptAnalyzerSettings.psd1` — PowerShell lint rules enforced in CI
- `CONTRIBUTING.md` — contributor guide

#### Changed
- `safety-rules.md`, `testing-rules.md`, `stack-rules.md` — strengthened with 5 core principles
- `AGENT.md` — added 5 hard execution rules
- `bootstrap.sh` / `bootstrap.ps1` — updated memory and rules seed content

---

### PR2 — Client-Independent Skills Directory

#### Added
- `.agent/skills/` — 9 skills migrated from `.qwen/` to client-agnostic location (Qwen Code, OpenCode, Codex CLI compatible)
- `.agent/skills/receiving-code-review/` — anti-sycophancy guidelines and verify-before-implementing workflow
- `.agent/commands/` — client-agnostic command definitions

---

### PR1 — Atomic Writes & Concurrency Safety

#### Added
- `lib-atomic-write.sh` — atomic write helpers using temp-file + rename pattern for crash-safe memory updates
- `verify-concurrency.sh` — concurrent write stress test (20 parallel hooks)

#### Changed
- Hook scripts — updated to use atomic writes for all `.agent/memory/` file mutations; Mutex guard around concurrent invocations

---

### Pre-PR (infrastructure and examples)

#### Added
- Release pipeline (`.github/workflows/release.yml`) — automatic GitHub Releases on version tag push
- Changelog validation workflow (`.github/workflows/changelog.yml`) — PR check ensuring CHANGELOG.md is updated
- `bump-version.sh` — semver tagging with push-to-release automation
- Status reporting system (`.agent/rules/status-reporting.md`, `.agent/memory/active-session.md`)
- GitHub Actions CI workflow (18 steps: link validation, tier badge check, bootstrap parity, JSON validation)
- GitHub Issue templates (bug report, feature request)
- `examples/daily-pitfalls.md` — 8 common daily mistakes and how AI Toolbox prevents them
- German and Russian translations for 4 key examples (add-feature, fix-bug, refactor, continue-work)

#### Changed
- `examples/README.md` — reorganized into categories with language flags
- `hook-stop.sh` / `.ps1` — auto-write session summary to `session-handover.md`
- `AGENT.md` — added reference to status-reporting rules

---

## [v1.0.0] — 2026-04-05

### Added
- Complete AI Toolbox framework: AGENT.md, Bootstrap scripts, Hooks, Rules
- Multi-tool integration: rtk, Beads, Superpowers, Template Bridge, MCP
- Unified 9-step Workflow (TASK → BRAINSTORM → PLAN → ISOLATE → IMPLEMENT → REVIEW → VERIFY → FINISH → CLOSE)
- TDD enforcement rules (`.agent/rules/tdd-rules.md`)
- Code Review workflow (`.agent/workflows/code-review.md`)
- Branch Finish workflow (`.agent/workflows/branch-finish.md`)
- Template Bridge integration (413+ specialist templates)
- MCP configuration for all 10 AI clients (8 client configs + master config)
- MCP guide (`docs/mcp-guide.md`) with setup for all clients
- Status reporting rules and live session tracking
- End-to-end ensemble walkthrough example
- 3-language examples (EN/DE/RU)

### Fixed
- 47 issues across 7 audit rounds (broken links, bootstrap parity, hook consistency, tier badges, content drift, regex bugs, missing guards)

---

[Unreleased]: https://github.com/mrAibo/AI_Toolbox/compare/v1.2.0..HEAD
[v1.2.0]: https://github.com/mrAibo/AI_Toolbox/compare/v1.1.0..v1.2.0
[v1.1.0]: https://github.com/mrAibo/AI_Toolbox/compare/v1.0.0..v1.1.0
[v1.0.0]: https://github.com/mrAibo/AI_Toolbox/releases/tag/v1.0.0
