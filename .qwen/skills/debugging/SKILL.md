---
name: debugging
description: >
  Systematic debugging methodology from Superpowers. Use when encountering ANY
  bug, test failure, or unexpected behavior — BEFORE proposing fixes.
---
# Debugging Skill

**Source:** [Superpowers systematic-debugging](https://github.com/obra/superpowers/blob/main/skills/systematic-debugging/SKILL.md)
**AI Toolbox adaptation:** `.agent/workflows/bug-fix.md`

## When to Use

- ANY bug or test failure
- Unexpected behavior
- Before proposing any fix

## 4-Phase Process

1. **Root Cause** — Read errors, reproduce, check recent changes
2. **Pattern Analysis** — Find working examples, compare with broken code
3. **Hypothesis** — Single-variable test to confirm cause
4. **Fix** — With failing test first (TDD), then verify

## Stop Rule

After 3 failed fix attempts → **question the architecture**, don't keep patching.

## Full Rules

Read at:
- `.agent/workflows/bug-fix.md`
- `.agent/rules/testing-rules.md`
