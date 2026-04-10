# Context Flush Workflow

**Purpose:** Prevent context explosion in long sessions by resetting the chat window while preserving state.

---

## When to Flush (Triggers)

Initiate a context flush when ANY of the following occur:

1. **Sub-task completed:** You finished a logical unit of work (e.g., implemented a feature, fixed a bug) and are about to start something unrelated.
2. **Component switch:** You are moving from one part of the codebase to a completely different component.
3. **Context bloat:** You have read many files, explored tangential issues, or feel the conversation has accumulated too much irrelevant history.
4. **Turn fatigue:** You notice repeated questions or the conversation has become circular.

Do NOT count turns — LLMs cannot reliably count. Use these semantic triggers instead.

---

## How to Flush

1. **Save state:** Update `.agent/memory/active-session.md` with:
   - What was accomplished in this session
   - What is currently in progress
   - What the next step should be
   - Any important discoveries or decisions made

2. **Notify the user:**
   ```
   My context window has grown large, which increases costs and reduces focus.
   I have saved my current state to `.agent/memory/active-session.md`.
   Please clear the chat history (run /clear, /reset, or restart the CLI) and say "continue".
   I will restore my state from the saved session file.
   ```

3. **After the flush:** When the user says "continue", follow the AGENT.md Boot Sequence to restore context from `.agent/memory/` files.

---

## Cost Impact

- A session with 20+ turns can cost 3-5x more per turn than a fresh session
- After a flush, the first turn costs ~80-90% less
- State preservation via active-session.md means zero information loss
