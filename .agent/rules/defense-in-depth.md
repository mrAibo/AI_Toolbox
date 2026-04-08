# Defense in Depth

**Source:** [Superpowers defense-in-depth](https://github.com/obra/superpowers/blob/main/skills/systematic-debugging/defense-in-depth.md)

## The Principle

After fixing a bug, add validation at multiple layers to prevent regression:

1. **The Fix** — The actual code change that resolves the bug
2. **The Test** — A test that catches this specific bug if it returns
3. **The Guard** — A validation or assertion that fails loudly if the precondition is violated
4. **The Process** — A CI check or workflow step that prevents this class of bugs

## Example: Null Pointer Bug

```
1. Fix:     Add null check before accessing user.name
2. Test:    Test that getUser() returns null for unknown ID
3. Guard:   Add type validation in the API layer (reject null IDs)
4. Process: Add static analysis rule (no unchecked property access)
```

## Why Multiple Layers?

- **The Fix** can be undone by accident
- **The Test** might be skipped or misconfigured
- **The Guard** catches runtime violations before they cascade
- **The Process** prevents the entire class of bugs

## Rules

- Don't rely on a single layer — one is none
- Each layer should be independent (not just redundant checks of the same thing)
- Document which layers protect against which bug class
- Prefer automated layers (tests, CI) over manual ones (code review checklists)
