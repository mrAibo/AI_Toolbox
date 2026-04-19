# AI Toolbox — Central Client Configuration

## Why this directory exists (PR4)

Before PR4, client capabilities and file-install mappings lived in two places that
were never in sync:

| Before | Problem |
|--------|---------|
| `.agent/config/client-capabilities.json` | Marked `"DOCUMENTATION ONLY"` — bootstrap never read it |
| `bootstrap.sh` / `bootstrap.ps1` | ~250 lines of hard-coded client logic, duplicated for Unix + Windows |

Drift had already occurred: `codex` and `opencode` were handled by bootstrap but
absent from the capability matrix.

**This directory introduces a single source of truth.** `config.json` is the
canonical client registry. All client additions, tier changes, and template
remappings start here.

---

## Source-of-Truth Rules

1. **`config.json` is authoritative** — edit here first when adding or changing a client.
2. **Templates in `.agent/templates/clients/`** define file content.
3. **Repo-root client files** (`CLAUDE.md`, `QWEN.md`, `.cursorrules`, …) are
   *generated outputs* — restore missing ones with the generator.
4. **`generate_client_files.py --sync`** re-installs any missing template-backed files.
5. Bootstrap scripts remain the install mechanism for now; a future PR will
   delegate template-backed installation to the generator directly.

---

## Generated / managed files

| Client | Router file | Config file | Extra files | Managed by |
|--------|------------|-------------|-------------|------------|
| claude-code | `CLAUDE.md` | `.claude.json` | — | bootstrap-inline + template |
| qwen-code | `QWEN.md` | — | `.qwen/settings.json` | template (router); bootstrap-inline (settings) |
| antigravity | `SKILL.md` | — | — | manual |
| cline | `.clinerules` | — | — | bootstrap-inline |
| windsurf | `.windsurfrules` | — | — | bootstrap-inline |
| cursor | `.cursorrules` | — | — | bootstrap-inline |
| gemini-cli | `GEMINI.md` | — | — | bootstrap-inline |
| aider | `CONVENTIONS.md` | `.aider.conf.yml` | — | template |
| codex | — | — | `.codex/hooks.json`, `.codex/config.toml` | template |
| opencode | — | — | `opencode.json` | template |

**bootstrap-inline**: file content is a heredoc inside `bootstrap.sh` / `bootstrap.ps1`.  
**template**: file is copied from `.agent/templates/clients/` by the generator or bootstrap.

---

## Generator quick-start

```bash
# Check which template-backed files are missing (dry-run)
python3 .agent/scripts/generate_client_files.py --check

# Install missing template-backed files
python3 .agent/scripts/generate_client_files.py --sync

# Or via wrappers:
bash .agent/scripts/generate-client-files.sh --sync          # Unix/macOS
powershell -ExecutionPolicy Bypass \
  -File .agent/scripts/generate-client-files.ps1 -Mode sync  # Windows
```

---

## Migration for existing repos

Repos that have already run `bootstrap.sh` / `bootstrap.ps1` do **not** need to
re-run bootstrap. Their client files are already present and will not be overwritten
(the generator respects the same guard: only writes when the target is missing or empty).

### Adding a new client (post-PR4 workflow)

1. Add an entry to `.ai-toolbox/config.json` (follow the existing schema).
2. Add a template file to `.agent/templates/clients/` if the client needs one.
3. Run `generate_client_files.py --sync` to install the file.
4. *(Future)* Update `bootstrap.sh` / `bootstrap.ps1` to call the generator for
   this client instead of duplicating the logic inline.
