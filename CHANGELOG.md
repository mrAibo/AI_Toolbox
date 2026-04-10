# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

### Added
- Release pipeline (`.github/workflows/release.yml`) — automatic GitHub Releases on version tag push
- Changelog validation workflow (`.github/workflows/changelog.yml`) — PR check ensuring CHANGELOG.md is updated for code changes
- `bump-version.sh` helper script — semver tagging with push-to-release automation
- German and Russian translations for 4 key examples (add-feature, fix-bug, refactor, continue-work)
- `examples/daily-pitfalls.md` — 8 common daily mistakes and how AI Toolbox prevents them
- Status reporting system (`.agent/rules/status-reporting.md`, `.agent/memory/active-session.md`)
- 4 new daily scenario examples (add-feature, fix-bug, refactor, continue-work)
- GitHub Actions CI workflow (link validation, tier badge check, bootstrap parity, JSON validation)
- GitHub Issue templates (bug report, feature request)
- `CONTRIBUTING.md` — guide for contributors

### Changed
- `examples/README.md` — reorganized into categories with language flags
- `hook-stop.sh/ps1` — auto-write session summary to `session-handover.md`
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
