# Root Cause Tracing

**Source:** [Superpowers root-cause-tracing](https://github.com/obra/superpowers/blob/main/skills/systematic-debugging/root-cause-tracing.md)

## The Technique

Trace backwards from the symptom to find the actual cause:

1. **Start at the symptom** — What error, failure, or unexpected behavior do you see?
2. **Find the immediate cause** — What line of code directly produced this symptom?
3. **Trace one level up** — What called that code with the wrong input or state?
4. **Continue upward** — Keep tracing until you find the decision that introduced the bug
5. **Stop at the root** — The root cause is the earliest point where a different decision would have prevented the bug

## Example

```
Symptom: 500 error on /api/users
  → Direct cause: Database query fails (column not found)
    → One level up: Migration didn't run
      → One level up: Deploy script skipped migrations
        → ROOT CAUSE: CI/CD config has no migration step for this environment
```

## Rules

- **Don't stop at the first cause** — The immediate cause is rarely the root
- **Don't skip levels** — Each step needs evidence, not guesses
- **Document the chain** — Write the trace so others can follow it
- **Fix at the root** — Patching the symptom creates recurring bugs

## When to Stop Tracing

- You've reached a design decision that could be improved
- You've found a missing validation or assumption
- You've identified a process gap (missing CI step, undocumented dependency)
- Going further would require changing external systems (third-party APIs, legacy code you don't own)
