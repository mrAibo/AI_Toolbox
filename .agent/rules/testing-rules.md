# Testing Rules

This file defines how work must be verified before it is considered complete.

The purpose is to prevent false completion, unverified assumptions, and silent regressions.

For the mandatory TDD process (RED-GREEN-REFACTOR), see **[tdd-rules.md](tdd-rules.md)**.

---

## Core rule

Do not claim that something works unless it has been checked.

Verification is mandatory.
If something cannot be verified, state that clearly.

---

## Evidence ladder

State only what evidence you actually have. The tiers are:

1. **Code written** — the code exists; behavior not yet verified
2. **Command ran** — a command was executed; output not yet reviewed
3. **Output reviewed** — the output was inspected; behavior not fully tested
4. **Tests pass** — automated tests pass; side effects not yet checked
5. **Behavior verified** — the intended behavior is confirmed end-to-end

Never skip a tier implicitly. If you are at tier 2, say so.

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

## Side-effect check

After verifying the primary behavior, check neighboring behavior:
- Did other tests still pass?
- Did adjacent functionality remain intact?
- Were any files, state, or outputs changed that were not intended?

A fix is not complete until side effects are ruled out.

---

## Verified vs. unclear

When reporting, explicitly separate:
- **Verified:** what was directly observed or tested
- **Assumed:** what was inferred but not directly confirmed
- **Unknown:** what was not checked

Do not collapse these categories. "It should work" or "it looks right" without evidence is not verification.

---

## Reporting rule

When reporting completion, mention:
- what was changed
- how it was verified
- what is still uncertain, if anything
