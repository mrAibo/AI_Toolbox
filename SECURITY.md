# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| `main` branch | ✅ |
| Earlier commits | ❌ |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in the AI Toolbox framework:

1. **Do NOT open a public issue.**
2. **Email:** [crownru@gmail.com](mailto:crownru@gmail.com)
3. **Subject:** `[SECURITY] AI Toolbox — <brief description>`
4. **Include:**
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We will respond within **48 hours** with an acknowledgment and a timeline for a fix.

## What We Consider a Security Issue

- Shell injection vulnerabilities in bootstrap or hook scripts
- Credential leakage in logs or memory files
- MCP server configurations that expose sensitive data
- Command injection in `verify-commit` or `sync-task` scripts

## What Is NOT a Security Issue

- Bugs in external tool integrations (rtk, Beads, etc.)
- Missing features or documentation gaps
- AI agent hallucinations or incorrect outputs
- Performance issues

## Disclosure Policy

- We will acknowledge the reporter within 48 hours.
- We will provide a fix within **14 days** for confirmed vulnerabilities.
- We will publicly credit the reporter (unless they prefer anonymity).
- We will publish a security advisory after the fix is released.

## Best Practices for Users

The AI Toolbox is designed with security in mind, but users should follow these practices:

1. **Never commit secrets** — use environment variables for tokens (e.g., `GITHUB_TOKEN`)
2. **Review MCP configs** — ensure no credentials are hardcoded
3. **Scope filesystem access** — restrict MCP filesystem access to project directory only
4. **Audit hook scripts** — review `hook-pre-command` and `hook-stop` before using in production
5. **Keep rtk updated** — `cargo install --git https://github.com/rtk-ai/rtk --rev v0.35.0` to get the latest security fixes (pin to a known-good commit; update after reviewing release notes)
6. **Never use `git commit --no-verify`** — this flag bypasses all pre-commit hooks, including quality checks, security scans, and the `verify-commit` script. For mandatory enforcement, run all quality gates in a CI pipeline where `--no-verify` cannot be used to circumvent checks.

## MCP Security

MCP servers are third-party integrations. The AI Toolbox only provides configuration templates — it does not host or maintain any MCP servers. Users should:

- Review the source code of MCP servers before installing
- Use read-only trust levels where possible
- Never expose tokens or credentials in config files
- Scope filesystem MCP to the project directory only

For detailed MCP security guidelines, see [docs/mcp-guide.md](docs/mcp-guide.md).
