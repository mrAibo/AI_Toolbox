# Test-Driven Development (TDD) Rules

This file defines the mandatory TDD process for all code changes.

The purpose is to prevent untested code, accidental regressions, and "works on my machine" commits.

---

## Core rule

**NEVER write production code without a failing test first.**

Every meaningful code change MUST follow the RED-GREEN-REFACTOR cycle.

---

## The RED-GREEN-REFACTOR Cycle

### Step 1: RED — Write a failing test

Write a test that demonstrates the desired behavior.

- The test should describe WHAT the code should do, not HOW it works
- Keep the test small and focused on one behavior
- The test MUST fail for the right reason (the feature doesn't exist yet)

### Step 2: VERIFY RED — Run the test

```bash
rtk test
```

- The test **MUST fail**. If it passes, the test is wrong.
- Verify the failure message matches what you expect.
- Do NOT skip this step.

### Step 3: GREEN — Write minimal code

Write the MINIMUM amount of code needed to make the test pass.

- No extra features
- No premature abstraction
- No refactoring yet

### Step 4: VERIFY GREEN — Run the test

```bash
rtk test
```

- The test **MUST pass**.
- All existing tests MUST also pass.
- Do NOT proceed to refactoring if any test fails.

### Step 5: REFACTOR — Clean up the code

Now that all tests pass, improve the code quality:

- Extract functions, classes, modules
- Improve naming and readability
- Remove duplication
- Apply design patterns where appropriate

**Rule:** Tests must remain green after every refactoring step.

### Step 6: COMMIT — Save the change

```bash
rtk git add <files>
rtk git commit -m "feat: description"
```

- Only commit when all tests pass.
- Never commit failing tests.

---

## When TDD is mandatory

TDD is required for:
- New features or endpoints
- Bug fixes (write a test that reproduces the bug first)
- Refactoring of complex code (write characterization tests first)
- Changes to business logic

TDD is optional for:
- Documentation-only changes
- Configuration changes with no logic
- One-line typos or whitespace fixes

---

## Anti-Patterns (NEVER do these)

| Anti-Pattern | Why it's bad | What to do instead |
|--------------|-------------|-------------------|
| Writing production code before a failing test | No safety net; easy to break things unknowingly | Write test first, verify it fails |
| Skipping "verify red" | Assuming the test fails without running it — it might not | Always run the test and confirm it fails |
| Writing more code than needed to pass the test | Over-engineering; unused code becomes dead weight | Write the minimum; add more when a test demands it |
| Refactoring before all tests pass | No way to know if the refactor broke something | Make tests green first, then refactor |
| Committing with failing tests | Breaks the build for everyone; erodes trust in tests | Never commit unless all tests pass |
| Mocking everything | Tests don't reflect real behavior | Prefer integration tests; mock only external dependencies |
| Testing implementation details | Brittle tests that break on refactoring | Test behavior and outcomes, not internals |
