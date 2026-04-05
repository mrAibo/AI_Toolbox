# MCP Guide

## Purpose

This document explains how Model Context Protocol (MCP) integrations fit into the AI Toolbox workflow and how to set them up.

---

## What is MCP?

MCP is an open standard that allows AI clients (Claude Code, Qwen Code, etc.) to connect to external resources through **servers**. Each server provides a set of **tools** the AI can call during a session.

**Analogy:** MCP servers are like browser extensions for your AI — they give it new capabilities without changing its core behavior.

---

## Recommended MCP Servers

### 🥇 Tier: Essential

| Server | Purpose | Trust Level |
|--------|---------|-------------|
| **context7** | Lazy-load up-to-date documentation and API references | Read-only |
| **sequential-thinking** | Structured step-by-step reasoning for complex problems | Read-only |

### 🥈 Tier: Recommended

| Server | Purpose | Trust Level |
|--------|---------|-------------|
| **filesystem** | Controlled file access within specific directories | Read-write |
| **fetch** | Fetch web content (documentation, articles) into context | Read-only |

### 🥉 Tier: Optional

| Server | Purpose | Trust Level |
|--------|---------|-------------|
| **github** | Read/write issues, PRs, code | Read-only (recommended) |
| **memory** | Long-term cross-session memory (local SQLite) | Read-write |

---

## Setup

### Step 1: Choose a Profile

| Profile | Servers | When to Use |
|---------|---------|-------------|
| **minimal** | context7, sequential-thinking | Quick tasks, low token budget |
| **developer** | + filesystem, fetch | Daily development (recommended) |
| **full** | All servers | Full project work, needs GITHUB_TOKEN |

### Step 2: Install via Claude Code

```bash
# Minimal
claude mcp add context7 npx -y @upstash/context7-mcp
claude mcp add sequential-thinking npx -y @modelcontextprotocol/server-sequential-thinking

# Developer (recommended)
claude mcp add filesystem npx -y @modelcontextprotocol/server-filesystem .
claude mcp add fetch npx -y @modelcontextprotocol/server-fetch

# Full (with GitHub)
claude mcp add github npx -y @modelcontextprotocol/server-github
claude mcp add memory npx -y @modelcontextprotocol/server-memory
```

### Step 2b: Install via Qwen Code

Add to your Qwen Code MCP configuration:

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

### Step 2c: Install via Cursor

Copy the config from `.agent/templates/mcp/mcp-cursor.json` to your `.cursor/settings.json`:

```json
{
  "mcpServers": {
    "context7": { "command": "npx", "args": ["-y", "@upstash/context7-mcp"] },
    "sequential-thinking": { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"] },
    "filesystem": { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-filesystem", "."] },
    "fetch": { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-fetch"] }
  }
}
```

### Step 2d: Install via RooCode / Cline

Copy the config from `.agent/templates/mcp/mcp-clinerules.json` to your Cline MCP settings.

### Step 2e: Install via Windsurf

Copy the config from `.agent/templates/mcp/mcp-windsurf.json` to your Windsurf MCP settings.

### Step 2f: Install via Gemini CLI

Copy the config from `.agent/templates/mcp/mcp-gemini.json` to your Gemini CLI MCP config.
Gemini CLI is Basic Tier — only minimal profile (context7 + sequential-thinking) is recommended.

### Step 2g: Install via Aider

Add to your `.aider.conf.yml`:

```yaml
mcp:
  context7:
    command: npx
    args: ["-y", "@upstash/context7-mcp"]
  sequential-thinking:
    command: npx
    args: ["-y", "@modelcontextprotocol/server-sequential-thinking"]
```

### Step 3: Verify

Start your AI client and ask: *"List your available MCP servers and their capabilities."*

Expected output: The servers you configured with their tool descriptions.

---

## Security Rules

### Core Principle

> **Never grant write access unless the AI explicitly needs it.**

### Trust Levels

| Level | What the AI Can Do | Risk |
|-------|--------------------|------|
| **read-only** | Read data, fetch docs, search | Low |
| **read-write** | Modify files, create resources | Medium |

### Best Practices

1. **Start with read-only** — upgrade only when needed
2. **Scope filesystem access** — restrict to project directory (`.`), never `/` or `$HOME`
3. **Never expose secrets** — `GITHUB_TOKEN` should be an env variable, not hardcoded
4. **Audit server sources** — only use official or well-maintained MCP servers
5. **Review tool calls** — check what the AI actually invoked before it executes

### Prohibited Configurations

- ❌ Filesystem MCP with root (`/`) or home (`$HOME`) directory access
- ❌ GitHub MCP with write permissions unless explicitly required
- ❌ MCP servers from untrusted/unknown sources
- ❌ Hardcoded tokens or credentials in config files

---

## When MCP Changes the Workflow

If an MCP integration changes how the AI works:

1. Record the change in `.agent/memory/integration-contracts.md`
2. Update operational notes in `.agent/memory/runbook.md`
3. Update this guide if the change is permanent

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `npx: command not found` | Install Node.js / ensure `npx` is in PATH |
| Server times out | Check internet connection; some MCP servers require npm registry access |
| AI can't find a tool | Verify server started successfully; run `npx -y <server>` manually to test |
| Token errors with context7 | context7 queries external APIs — ensure no firewall blocks the request |
