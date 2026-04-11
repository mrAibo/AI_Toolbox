---
name: parallel
description: >
  Parallel execution rules — when and how to use parallel agents and tool calls.
  Use PROACTIVELY when facing 2+ independent tasks. Prevents sequential anti-patterns.
---
# Parallel Execution Skill

**Source:** AI Toolbox `.agent/rules/parallel-execution.md`

## Mandatory Parallelization

- Fetching 2+ URLs simultaneously
- Reading 3+ independent files
- Running independent verification checks
- Reviewing multiple files
- Researching unrelated sub-topics

## Self-Check Before Execution

1. Do they depend on each other's output? → If NO: PARALLELIZE
2. Would sequential execution waste time? → If YES: PARALLELIZE
3. Are there 2+ independent sub-tasks? → If YES: PARALLELIZE

## Agent Types

- `Explore` — Fast file/keyword search, URL fetching
- `general-purpose` — Complex research, multi-step analysis

## Full Rules

Read at: `.agent/rules/parallel-execution.md`
