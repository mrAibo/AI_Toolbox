# AI Toolbox Security Policy

Operative documentation for hook-level security checks and bypass paths.

---

## Heavy Command Policy

Commands with high token cost (build systems, test runners, interpreters) trigger an
explicit confirmation before execution.

**Detection:** The pre-command hook normalizes commands before matching:
- leading whitespace is stripped
- `env` keyword is stripped (`env python` → `python`)
- leading `VAR=val` pairs are stripped (`DEBUG=1 python` → `python`)

This prevents trivial bypasses like `" python"` or `"env python"`.

**Legitimate bypass:** Prefix any heavy command with `rtk` to signal that token
optimization is already applied. The hook allows `rtk <cmd>` unconditionally.

```
rtk python script.py   # allowed — rtk wrapper applied
rtk cargo test         # allowed — rtk wrapper applied
```

**Covered hooks:**
- `.agent/scripts/hook-pre-command.sh` (Claude Code, Unix)
- `.agent/scripts/hook-pre-command.ps1` (Claude Code, Windows)
- `.agent/scripts/hook-pre-command-qwen.sh` (Qwen Code, Unix)
- `.agent/scripts/hook-pre-command-ps1-qwen.ps1` (Qwen Code, Windows)

---

## Secret Scan Policy

### When scans run

| Layer | Trigger | Scope |
|-------|---------|-------|
| Post-write hook | After every file write/edit | Entire file content |
| Commit verification | `git commit` | Only newly added lines in staged diff |

### Patterns detected

- Passwords, API keys, secrets, tokens, auth keys
- Connection strings and database URLs
- PEM/OPENSSH private key blocks
- Hard-blocked file types: `.env`, `*.pem`, `*.key`, `*.p12`, `*.pfx`, `*.jks`

### False-positive filtering (commit scan only)

Lines matching common placeholders are excluded from blocking:
`""`, `null`, `undefined`, `PLACEHOLDER`, `YOUR_*_HERE`, `change-me`, `todo`

### Bypass — when appropriate

Use `SKIP_SECRET_SCAN=true` only when:
- The content is an intentional test fixture with fake credentials
- The content is documentation/examples with clearly fake values
- A human has reviewed the staged diff and confirmed no real secrets

**Unix:**
```bash
SKIP_SECRET_SCAN=true git commit -m "test: add credential fixture for auth tests"
```

**Windows (PowerShell):**
```powershell
$env:SKIP_SECRET_SCAN = 'true'; git commit -m "test: add credential fixture for auth tests"
```

**Audit:** The bypass is visible in shell history. Reference the reason in the commit message
so the decision is traceable in git log.

### Covered scripts

- `.agent/scripts/verify-commit.sh` — commit-time scan (bash)
- `.agent/scripts/verify-commit.ps1` — commit-time scan (PowerShell)
- `.agent/scripts/hook-post-tool-qwen.sh` — post-write scan (Qwen, Unix)
- `.agent/scripts/hook-post-tool-ps1-qwen.ps1` — post-write scan (Qwen, Windows)

---

## Scope and Limitations

These checks are lightweight safeguards against **accidental** exposure and token waste.
They are not a full security sandbox. A motivated actor can work around them.

Complement these hooks with:
- Repository-level secret scanning (e.g., GitHub secret scanning, gitleaks in CI)
- Pre-receive hooks on the remote
- Regular dependency audits
