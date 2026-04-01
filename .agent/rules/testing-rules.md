# Testing Rules

This file defines how work must be verified before it is considered complete.

The purpose is to prevent false completion, unverified assumptions, and silent regressions.

---

## Core rule

Do not claim that something works unless it has been checked.

Verification is mandatory.
If something cannot be verified, state that clearly.

---

## Preferred workflow

When possible, use one of these approaches:
- test-first
- verification-first
- reproduce -> fix -> verify

The chosen approach depends on the task, but verification is always required.

---

## Required behavior

- Run tests when tests exist
- If there are no tests, run the most relevant verification command
- If no command exists, inspect the result in the most direct practical way
- Check the actual output instead of assuming success
- Mention what was verified and what remains unverified

---

## Terminal output discipline

- Prefer concise test output
- Use `rtk` for heavy test runs where possible
- Avoid pasting very large raw output into context
- Summarize failures clearly and precisely

---

## Change validation

For each meaningful code change, verify at least one of the following:
- tests pass
- build succeeds
- command output is correct
- file output is correct
- integration behavior matches the expected contract

---

## Bug fix workflow

For bug fixes, prefer this sequence:
1. Reproduce the problem
2. Identify the likely cause
3. Implement the fix
4. Re-run verification
5. Record durable knowledge if the bug was non-trivial

---

## Reporting rule

When reporting completion, mention:
- what was changed
- how it was verified
- what is still uncertain, if anything
