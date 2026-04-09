---
name: branch-finish
description: >
  Branch completion workflow — testing, merging, and cleanup after work is done.
  Use PROACTIVELY when implementation is complete and all tests pass. Adapted from Superpowers.
---
# Branch Finish Skill

**Source:** [Superpowers finishing-a-development-branch](https://github.com/obra/superpowers/blob/main/skills/finishing-a-development-branch/SKILL.md)
**AI Toolbox adaptation:** `.agent/workflows/branch-finish.md`

## When to Use

- All tests pass
- Implementation is complete
- Ready for integration decision

## Steps

1. **Verify** — Run full test suite, confirm all pass
2. **Review** — Check for debug statements, TODOs, incomplete work
3. **Decide** — 4 options:
   - Merge to main
   - Create PR
   - Keep branch for later
   - Discard changes
4. **Clean up** — Delete temp branches, close tasks

## Full Rules

Read at: `.agent/workflows/branch-finish.md`
