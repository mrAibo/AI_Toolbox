# Coding Discipline Rules

This file defines constraints against over-engineering and scope creep at the code level.

Its purpose is to prevent speculative complexity, premature abstractions, and opportunistic
refactoring that inflates diffs and introduces unintended regressions.

Inspired by Andrej Karpathy's observations on common LLM coding pitfalls.

---

## Simplicity First

Write the minimum code that solves the stated problem. Nothing more.

**The rule:** If the current task does not require it, do not write it.

This applies to:
- design patterns (Strategy, Factory, Observer, etc.)
- extra abstraction layers, base classes, or interfaces
- configuration systems for values that aren't yet configurable
- helper utilities for logic used only once
- generic solutions to specific problems

---

## What "speculative code" looks like

Speculative code solves a problem that does not exist yet. Examples:

```python
# ❌ Task: "calculate a 10% discount"
class DiscountStrategy(ABC):
    @abstractmethod
    def apply(self, price: float) -> float: ...

class PercentageDiscount(DiscountStrategy):
    def __init__(self, rate: float): self.rate = rate
    def apply(self, price: float) -> float: return price * (1 - self.rate)

discount = PercentageDiscount(0.10)
result = discount.apply(price)
```

```python
# ✅ Task: "calculate a 10% discount"
result = price * 0.90
```

The abstraction becomes justified only when a second discount type is actually required.
Until then, it is speculative complexity.

---

## Surgical Changes

Change only the lines that fix the reported problem.

When a bug is reported or a specific change is requested:
- locate the exact lines responsible
- change those lines only
- do not improve, reformat, or rename anything adjacent

---

## What "opportunistic refactoring" looks like

Opportunistic refactoring changes unrelated code while fixing something else. Examples:

```python
# ❌ Task: "fix email validation rejecting + signs"
# Bug was in the regex pattern. But the diff also:
# - renames validate_email → check_email_format
# - adds a @staticmethod decorator
# - extracts a helper is_valid_domain()
# - reformats the docstring
# - adds a new ValueError type
```

```python
# ✅ Task: "fix email validation rejecting + signs"
# Change only the regex pattern. One line changed.
- pattern = r'^[a-zA-Z0-9_.]+@[a-zA-Z0-9.]+$'
+ pattern = r'^[a-zA-Z0-9_.+]+@[a-zA-Z0-9.]+$'
```

If you notice other issues while making the fix, note them and propose them separately
after the current task is complete. See `safety-rules.md` — Scope control.

---

## The test for both rules

Before writing or editing code, ask:

1. **Does the current task require this line?**
   If no — do not write it.

2. **Is this line inside the reported change boundary?**
   If no — do not touch it.

---

## Anti-Patterns

| Anti-Pattern | Why it's bad | What to do instead |
|---|---|---|
| Adding abstractions "for future extensibility" | Future requirements are unknown; abstractions that don't earn their complexity become permanent debt | Add abstraction when the second use case arrives, not before |
| Wrapping simple logic in a class or service | Adds indirection without benefit | Use a plain function or expression |
| Renaming or reformatting while fixing a bug | Inflates the diff; makes reviews harder; can introduce regressions | Fix the bug, commit. Rename in a separate commit if needed |
| Improving adjacent code "while you're in there" | Scope creep; creates untested side effects | Finish the task, then open a separate proposal |
| Extracting helpers for one-time-use logic | Premature decomposition; harder to follow | Keep logic inline until it is reused |
| Adding configuration for a currently fixed value | Speculative generalization | Hardcode it; extract to config when the second value is needed |
