# Universal AI Workflow & Triggers

## Boot sequence
At the beginning of a fresh session:
1. Read `.agent/memory/architecture-decisions.md`
2. Read `.agent/memory/integration-contracts.md`
3. Report the current state briefly before starting new work

## New project
If the user asks to create a new project or large feature:
1. Do not code immediately
2. Brainstorm first
3. Record the architecture direction in memory
4. Create tasks in Beads
5. Work only on the next ready task

## Execution rules
- Use verification-first or test-first workflow when possible
- Heavy terminal commands should be prefixed with `rtk`
- Large `.log` files should be read with `rtk read <file>`
- Do not claim completion without verification

## Memory rules
- Architecture choices go to `.agent/memory/architecture-decisions.md`
- Integration changes go to `.agent/memory/integration-contracts.md`
- Keep project context durable and concise
