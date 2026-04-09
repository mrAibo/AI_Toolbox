# Complete Audit Report — AI Toolbox

**Date:** 2026-04-09
**Scope:** Full security, code quality, and test coverage audit
**Auditors:** ai-toolbox-security, ai-toolbox-reviewer, ai-toolbox-tester

---

## Executive Summary

| Category | Critical | High | Medium | Low | Info | Positive |
|---|---|---|---|---|---|---|
| **Security** | 2 | 2 | 7 | 4 | 0 | 6 |
| **Code Quality** | 0 | 0 | 12 | 9 | 6 | 0 |
| **Test Coverage** | 3 | 0 | 0 | 0 | 0 | 0 |

**Overall Verdict:** ⚠️ Changes Required — 2 Critical Security Issues, 12 Medium Code Quality Issues, 3 Critical Test Coverage Gaps

---

## Security Findings

### Critical (2)

| # | File | Issue | Fix |
|---|---|---|---|
| S1 | `hook-pre-command.sh:44-59` | Shell-to-Python code injection via `$tool` interpolation | ✅ Already fixed — uses `os.environ.get()` |
| S2 | `mcp-configs.json:27-28` | Filesystem MCP unrestricted root access (`"."`) | Scope to specific directories, exclude `.git/` and `.agent/scripts/` |

### High (2)

| # | File | Issue | Fix |
|---|---|---|---|
| S3 | `commit-msg.sh:11-14` | Path validation bypass via symlink/relative path traversal | Use `realpath` to resolve absolute path before validation |
| S4 | `hook-post-tool-qwen.sh:28-32` | Symlink traversal — prefix match doesn't prevent `../../../etc/passwd` | Use `realpath -m` to resolve before comparison |

### Medium (7)

| # | File | Issue | Status |
|---|---|---|---|
| S5 | All `.ps1` hook configs | `ExecutionPolicy Bypass` at 18+ locations | Document risk, consider `RemoteSigned` |
| S6 | `setup.sh:174`, `setup.ps1` | `beads@v0.63.3` — pinned but no checksum verify | Add SHA256 note in docs |
| S7 | `mcp-qwen.json` | MCP packages unpinned (`@latest`) | Pin versions like `mcp-configs.json` |
| S8 | `bootstrap.sh/ps1` | Git hooks overwritten without user notification | Add warning before installation |
| S9 | `README.md:111` | `claude-code-templates@latest` unpinned | Pin to `@0.1.0` |
| S10 | `validate-client-capabilities.sh:17` | `$CONFIG_FILE` interpolated into Python string | Use `os.environ` |
| S11 | `.github/workflows/ci.yml:116` | 14 shellcheck rules excluded | Document why each is excluded |

### Low (4)

| # | File | Issue | Status |
|---|---|---|---|
| S12 | `hook-pre-command.sh` | Race condition on `.tool-stats.json` | Low impact — cosmetic only |
| S13 | `hook-stop.sh` | No 10-entry cap on session-handover growth | ✅ Already fixed |
| S14 | `hook-session-end-qwen.sh` | `python3` without fallback check | Add `command -v python3` guard |
| S15 | `setup.ps1:6` | `Set-Location` without repo validation | Acceptable — git fallback exists |

### Positive (6)

| # | Finding |
|---|---|
| P1 | ✅ No hardcoded secrets anywhere in the project |
| P2 | ✅ `.tool-stats.json` correctly in `.gitignore` |
| P3 | ✅ MCP rules explicitly forbid storing secrets |
| P4 | ✅ PostToolUse hooks scan for secrets (defense-in-depth) |
| P5 | ✅ CI uses `persist-credentials: false` |
| P6 | ✅ No `eval`/`exec`/`source` in any scripts |

---

## Code Quality Findings

### Medium (12)

| # | File | Issue | Effort |
|---|---|---|---|
| CQ1 | 5 scripts with `set -e`, 12 without | Standardize: no `set -e` in hooks, add comments | Low |
| CQ2 | `hook-stop.sh:42-58` | Duplicate Python blocks (python3/python fallback) | Low |
| CQ3 | `hook-pre-command.sh:44-72` | Same duplicate Python pattern | Low |
| CQ4 | `sync-task.sh:7` | `git rev-parse` without `2>/dev/null \|\| pwd` fallback | Low |
| CQ5 | `sync-task.sh:74-79` | Temp file without cleanup trap | Low |
| CQ6 | `commit-msg.sh:11-14` | Path validation too restrictive for absolute paths | Low |
| CQ7 | `sync-task.ps1:29` | Typo: "MANually" → "MANUALLY" | Trivial |
| CQ8 | `doctor.ps1:8` | `$script:Warnings++` scope issue | Low |
| CQ9 | `bootstrap.ps1` vs `bootstrap.sh` | Emoji inconsistency in generated files | Low |
| CQ10 | `README.md` vs `AGENT.md` vs `setup.sh` | 3 different rtk install methods | Low |
| CQ11 | `validate-client-capabilities.sh:17` | Shell injection via `$CONFIG_FILE` in Python | Medium |
| CQ12 | All 5 hook-ps1 scripts | Duplicate input-parsing pattern (~15 lines each) | Medium |

