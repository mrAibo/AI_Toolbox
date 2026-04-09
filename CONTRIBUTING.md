# Contributing to AI Toolbox

Thank you for your interest in contributing! This document explains how to contribute to the AI Toolbox project.

---

## How Can I Contribute?

### Reporting Bugs

Before creating a bug report:
- Search [existing issues](https://github.com/mrAibo/AI_Toolbox/issues) to see if it's already reported
- Check if the issue exists in the latest version

When filing a bug, include:
- **OS** (Windows, macOS, Linux)
- **AI Client** (Claude Code, Qwen Code, etc.)
- **Steps to reproduce**
- **Expected vs actual behavior**
- **Relevant logs** (use `rtk` for long logs)

👉 Use the [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.yml).

### Suggesting Enhancements

When proposing a feature:
- Explain the **problem** it solves
- Describe the **solution** clearly
- Note any **alternatives** considered

👉 Use the [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.yml).

### Contributing Code

1. **Fork** the repository
2. **Create a branch** for your change (`git checkout -b feature/my-feature`)
3. **Make your changes** — keep them focused and minimal
4. **Test your changes**:
   - Run `bash .agent/scripts/bootstrap.sh` — must complete without errors
   - Run `pwsh .agent/scripts/bootstrap.ps1` — must complete without errors
   - Verify all markdown links are valid
5. **Commit** with a clear message (see below)
6. **Open a Pull Request** — explain what you changed and why

---

## Commit Message Convention

Use the [Conventional Commits](https://www.conventionalcommits.org/) format:

```
type(scope): short description

feat(rules): add tdd-rules.md with RED-GREEN-REFACTOR cycle
fix(bootstrap): runbook.md missing from bootstrap.sh
docs(examples): add German and Russian translations
chore(ci): add GitHub Actions workflow for validation
```

**Types:**
- `feat` — new feature
- `fix` — bug fix
- `docs` — documentation changes
- `style` — formatting, no code change
- `refactor` — code change, no behavior change
- `test` — adding tests
- `chore` — maintenance tasks

---

## Project Structure

See [README.md](README.md) for the detailed project structure. The CONTRIBUTING tree below is a simplified overview:

```
AI_Toolbox/
├── AGENT.md                    # Master protocol
├── README.md                   # Human-facing overview
├── .agent/
│   ├── rules/                  # Execution constraints
│   ├── scripts/                # Bootstrap, hooks, sync
│   ├── workflows/              # Defined workflows (unified, bug-fix, etc.)
│   ├── templates/              # Templates (MCP configs, client configs)
│   └── memory/                 # Project memory files
├── docs/                       # Detailed guides
├── examples/                   # Usage examples (EN/DE/RU)
└── prompts/                    # Ready-to-use prompts
```

---

## What to Contribute

Good areas for contributions:

| Area | What | Difficulty |
|------|------|-----------|
| **Examples** | New real-world scenarios in any language | Easy |
| **Docs** | Improve existing documentation | Easy |
| **Rules** | New rule files for specific workflows | Medium |
| **Workflows** | New workflow definitions | Medium |
| **Bootstrap** | Fix bugs in bootstrap scripts | Medium |
| **MCP** | New MCP server configurations | Easy |
| **Tests** | CI validation scripts | Medium |

---

## Style Guidelines

- **Markdown** — use standard CommonMark
- **Shell scripts** — use `#!/bin/bash`, `set -e`, quote all variables
- **PowerShell** — use `$ErrorActionPreference = "Stop"`, UTF-8 encoding
- **JSON** — 2-space indent, trailing commas allowed
- **YAML** — 2-space indent

All text files must end with a trailing newline character.

---

## Questions?

- Read the [README.md](README.md) for an overview
- Check [docs/](docs/) for detailed guides
- Look at [examples/](examples/) for usage patterns
- Open an [issue](https://github.com/mrAibo/AI_Toolbox/issues) for anything unclear
