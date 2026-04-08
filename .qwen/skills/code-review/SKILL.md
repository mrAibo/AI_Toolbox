---
name: code-review
description: >
  Code review before merges and after major changes. Use when completing tasks,
  implementing features, or before merging. Adapted from Superpowers code-review skill.
---
# Code Review Skill

**Source:** [Superpowers requesting-code-review](https://github.com/obra/superpowers/blob/main/skills/requesting-code-review/SKILL.md)
**AI Toolbox adaptation:** `.agent/workflows/code-review.md`

## When to Use

- After completing a task or feature
- Before merging to main
- After major refactoring

## Review Checklist

1. **Safety** — No destructive operations without confirmation
2. **Testing** — All new code has tests
3. **TDD** — Tests written before implementation
4. **Security** — No exposed secrets or credentials
5. **Quality** — Follows project conventions, no dead code

## Using Sub-Agents for Review

For thorough reviews, spawn parallel agents:
- Agent 1: Correctness & Security
- Agent 2: Code Quality
- Agent 3: Performance
- Agent 4: Undirected Audit

## Full Rules

Read at: `.agent/workflows/code-review.md`
