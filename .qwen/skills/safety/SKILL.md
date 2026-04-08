---
name: safety
description: >
  Safety rules — prevents destructive actions, enforces caution with secrets,
  credentials, and irreversible operations. Use PROACTIVELY before any risky command.
---
# Safety Rules Skill

**Source:** AI Toolbox `.agent/rules/safety-rules.md`

## When to Use

- Before any destructive command
- When working with credentials or secrets
- Before deleting files or directories
- Before force-push or history rewrites
- Before database migrations

## Forbidden Without Explicit Intent

- Delete files or directories
- Rewrite large parts of the repo
- Replace major technologies
- Force-push or rewrite git history
- Overwrite working configurations blindly
- Remove tests, validation, or safety checks

## Full Rules

Read at: `.agent/rules/safety-rules.md`
