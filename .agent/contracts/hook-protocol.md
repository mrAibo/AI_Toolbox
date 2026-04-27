# AI Toolbox Hook Protocol

This contract makes explicit what each AI client's hook system can and cannot do.
The machine-readable companion is [hook-protocol.json](hook-protocol.json), which is
validated against `.agent/schema/hook-protocol.schema.json` in CI.

## Why this exists

Without an explicit contract, every hook script encodes implicit assumptions about its
client. When client APIs evolve, divergence is silent. The `guarantees` block here is
the single source of truth for what is structurally possible — not what we currently use.

## The `guarantees` block

For every supported client, four boolean guarantees are declared:

| Guarantee             | Meaning                                                                  |
|-----------------------|--------------------------------------------------------------------------|
| `can_block`           | Hook can prevent the tool call by returning non-zero or a structured deny.|
| `can_modify_input`    | Hook can rewrite the tool input before execution.                         |
| `can_modify_output`   | Hook can rewrite tool output after execution (e.g. PostToolUse handlers). |
| `can_inject_context`  | Hook can add system prompts, files, or prefixes into the model's window.  |

A `false` here is a **hard system limit, not an implementation gap.** Don't write a
hook expecting Codex to inject context — the Codex CLI doesn't read hook stdout.

## Per-client summary

### Claude Code (`.claude.json`) — Full

All four guarantees `true`. Hooks return JSON over stdout:

```json
{
  "decision": "allow",
  "hookSpecificOutput": {
    "permissionDecision": "ask",
    "permissionDecisionReason": "...",
    "additionalContext": "..."
  }
}
```

### Qwen Code (`.qwen/settings.json`) — Full

Mirrors Claude's protocol. Adds the `PreCompact` event for surviving context compaction.

### Codex CLI (`.codex/hooks.json`) — Block only

`can_block: true`, everything else `false`. Hooks signal via **exit code only**:

- `0` → continue
- `1` → block, show `statusMessage` to user

Stdout is **ignored**. Do not assume context injection works.

### OpenCode (`opencode.json`) — Slash-command driven

OpenCode has no generic hook API. AI Toolbox integrates through:

- `permission` config (edit/bash gating → `can_block: true`)
- Slash-command templates (`/boot`, `/sync`, `/handover`) whose output the agent
  reads → `can_inject_context: true`

## Adding a new client

1. Determine the four guarantees from the client's documented API.
2. Add an entry to `hook-protocol.json` with each event the toolbox installs.
3. Run `bash .agent/scripts/test-hook-contract.sh <client>` (added in this milestone).
4. Add the client to `.ai-toolbox/config.json` if not already present.

## Testing

`test-hook-contract.sh <client>` does three things:

1. Loads `hook-protocol.json` and validates the entry against the schema.
2. For each event, simulates the documented stdin and runs the implementation
   script in a sandboxed temp dir.
3. Verifies the script's exit code and stdout shape match the contract.

The CI matrix runs this for every Full/Standard tier client on every push, so a
divergence between the contract and the actual hook behavior fails fast.

## Conventions for hook authors

- **Match the contract first.** If your script can't honor the declared
  `stdout_format`, update the contract — don't silently diverge.
- **Treat `can_modify_*: false` as a hard limit.** When you discover a need that
  the platform doesn't support, don't fake it via stderr or environment hacks.
  Instead, surface the limitation in a structured error.
- **Use exit codes from the registry.** Heavy command blocks emit
  `CONTRACT_VIOLATION` (exit 20) only when the hook itself misbehaves —
  *not* when the user runs an unwrapped heavy command.
