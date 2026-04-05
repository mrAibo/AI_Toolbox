# 🔌 MCP Server Setup

**When to use:**
You want to extend your AI agent with external tools via the Model Context Protocol (MCP). This prompt installs the recommended MCP servers step by step.

---

## Before You Start

Make sure:
- **Node.js** is installed (`node --version`)
- **npx** is available (`npx --version`)
- You have internet access (MCP servers are installed via npm)

---

### English Prompt 🇺🇸

> "Install the recommended MCP servers for this project following docs/mcp-guide.md.
>
> Use the **developer profile** (recommended for daily work):
> 1. **context7** — `npx -y @upstash/context7-mcp` — Lazy-load up-to-date documentation
> 2. **sequential-thinking** — `npx -y @modelcontextprotocol/server-sequential-thinking` — Structured reasoning
> 3. **filesystem** — `npx -y @modelcontextprotocol/server-filesystem .` — Controlled file access (scoped to current directory)
> 4. **fetch** — `npx -y @modelcontextprotocol/server-fetch` — Fetch web content
>
> Install them one by one. After each installation, confirm it succeeded.
> If any server fails, report the error and continue with the next.
> After all installations, list the configured MCP servers."

### German Prompt 🇩🇪

> "Installiere die empfohlenen MCP-Server für dieses Projekt gemäß docs/mcp-guide.md.
>
> Verwende das **Developer-Profil** (empfohlen für die tägliche Arbeit):
> 1. **context7** — `npx -y @upstash/context7-mcp` — Dokumentation nachladen
> 2. **sequential-thinking** — `npx -y @modelcontextprotocol/server-sequential-thinking` — Strukturierte Analyse
> 3. **filesystem** — `npx -y @modelcontextprotocol/server-filesystem .` — Kontrollierter Dateizugriff (auf aktuelles Verzeichnis beschränkt)
> 4. **fetch** — `npx -y @modelcontextprotocol/server-fetch` — Webinhalte laden
>
> Installiere sie nacheinander. Bestätige nach jeder Installation den Erfolg.
> Falls ein Server fehlschlägt, melde den Fehler und fahre mit dem nächsten fort.
> Liste nach allen Installationen die konfigurierten MCP-Server auf."

### Russian Prompt 🇷🇺

> "Установи рекомендуемые MCP-серверы для этого проекта согласно docs/mcp-guide.md.
>
> Используй **Developer-профиль** (рекомендуется для ежедневной работы):
> 1. **context7** — `npx -y @upstash/context7-mcp` — Подгрузка актуальной документации
> 2. **sequential-thinking** — `npx -y @modelcontextprotocol/server-sequential-thinking` — Структурированное мышление
> 3. **filesystem** — `npx -y @modelcontextprotocol/server-filesystem .` — Контролируемый доступ к файлам (ограничен текущей директорией)
> 4. **fetch** — `npx -y @modelcontextprotocol/server-fetch` — Загрузка веб-контента
>
> Устанавливай по одному. После каждой установки подтверди успех.
> Если сервер не установился — сообщи об ошибке и перейди к следующему.
> После всех установок перечисли настроенные MCP-серверы."

---

## Minimal Profile (Quick Setup)

If you only need documentation and reasoning support:

> "Install only the **minimal** MCP profile:
> 1. **context7** — `npx -y @upstash/context7-mcp`
> 2. **sequential-thinking** — `npx -y @modelcontextprotocol/server-sequential-thinking`
>
> Confirm each installation and list all configured servers when done."

## Full Profile (All Servers)

For full project work with GitHub integration:

> "Install the **full** MCP profile including all servers from docs/mcp-guide.md.
> For the GitHub server, I will set the GITHUB_TOKEN environment variable separately.
> Install each server, confirm success, and list all configured servers when done."
