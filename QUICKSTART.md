# Quick Start — AI Toolbox in 5 Minutes

This guide gets you up and running in under 5 minutes.

---

## Prerequisites

- **Git** installed
- **Terminal AI client** (Claude Code, Qwen Code, Gemini CLI, Cursor, etc.)
- *(Optional)* **Rust** for rtk, **Go** for Beads

---

## Step 1: Create or Clone (1 min)

```bash
# New project
git clone https://github.com/mrAibo/AI_Toolbox.git my-project
cd my-project

# Or in an existing project
curl -sSL https://raw.githubusercontent.com/mrAibo/AI_Toolbox/main/install.md
# Follow the instructions
```

---

## Step 2: Bootstrap (1 min)

```bash
# Linux/macOS
bash .agent/scripts/bootstrap.sh

# Windows
powershell -ExecutionPolicy Bypass -File .agent\scripts\bootstrap.ps1
```

This creates:
- ✅ Router files for your AI client (`CLAUDE.md`, `QWEN.md`, etc.)
- ✅ Memory files with seed content
- ✅ Rule files (safety, testing, TDD, MCP, etc.)
- ✅ Git pre-commit hook

---

## Step 3: Install rtk (1 min, optional but recommended)

```bash
cargo install rtk
rtk init -g
```

rtk compresses test/build output by 60-90%, saving tokens and keeping the AI focused.

---

## Step 4: Start Your AI Agent (30 sec)

Open your AI client in the project directory. It will:
1. Read `AGENT.md` automatically
2. Run the Boot Sequence
3. Restore context from memory files
4. Be ready to work

**Prompt to use:**
```
I want to build [describe your project/feature].
Per AGENT.md rules, do not code yet.
Analyze constraints, propose approaches, and let's plan.
```

---

## That's It

You now have:
- ✅ A structured AI workflow
- ✅ Persistent project memory
- ✅ Safety rules (no destructive actions without confirmation)
- ✅ TDD enforcement (RED-GREEN-REFACTOR)
- ✅ Task tracking (if you installed Beads)
- ✅ Token optimization (if you installed rtk)

---

## What's Next?

| If you want to... | Read |
|-------------------|------|
| Understand the full architecture | [docs/architecture.md](docs/architecture.md) |
| Set up MCP servers | [docs/mcp-guide.md](docs/mcp-guide.md) |
| See real examples | [examples/README.md](examples/README.md) |
| Contribute to AI Toolbox | [CONTRIBUTING.md](CONTRIBUTING.md) |
| See what changed | [CHANGELOG.md](CHANGELOG.md) |
