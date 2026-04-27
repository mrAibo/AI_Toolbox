# AI Toolbox Plugins

Plugins are file-based extensions that contribute additional rules and
context hints to the toolbox without runtime code. They are introduced in
v1.5 (see [`plan: AI Toolbox V1.5`](../memory/architecture-decisions.md)).

> A plugin is **just a directory** with a `manifest.json` and at least one
> markdown rules file. No build step, no install command, no daemon.

## Why plugins (and why not plugins)

The toolbox already provides universal rules (`safety-rules.md`, `tdd-rules.md`,
`coding-discipline.md`, …). Plugins are for the **stack-specific** layer:
React conventions, Python type-checking, Docker patterns, etc. They live
*next to* the universal rules; they don't replace them.

Things plugins **do not** do:
- They do not execute code.
- They do not install dependencies.
- They do not wire hooks. (The hook contract is one layer below.)
- They do not change the AGENT.md structure beyond appending references in
  a clearly-marked region.

## Layout

```
.agent/plugins/
├── README.md                    ← this file
├── nodejs/
│   ├── manifest.json
│   └── rules.md
└── python/
    ├── manifest.json
    └── rules.md
```

Each plugin directory must:

1. Be named in lowercase with hyphens (`my-plugin`, `next-js`).
2. Match the `name` field in its `manifest.json`.
3. Contain at least one markdown rules file referenced by `manifest.json`.

## Manifest format

`manifest.json` is validated against [`plugin-manifest.schema.json`](../schema/plugin-manifest.schema.json) in CI.
Minimum shape:

```json
{
  "$schema": "../../schema/plugin-manifest.schema.json",
  "name": "nodejs",
  "version": "0.1.0",
  "description": "Node.js / npm conventions",
  "rules": ["rules.md"],
  "context_hints": ["package.json", "**/*.js", "**/*.mjs"],
  "priority": 100
}
```

| Field                       | Required | Notes                                                        |
|-----------------------------|----------|--------------------------------------------------------------|
| `name`                      | yes      | Must match the directory name.                               |
| `version`                   | yes      | Semver. Recorded in `lock.json` (Phase C).                   |
| `description`               | no       | One-line summary, ≤ 200 chars.                               |
| `rules`                     | no       | Markdown files (relative to plugin dir) appended to AGENT.md.|
| `context_hints`             | no       | Glob patterns weighted up by `context build` (Phase C).       |
| `priority`                  | no       | Sort order. Higher overrides earlier. Default 100.           |
| `conflict_resolution`       | no       | `override` / `merge` / `fail`. Default `merge`.              |
| `requires_toolbox_version`  | no       | Minimum required toolbox version.                            |
| `tags`                      | no       | Free-form for searchability.                                 |

## How plugins land in AGENT.md

Bootstrap scans `.agent/plugins/*/manifest.json`, sorts by ascending
`priority`, and replaces the content between these markers in AGENT.md:

```markdown
<!-- AI_TOOLBOX_PLUGINS:START -->
<!-- AI_TOOLBOX_PLUGINS:END -->
```

Anything outside the markers is preserved. Re-running bootstrap is
idempotent — installing or removing a plugin and re-running bootstrap
updates the references cleanly.

## Conflict resolution

When two plugins reference rules that contradict each other, the strategy
is governed by their `conflict_resolution` field:

- `merge` (default) — both rule files are referenced, in priority order.
  The agent reads both and resolves at runtime by reading the order.
- `override` — the higher-priority plugin's rules are referenced; the
  lower-priority plugin's referenced rules are skipped.
- `fail` — bootstrap aborts with `PLUGIN_CONFLICT` (exit 51) when any
  conflict is detected. Use this for plugins that *must* be exclusive
  with each other.

Conflict detection currently inspects `rules` filenames only. Future
versions may compare rule content.

## Adding a plugin

1. `mkdir .agent/plugins/<name>/`
2. Write `manifest.json` (validate with `ai-toolbox validate` once Phase C
   exposes plugin validation; today, run the schema check from CI).
3. Write `rules.md` with the conventions you want the agent to follow.
4. Run `ai-toolbox bootstrap` (or `ai-toolbox bootstrap --dry-run` first
   to preview).
5. Verify the plugin reference appears between the markers in `AGENT.md`.

## Removing a plugin

Just delete the directory and re-run bootstrap. The reference is removed
from AGENT.md automatically.

## Examples

The repository ships two reference plugins as a starting template:

- [`nodejs/`](nodejs/) — Node.js / npm conventions
- [`python/`](python/) — Python / pip / venv conventions

Both are minimal on purpose. Copy their structure when authoring your own.
