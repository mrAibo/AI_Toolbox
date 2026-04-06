# Example: Fresh Project Setup with AI Toolbox

This example shows how to initialize AI Toolbox in a brand-new project from scratch.

---

## Scenario

You start a new project (`my-webapp`) and want AI-assisted development with proper memory, safety rules, and task tracking.

---

## Step 1: Create the Project

```bash
mkdir my-webapp
cd my-webapp
git init
npm init -y
```

---

## Step 2: Initialize AI Toolbox

### Option A: Via AI Agent (Recommended)

Start your terminal AI (Claude Code, Qwen Code, Gemini CLI, etc.) and paste:

```
Follow the setup instructions here to initialize the AI Toolbox environment:
https://raw.githubusercontent.com/mrAibo/AI_Toolbox/main/INSTALL.md
```

The AI will:
1. Download `.agent/` folder + `AGENT.md`
2. Run `bootstrap.sh` / `bootstrap.ps1`
3. Create all router files (`CLAUDE.md`, `QWEN.md`, etc.)
4. Check for `rtk` and `Beads`
5. Report completion

### Option B: Manual

```bash
# Clone just the framework
git clone https://github.com/mrAibo/AI_Toolbox.git /tmp/ai_toolbox

# Copy core files
cp -r /tmp/ai_toolbox/.agent ./
cp /tmp/ai_toolbox/AGENT.md ./
rm -rf /tmp/ai_toolbox

# Run bootstrap
bash .agent/scripts/bootstrap.sh  # or .ps1 on Windows
```

---

## Step 3: What Gets Created

```
my-webapp/
├── AGENT.md                    # Master protocol (committed)
├── CLAUDE.md / QWEN.md / ...   # Client router files
├── .gitignore                  # Updated with AI Toolbox entries
└── .agent/
    ├── memory/                 # Project brain
    │   ├── architecture-decisions.md   # ADR log (empty, ready)
    │   ├── integration-contracts.md    # API contracts (empty, ready)
    │   ├── session-handover.md         # Handover log (empty, ready)
    │   ├── current-task.md             # Active task (empty, ready)
    │   └── runbook.md                  # Operational knowledge (empty, ready)
    ├── rules/                  # Execution constraints
    │   ├── safety-rules.md     # No destructive actions
    │   ├── testing-rules.md    # Verification required
    │   ├── stack-rules.md      # Tech stack discipline
    │   ├── antigravity.md      # Antigravity-specific rules
    │   └── qwen-code.md        # Qwen Code multi-agent rules
    └── scripts/                # Automation
        ├── bootstrap.sh / .ps1 # Setup script (run once)
        └── sync-task.sh / .ps1 # Task synchronization
```

---

## Step 4: First Interaction

```
"I want to build a React webapp with a REST API.
Per AGENT.md, do not code yet. Analyze constraints,
propose 2-3 approaches, and let's brainstorm."
```

The AI will:
1. Record the decision in `architecture-decisions.md`
2. Create tasks in `current-task.md`
3. Start implementation with verification

---

## What You Get

| Feature | Without AI Toolbox | With AI Toolbox |
|---------|-------------------|-----------------|
| Memory | Lost between sessions | Persistent in `.agent/memory/` |
| Safety | AI runs `rm -rf` unchecked | Hooks enforce `rtk` prefix |
| Tasks | "What was I doing?" | `current-task.md` + Beads |
| Architecture | Decisions lost | ADR log in `architecture-decisions.md` |
| Handover | "Remind me where we left off" | `session-handover.md` |
| Multi-Agent | Not structured | `.agent/rules/qwen-code.md` |