### Low (9)

| # | File | Issue |
|---|---|---|
| CQ13 | `hook-post-tool-qwen.sh:67` | Trailing comma in `$SECRET_FOUND` output |
| CQ14 | `hook-session-end-qwen.sh:22` | `python3` without availability check |
| CQ15 | All `.ps1` scripts | No `[CmdletBinding()]` |
| CQ16 | `doctor.ps1` | No shellcheck equivalent check |
| CQ17 | `bootstrap.ps1` vs `bootstrap.sh` | Guard clause order differs |
| CQ18 | `setup.ps1:267` | `[NEXT]` vs `🚀` inconsistency |
| CQ19 | `hook-stop.ps1:46-53` | Regex join precedence issue |
| CQ20 | `bootstrap.sh:2` | UTF-8 encoding corruption (`â€"` ) |
| CQ21 | `setup.sh:13-15` | UTF-8 emoji corruption (`ðŸ¤–`) |

### Info (6)

| # | Issue |
|---|---|
| CQ22 | `integration-plan-ARCHIVED.md` should move to `archive/` |
| CQ23 | `.claude.json` root duplicate of template |
| CQ24 | `client-capabilities.json` uses `_comment` keys |
| CQ25 | `GEMINI.md` contains template placeholders |
| CQ26 | `QWEN.md` root vs template — memory order inconsistent with AGENT.md |
| CQ27 | `bootstrap.sh` missing `.tool-stats.json` in `.gitignore` addition |

---

## Test Coverage Findings

### Critical Gaps (3)

| # | Gap | Impact | Effort to Fix |
|---|---|---|---|
| TC1 | **Zero functional hook tests** — 14 hook files, 0 behavior tests | Hooks could silently fail without detection | Medium |
| TC2 | **No integration tests** — Boot→Task→Handover workflow never tested end-to-end | Workflow regressions undetected | High |
| TC3 | **CI skips all .ps1 tests** — `pwsh` not on `ubuntu-latest` | PowerShell scripts untested in CI | Low |

### Current Coverage

| Component | Coverage | Notes |
|---|---|---|
| CI Pipeline | 35% | 11 steps, all static/structural |
| Script Tests | 10% | Only `bash -n` syntax checks |
| Doctor | 0% | Self-check tool untested |
| Bootstrap Parity | 50% | String matching only, no content comparison |
| Hooks | 0% | ❌ Critical |
| Integration | 0% | ❌ Critical |
| Documentation | 20% | Internal links checked, commands not verified |
| **Overall** | **~15%** | |

### Quick Wins

| Fix | Effort | Coverage Gain |
|---|---|---|
| Install `pwsh` in CI (`sudo apt install powershell`) | Low | +5% |
| Remove `|| true` from shellcheck step | Low | Real gating |
| Add JSON output validation tests for all hooks | Medium | +15% |
| Add 1 integration test (boot → sync → handover) | High | +10% |

---

## Prioritized Action Plan

### 🔴 Immediate (This Session)

| # | Action | Files |
|---|---|---|
| 1 | Fix MCP Filesystem scope (S2) | `mcp-configs.json`, `mcp-qwen.json` |
| 2 | Fix path validation with `realpath` (S3, S4) | `commit-msg.sh`, `hook-post-tool-qwen.sh` |
| 3 | Pin MCP packages in `mcp-qwen.json` (S7) | `mcp-qwen.json` |
| 4 | Fix `$CONFIG_FILE` injection (S10) | `validate-client-capabilities.sh` |

### 🟡 Near-Term (Next Session)

| # | Action | Files |
|---|---|---|
| 5 | Standardize `set -e` usage with comments (CQ1) | 17 .sh files |
| 6 | Extract duplicate Python blocks into functions (CQ2, CQ3, CQ12) | 3 hook files |
| 7 | Fix `sync-task.sh` git fallback (CQ4) + temp cleanup (CQ5) | `sync-task.sh` |
| 8 | Unify rtk install instructions (CQ10) | README.md, AGENT.md, setup.sh |
| 9 | Fix UTF-8 encoding in script headers (CQ20, CQ21) | bootstrap.sh, setup.sh |

### 🔵 Long-Term (Future)

| # | Action | Effort |
|---|---|---|
| 10 | Add functional tests for all 14 hooks | Medium |
| 11 | Add integration test (boot→task→handover) | High |
| 12 | Add `pwsh` to CI for .ps1 testing | Low |
| 13 | Remove `|| true` from shellcheck CI | Low |
| 14 | Document all shellcheck exclusions | Low |
| 15 | Add SHA256 checksums for binary downloads | Low |

---

## Audit Conclusion

The AI Toolbox has **solid foundations**: no secrets, good defense-in-depth, proper .gitignore usage, MCP security rules. However, **2 critical security issues** and **3 critical test coverage gaps** must be addressed before production use.

**Security:** 2/2 Critical issues need immediate fixes.
**Code Quality:** 12 medium issues — mostly consistency and maintainability.
**Testing:** 15% overall coverage — hooks and integration are the biggest gaps.
