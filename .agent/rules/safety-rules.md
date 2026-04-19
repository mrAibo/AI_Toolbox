# Safety Rules

This file defines the repository safety constraints for AI-assisted work.

Its purpose is to reduce accidental damage, unsafe assumptions, and destructive actions.

---

## Core safety principle

Do not perform destructive, irreversible, or high-risk actions unless the user clearly intended them.

If the intent is unclear, stop and clarify.

---

## Forbidden without explicit intent

Do not do the following unless the user explicitly wants it:
- delete files or directories
- rewrite large parts of the repository
- replace major technologies
- force-push or rewrite git history
- overwrite working configurations blindly
- remove tests, validation, or safety checks

---

## Required caution areas

Be extra careful when working with:
- database schema changes
- migration scripts
- authentication or authorization logic
- secrets, credentials, and tokens
- deployment configuration
- production-like data
- destructive shell commands

---

## Assumption rule

Do not treat assumptions as facts.

If something is inferred rather than verified:
- say so
- document the uncertainty
- avoid irreversible actions based on the assumption

---

## Smallest safe change

Always prefer the smallest change that achieves the goal.

Before implementing, ask: is there a smaller, safer version of this change?
If yes, do that first. Expand only when the smaller version proves insufficient.

Do not refactor, rename, or reorganize anything not directly related to the current task.
Stop and surface scope questions to the user rather than deciding silently.

---

## Scope control

Do not expand the scope of a task without explicit user approval.

If you discover something related that seems worth fixing:
- note it
- finish the current task
- propose the additional work separately

Silent scope expansion is a safety violation, not a helpful bonus.

---

## High-risk and public surfaces

Apply extra scrutiny before changing:
- public APIs and interfaces used by callers outside this module
- schema or protocol definitions that other systems depend on
- authentication, authorization, and security boundaries
- external-facing behavior (webhooks, events, CLI outputs)

For these surfaces: describe the change and its impact before implementing.

---

## Repository integrity rule

The repository should remain understandable and recoverable after each session.

That means:
- memory files should be updated when needed
- unfinished work should be handed over clearly
- no silent breaking changes should be introduced
- the next session should be able to continue safely

---

## Communication rule

If a task has real risk, communicate the risk before proceeding — not after.

Always communicate before acting when:
- the change touches a public or high-risk surface
- you are about to delete, overwrite, or restructure something significant
- you are making an assumption that the user has not confirmed
- scope is growing beyond what was originally requested
