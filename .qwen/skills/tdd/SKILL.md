---
name: tdd
description: >
  Test-Driven Development — RED-GREEN-REFACTOR cycle.
  Use when implementing ANY feature or bugfix, before writing production code.
  Adapted from Superpowers TDD skill. Use PROACTIVELY for all code changes.
---
# TDD Skill

**Source:** [Superpowers test-driven-development](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md)
**AI Toolbox adaptation:** `.agent/rules/tdd-rules.md`

## When to Use

- Implementing any new feature
- Fixing any bug
- Refactoring existing code

## Rules

**NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST. Ever.**

### The Cycle

```
RED → VERIFY RED → GREEN → VERIFY GREEN → REFACTOR → COMMIT
```

1. **RED:** Write ONE failing test
2. **VERIFY RED:** Confirm it fails for the RIGHT reason
3. **GREEN:** Minimal code to make it pass
4. **VERIFY GREEN:** All tests pass
5. **REFACTOR:** Clean up the code
6. **COMMIT:** After each green cycle

## Full Rules

Read the complete rules at:
- `.agent/rules/tdd-rules.md`
- `.agent/rules/testing-rules.md`

## Anti-Patterns

- Writing code before tests → Delete it and start over
- Claiming "fixed" without running tests → Run verification
- Multiple fixes simultaneously → One change at a time
- Qualifier language ("should work", "probably fixed") → Evidence only
