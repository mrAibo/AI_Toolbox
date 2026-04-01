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
5. Configure scripts and hooks
6. Connect task tracking if needed
7. Run the bootstrap script (This will automatically generate AI routing files like `.clinerules`, `CLAUDE.md`, `GEMINI.md` to point agents to the workflow).

## Notes
- Keep the setup simple and repeatable
- Use `rtk` for heavy terminal output when possible
- Record durable decisions in `.agent/memory/`
