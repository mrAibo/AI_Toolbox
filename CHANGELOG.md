# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

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

[Unreleased]: https://github.com/mrAibo/AI_Toolbox/compare/v1.0.0..HEAD
[v1.0.0]: https://github.com/mrAibo/AI_Toolbox/releases/tag/v1.0.0
