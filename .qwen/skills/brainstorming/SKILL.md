---
name: brainstorming
description: >
  Use BEFORE any creative work — designing features, planning architecture,
  or clarifying requirements. Triggers the Superpowers brainstorming methodology
  adapted for AI Toolbox. Use PROACTIVELY when starting new features or major changes.
---
# Brainstorming Skill

**Source:** [Superpowers brainstorming skill](https://github.com/obra/superpowers/blob/main/skills/brainstorming/SKILL.md)
**AI Toolbox adaptation:** `.agent/workflows/unified-workflow.md`

## When to Use

- Starting any new feature or major change
- Before writing a plan or touching code
- When requirements are unclear or need exploration

## Instructions

1. **Explore intent** — What does the user actually want? What's the underlying problem?
2. **Identify constraints** — Technical limitations, dependencies, existing patterns
3. **Propose approaches** — At least 2-3 alternatives with trade-offs
4. **Validate design** — Challenge assumptions before committing to a direction
5. **Record decision** — Write to `.agent/memory/architecture-decisions.md`

## Full Rules

Read the complete methodology at:
- `.agent/workflows/unified-workflow.md` (Step 2: BRAINSTORM)
- `.agent/rules/safety-rules.md` (caution areas)

## After Brainstorming

- If direction is clear → proceed to `/boot` then planning
- If still uncertain → ask user for clarification
- Record the architectural decision in `.agent/memory/architecture-decisions.md`
