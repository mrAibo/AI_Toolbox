# Pi (Inflection AI) Setup

Pi is a **Basic-Tier** client. It is a web-based conversational AI at [pi.ai](https://pi.ai) with no CLI, no config file, and no hook support. All AI Toolbox rules are soft reminders — there is no automated enforcement.

---

## Prerequisites

- A Pi account at [pi.ai](https://pi.ai)
- A local copy of the AI Toolbox project (cloned or bootstrapped)

---

## Setup

No installation is required. Run bootstrap once to generate `PI.md`:

```bash
# Linux / macOS
bash .agent/scripts/bootstrap.sh
```

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File .agent\scripts\bootstrap.ps1
```

Bootstrap creates `PI.md` in the project root if it does not already exist.

---

## How to Use Pi with AI Toolbox

Pi has no file-system access and cannot read your project files automatically. You must paste context manually at the start of each session.

### Recommended session start

1. Open [pi.ai](https://pi.ai) in your browser
2. Paste the contents of `PI.md` as your first message
3. Optionally paste the relevant memory files:
   - `.agent/memory/current-task.md` — active task state
   - `.agent/memory/session-handover.md` — unfinished work from the last session
4. Describe what you want to work on

### Recommended session end

Before closing the Pi chat, ask Pi to summarize the session and paste the result into `.agent/memory/session-handover.md` manually.

---

## What Gets Configured

| Component | File | Notes |
|-----------|------|-------|
| Router | `PI.md` | Paste into Pi at session start |
| Memory | `.agent/memory/` | Paste relevant files manually |
| Rules | `.agent/rules/` | Soft reminders — reference on demand |

---

## Limitations

| Feature | Status |
|---------|--------|
| Hooks (pre-command, stop) | Not available |
| Multi-agent | Not available |
| Automatic memory sync | Not available — manual paste only |
| Auto-detection | Not possible — no CLI binary |
| Plan mode | Not available |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Pi loses context mid-session | Re-paste `PI.md` and the relevant memory file |
| Pi contradicts earlier decisions | Paste `architecture-decisions.md` into chat |
| Session handover lost | Summarize the session manually before closing |
