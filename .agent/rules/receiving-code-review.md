# Receiving Code Review

**Source:** [Superpowers receiving-code-review](https://github.com/obra/superpowers/blob/main/skills/receiving-code-review/SKILL.md)

## When Receiving Review Feedback

Before implementing ANY review suggestion:

1. **Read carefully** — Understand what the reviewer is actually concerned about
2. **Verify independently** — Check if the issue is real by examining the code yourself
3. **Decide** — Is this a valid concern?

### If Valid

- Fix the issue
- Explain what you changed and why
- Thank the reviewer for catching it

### If Not Valid

- Push back with evidence (tests, specs, reasoning)
- Don't just agree — verify first
- "You're right, let me check" → check → then respond with findings

## Anti-Patterns (NEVER Do These)

- ❌ "You're absolutely right!" without checking — sycophantic, not rigorous
- ❌ Implementing every suggestion blindly — reviewer may be wrong or misunderstood
- ❌ Defensive dismissal — evaluate on merits, not ego
- ❌ "Good catch!" without verifying it was actually a catch

## Core Principle

**Verify before implementing.** A review suggestion is a hypothesis, not a fact. Your job is to test it, not to please the reviewer.

## When Reviewers Disagree With Your Pushback

- Provide concrete evidence (tests, output, specs)
- If still disputed, defer to the reviewer's judgment — they own the review
- Document the decision in a comment or commit message
