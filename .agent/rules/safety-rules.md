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

## Change scope rule

Keep changes as small and local as possible.

Avoid broad rewrites when a focused change is enough.
Do not refactor unrelated parts of the system during a targeted fix unless the user asks for it.

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

If a task has real risk, communicate the risk before proceeding.

Examples:
- destructive migrations
- removing compatibility layers
- changing public interfaces
- replacing a key dependency
