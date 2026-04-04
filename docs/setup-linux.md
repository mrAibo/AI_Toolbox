# Linux Setup

## Prerequisites
- Git
- Bash
- A terminal-based AI tool such as Claude Code, OpenCode, or Gemini CLI

## Recommended flow
1. Clone the repository
2. Review `README.md`
3. Review `AGENT.md`
4. Fill the memory files
5. Run the bootstrap script (`bash .agent/scripts/bootstrap.sh`). This will generate AI routing files (like `.clinerules`, `CLAUDE.md`, `GEMINI.md`) and initialize the hook wrappers.
6. Verify scripts and hooks (Git pre-commit, .claude.json).
7. Connect task tracking if needed (e.g., `bd`).

## Notes
- Keep the setup simple and repeatable
- Use `rtk` for heavy terminal output when possible
- Record durable decisions in `.agent/memory/`
