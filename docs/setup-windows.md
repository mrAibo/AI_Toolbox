# Windows Setup

## Prerequisites
- Git
- PowerShell
- Optional: WSL if your workflow is more Unix-oriented
- A terminal-based AI tool such as Claude Code, OpenCode, or Gemini CLI

## Recommended flow
1. Clone the repository
2. Review `README.md`
3. Review `AGENT.md`
4. Fill the memory files
5. Run the bootstrap script (`powershell .agent/scripts/bootstrap.ps1`). This will generate AI routing files (like `.clinerules`, `CLAUDE.md`, `GEMINI.md`) and initialize the hook wrappers.
6. Verify PowerShell scripts and hooks (Git pre-commit, .claude.json).
7. Connect task tracking if needed (e.g., `bd`).

## Notes
- Keep the workflow consistent with Linux as much as possible
- Use PowerShell versions of the scripts where appropriate
- Record durable decisions in `.agent/memory/`
