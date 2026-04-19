# Stack Rules

This file defines stack-level constraints and preferences for the project.

Its purpose is to prevent random tool choices, uncontrolled framework drift, and unnecessary complexity.

---

## General rule

Do not introduce a new language, framework, library, database, or major build tool without a reason.

If a new dependency is necessary:
- explain why it is needed
- explain what problem it solves
- compare it with at least one simpler alternative
- record the decision in `architecture-decisions.md`

---

## Simplicity first

Prefer the simplest solution that correctly solves the problem.

Before adding complexity:
- ask whether a simpler mechanism already exists in the project
- ask whether the added complexity will outlast this task
- prefer boring and predictable over clever and fragile

A solution that requires explanation is harder to maintain than one that does not.

---

## Abstraction discipline

Do not introduce a new abstraction unless it eliminates repeated, concrete complexity.

An abstraction is justified only when:
- the same pattern recurs in at least two real places
- a simpler mechanism does not already handle it
- the abstraction makes the code easier to understand, not harder

When in doubt, duplicate first. Refactor only when the duplication pattern is clear.

---

## Stack selection principles

- Prefer the smallest stack that solves the problem
- Prefer existing project tools over new tools
- Prefer standard libraries over extra dependencies when practical
- Prefer stable, well-documented technologies over trendy ones
- Prefer explicit compatibility over assumptions

---

## Language and framework discipline

- Do not mix multiple paradigms or frameworks without a clear reason
- Do not introduce a framework just to avoid writing a small amount of code
- Avoid dependency sprawl
- Keep the stack understandable for future sessions

---

## Build and runtime discipline

- Keep the build process simple and reproducible
- Avoid unnecessary code generation layers
- Avoid hidden magic in setup and execution
- Prefer commands and workflows that can be explained in a short runbook

---

## AI workflow tools

The following tools are preferred in this repository when available:

- `rtk` for heavy terminal output and log compression
- `Beads` for task tracking and execution order
- `AGENT.md` and `.agent/memory/*.md` for durable workflow memory

---

## Documentation rule

Any meaningful stack decision must be reflected in:
- `architecture-decisions.md` for the decision itself
- `integration-contracts.md` if interfaces are affected
- `runbook.md` if operating procedures are affected
