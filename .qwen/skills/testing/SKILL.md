---
name: testing
description: >
  Testing rules and verification discipline. Use when running tests, verifying
  changes, or before claiming any work complete. Adapted from AI Toolbox testing rules.
---
# Testing Skill

**Source:** AI Toolbox `.agent/rules/testing-rules.md`

## When to Use

- After any code change
- Before claiming work is done
- When verifying bug fixes
- Before commits or merges

## Core Rule

**Do not claim completion without verification.**

### Verification Steps

1. Run the relevant tests
2. If no tests exist, run the most relevant verification command
3. Read the actual output — don't assume success
4. Mention what was verified and what remains unverified

## Full Rules

Read at: `.agent/rules/testing-rules.md`

## Terminal Discipline

- Use `rtk` for heavy test runs (saves 60-90% tokens)
- Prefer concise output — no raw log dumps
- Summarize failures clearly
