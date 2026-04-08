# Testing Anti-Patterns

**Source:** [Superpowers testing-anti-patterns](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/testing-anti-patterns.md)

## Anti-Patterns to Avoid

### 1. Mocking Production Behavior

**Wrong:** Mocking a function to return a fixed value when the real function has important side effects.
**Right:** Test with real dependencies where possible. Use fakes or test containers for databases.

### 2. Testing Only the Happy Path

**Wrong:** Only testing the case where everything works.
**Right:** Test error cases, edge cases, and boundary conditions. Every `if` should have a test for both branches.

### 3. Testing Implementation Details

**Wrong:** Testing internal method calls, private functions, or specific implementation choices.
**Right:** Test observable behavior — inputs and outputs. Implementation can change; behavior should not.

### 4. Test-Only Methods

**Wrong:** Adding methods to production code that are only used by tests.
**Right:** If you need to expose something for testing, the design is probably wrong. Test through the public interface.

### 5. Assertions Without Messages

**Wrong:** `assert(x == y)` — when it fails, you don't know why.
**Right:** `assert(x == y, f"Expected {y}, got {x}")` — clear failure message.

### 6. Testing Multiple Things in One Test

**Wrong:** One test that checks validation, creation, and deletion.
**Right:** One test per behavior. When it fails, you know exactly what broke.

### 7. Fragile Tests (Order-Dependent)

**Wrong:** Tests that pass when run alone but fail in a suite (shared state, global variables).
**Right:** Each test is independent and isolated. Use fresh fixtures for each test.

## Principle

Tests should be:
- **Clear** — Easy to understand what behavior is being tested
- **Independent** — No shared state, no order dependencies
- **Behavioral** — Test what the code does, not how it does it
- **Complete** — Cover errors, edge cases, and normal operation
