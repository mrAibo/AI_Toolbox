# MCP Usage Rules

This file defines the constraints for using Model Context Protocol (MCP) servers within the AI Toolbox workflow.

---

## Core Principle

**MCP servers extend AI capabilities but introduce external dependencies and security surface.** Treat them as third-party integrations that must be governed.

---

## Authorization Rules

### Before Connecting an MCP Server

1. **Document it** in `.agent/memory/integration-contracts.md`
2. **Justify it** — what workflow problem does it solve?
3. **Scope it** — read-only vs read-write, which directories/resources?
4. **Record it** — add to `runbook.md` if it changes operational procedures

### Prohibited Without Explicit User Approval

- Granting write access to any MCP server
- Connecting MCP servers that access external APIs (GitHub, databases)
- Installing new npm packages for MCP servers globally
- Storing credentials or tokens in config files

---

## Security Rules

### Data Access

- MCP servers should only access data relevant to the current task
- Never use MCP to exfiltrate code, credentials, or sensitive data
- Filesystem MCP must be scoped to the project directory only

### Token Management

- Tokens (GITHUB_TOKEN, API keys) must be set via environment variables
- Never echo, log, or store tokens in memory files
- Rotate tokens if they are exposed in any way

### Server Vetting

- Only use MCP servers from official sources (`@modelcontextprotocol/*`, `@upstash/*`)
- Review the server's source code or npm page before installing
- Do not use community/unverified MCP servers without approval

---

## Operational Rules

### During Sessions

- If an MCP server is unavailable, continue work without it (core workflow must work standalone)
- Log MCP errors in `session-handover.md` if they block progress
- Do not retry failing MCP servers more than once per session

### After Sessions

- If a new MCP server was added during the session, update `integration-contracts.md`
- If an MCP server was removed, note the reason in `session-handover.md`

---

## MCP + Multi-Agent

When using MCP with parallel sub-agents:

- MCP connections are shared across agents (single client instance)
- Do not have multiple agents write to the same MCP resource simultaneously
- Sequential MCP calls (read then write) must be in a single agent, not split across agents
