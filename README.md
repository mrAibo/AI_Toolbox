# AI Toolbox

> **Make any terminal AI agent reliable.** Persistent memory, enforced safety,
> stack-aware rules — file-based, no daemon, no vendor lock-in.

[![Latest Release](https://img.shields.io/github/v/release/mrAibo/AI_Toolbox?label=version)](https://github.com/mrAibo/AI_Toolbox/releases)
[![CI](https://github.com/mrAibo/AI_Toolbox/actions/workflows/ci.yml/badge.svg)](https://github.com/mrAibo/AI_Toolbox/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## The problem

Terminal AI agents are powerful — and they forget. Across a single feature you
hit five recurring failure modes:

- The agent **re-reads the same files** every session because nothing persists.
- It **plans in chat** (which gets compacted) instead of in version control.
- It **claims work is done** without running tests.
- It **dumps 8,000 lines** of test output into the context window and loses focus.
- Every client has a **different hook format**, so guardrails don't transfer.

## The fix

A small, file-based protocol that lives next to your code.

| Layer | What it does |
|-------|-------------|
| **Memory** (`.agent/memory/`) | ADRs, integration contracts, session handover, audit log — survives restarts |
| **Rules** (`.agent/rules/`) | TDD, safety, surgical changes, parallel execution — enforced by hooks where supported |
| **Plugins** (`.agent/plugins/`) | Stack-specific conventions (Node, Python, …) — declarative, no runtime |
| **Contracts** (`.agent/contracts/`) | Hook protocol per client with **explicit guarantees**, structured error codes |
| **CLI** (`./ai-toolbox`) | One stable entry point: `doctor`, `setup`, `bootstrap`, `validate`, `migrate` |

Works with **11 AI clients** out of the box.

---

## What's new in v1.5

- 🛠️  **`ai-toolbox` CLI** — one stable entry replacing `bash .agent/scripts/...`
- 📐 **JSON-Schema everywhere** — config, plugins, hook contracts, doctor output
- 🔌 **Plugins** — drop a directory, get stack-specific rules into `AGENT.md`
- 🧪 **`bootstrap --dry-run`** — preview every file change before it happens
- 🚦 **CI compatibility matrix** — every Full-Tier client's hook contract verified on every push
- 📋 **Structured errors** — every failure has a stable code (`CONFIG_ERROR`, `PLUGIN_CONFLICT`, …) with a fix instruction
- 🔁 **`ai-toolbox migrate`** — versioned, idempotent config upgrades

Full history in [CHANGELOG.md](CHANGELOG.md).

---

## Quick start

### Option 1: Clone + setup *(recommended)*

```bash
git clone https://github.com/mrAibo/AI_Toolbox.git my-project
cd my-project
./ai-toolbox setup
```

Setup auto-detects your AI client, installs optional tools (rtk, Beads), and
configures hooks. Anything that needs your action prints a numbered checklist.

### Option 2: GitHub Template

On the [repository page](https://github.com/mrAibo/AI_Toolbox) click
**"Use this template" → "Create a new repository"**, clone, and run setup.
Full step-by-step guide: [USE_AS_TEMPLATE.md](USE_AS_TEMPLATE.md).

### Option 3: AI-assisted

Paste this into any supported AI client:

> Clone https://github.com/mrAibo/AI_Toolbox.git to a temp folder, copy `.agent/`
> and `AGENT.md` into the current directory, then run `./ai-toolbox setup`.
> Read `AGENT.md` when done and confirm.

### Verify

```bash
./ai-toolbox doctor              # health check
./ai-toolbox doctor --explain    # with fix instructions
```

---

## What it looks like

**Day 1.** You ask the agent for a refactor. Before writing code, it reads
`.agent/memory/architecture-decisions.md`, picks up unfinished work from
`session-handover.md`, and announces the active rules:

```
✅ AI Toolbox Active
  → rtk: installed
  → Beads: installed
📋 Skill activated: TDD Rules — RED phase
```

**Day 2, new session.** Same agent (or a different one — `claude`, `qwen`, `codex`)
runs the same boot sequence and resumes where day 1 ended. No "let me read your codebase first."

**Day 3.** It runs `npm test`. The pre-command hook intercepts and swaps in `rtk
npm test` — output drops from 8,000 to 30 lines. A test fails. The agent reads
the 3 failing tests, not the noise.

**Day 4.** You add a React plugin:

```bash
mkdir -p .agent/plugins/react
cat > .agent/plugins/react/manifest.json <<EOF
{
  "name": "react", "version": "0.1.0",
  "rules": ["rules.md"],
  "context_hints": ["src/**/*.tsx"],
  "priority": 100
}
EOF
echo "# React conventions ..." > .agent/plugins/react/rules.md
./ai-toolbox bootstrap
```

The plugin reference appears in `AGENT.md` automatically. Re-run is idempotent.

---

## CLI reference

```bash
./ai-toolbox doctor    [--json] [--explain]      # health check
./ai-toolbox setup     [--silent]                # interactive client detection
./ai-toolbox bootstrap [--dry-run]               # idempotent file generation
./ai-toolbox validate  [--json]                  # schema-validate config
./ai-toolbox migrate   [--target X] [--dry-run]  # advance toolbox_version
./ai-toolbox sync      [--json]                  # refresh current-task.md
```

`context`, `simulate`, and `stats` are reserved for v1.6 (Phase C — adaptive
context building). They exit 60 with a clear message until then.

Full reference: [docs/cli-reference.md](docs/cli-reference.md).

---

## Client support

| Client | Tier | Auto hooks | Multi-agent | Router |
|--------|------|-----------|------------|--------|
| Claude Code | Full | ✅ | ✅ | `CLAUDE.md` |
| Qwen Code | Full | ✅ | ✅ | `QWEN.md` |
| Antigravity | Full | ✅ | ✅ | `SKILL.md` |
| Codex CLI | Full | ✅ | block-only | `CODERULES.md` |
| OpenCode | Full | ✅ | ✅ | `OPENCODERULES.md` |
| Cursor | Standard | manual | — | `.cursorrules` |
| RooCode / Cline | Standard | manual | — | `.clinerules` |
| Windsurf | Standard | manual | — | `.windsurfrules` |
| Gemini CLI | Basic | — | — | `GEMINI.md` |
| Aider | Basic | — | — | `CONVENTIONS.md` |
| Pi (Inflection) | Basic | — | — | `PI.md` |

**Tiers.** *Full* = hooks auto-enforce every rule, multi-agent parallel work
available. *Standard* = hooks work but require manual invocation. *Basic* =
soft reminders only, no hook support.

Hook capabilities per client (block / modify input / modify output / inject
context) are declared in [`.agent/contracts/hook-protocol.json`](.agent/contracts/hook-protocol.json) — and verified in CI on every push.

---

## How it works

Every session follows a fixed sequence defined in [`AGENT.md`](AGENT.md):

```
Session start  →  read .agent/memory/memory-index.md
               →  ./ai-toolbox sync   (loads current-task.md)
               →  read session-handover.md (unfinished work)

During work    →  pre-command hook blocks heavy commands without rtk
               →  TDD rules enforce RED → GREEN → REFACTOR
               →  large source-file reads trigger a "use git diff" reminder

Session end    →  hook-stop writes session-handover.md
               →  audit.log appended (append-only, gitignored)
```

The agent never loses context between sessions.

---

## Optional tools

| Tool | Why | Without it |
|------|-----|-----------|
| **[rtk](https://github.com/rtk-ai/rtk)** | Compresses test/build output 60–90% | Heavy commands eat tokens |
| **[Beads](https://github.com/steveyegge/beads)** | CLI task graph — keeps plans out of chat | Manual edits to `current-task.md` |
| **[MCP servers](docs/mcp-guide.md)** | Live docs (Context7), filesystem, fetch | No live docs / web lookup |

```bash
cargo install --git https://github.com/rtk-ai/rtk
go install github.com/steveyegge/beads/cmd/bd@v0.63.3
```

`./ai-toolbox setup` installs these for you if you confirm the prompts.

---

## Documentation

| Guide | What's in it |
|-------|-------------|
| [AGENT.md](AGENT.md) | Agent's master execution contract — boot sequence, workflows, rules |
| [QUICKSTART.md](QUICKSTART.md) | 5-minute walk-through |
| [INSTALL.md](INSTALL.md) | Detailed installation across all clients |
| [USE_AS_TEMPLATE.md](USE_AS_TEMPLATE.md) | GitHub Template flow |
| [docs/cli-reference.md](docs/cli-reference.md) | All `ai-toolbox` subcommands and flags |
| [.agent/plugins/README.md](.agent/plugins/README.md) | Plugin authoring guide |
| [.agent/contracts/hook-protocol.md](.agent/contracts/hook-protocol.md) | What hooks can / cannot do per client |
| [.agent/contracts/error-codes.md](.agent/contracts/error-codes.md) | Structured error registry |
| [docs/mcp-guide.md](docs/mcp-guide.md) | MCP server setup |
| [docs/faq.md](docs/faq.md) | FAQ |
| [CHANGELOG.md](CHANGELOG.md) | Release history |

---

## Contributing

PRs welcome. Three rules of engagement:

1. **Schemas first.** New config fields land in `.agent/schema/` *before* they're
   read by code.
2. **Hook contract.** New client integrations declare their `guarantees` block
   in [`hook-protocol.json`](.agent/contracts/hook-protocol.json) and pass the
   CI matrix.
3. **No more than 9 top-level CLI verbs.** New functionality is a flag or a
   sub-subcommand, not a new verb.

Run `./ai-toolbox doctor` and the test suite (`pytest tests/`) before you push.

---

## License

MIT — see [LICENSE](LICENSE).
