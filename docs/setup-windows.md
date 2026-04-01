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
5. Configure PowerShell scripts and hooks
6. Connect task tracking if needed
7. Run the bootstrap script (This will automatically generate AI routing files like `.clinerules`, `CLAUDE.md`, `GEMINI.md` to point agents to the workflow).

## Notes
- Keep the workflow consistent with Linux as much as possible
- Use PowerShell versions of the scripts where appropriate
- Record durable decisions in `.agent/memory/`
