# Examples: Daily Pitfalls & Anti-Patterns

These are real-world mistakes developers make daily — and how the AI Toolbox catches or prevents them.

---

## Pitfall 1: "The AI wrote code without tests"

### What happens
The user says "add a GET endpoint" and the AI writes the implementation directly — no tests.

### Why it's bad
Untested code ships. The first user to hit the endpoint gets a 500 error.

### How AI Toolbox prevents it
**`.agent/rules/tdd-rules.md`** enforces RED-GREEN-REFACTOR:

```
Step 1: RED — Write failing test
Step 2: VERIFY RED — rtk test → MUST fail
Step 3: GREEN — Write minimal code
Step 4: VERIFY GREEN — rtk test → MUST pass
```

The AI **cannot** skip to GREEN without a failing test first. The verification rule in `testing-rules.md` states: "Do not claim completion without verification."

### What the user sees
```
📋 Applying: .agent/rules/tdd-rules.md — RED phase
🔧 Writing failing test: GET /users/:id returns 404 for unknown user
🔧 Using: rtk test — FAIL (expected)
✅ RED confirmed — now writing minimal implementation
```

---

## Pitfall 2: "The AI forgot what it was doing yesterday"

### What happens
User closes the session. Next morning: "Where did we leave off?" The AI has no memory.

### Why it's bad
30 minutes of re-reading code, re-understanding context, re-planning.

### How AI Toolbox prevents it
**`hook-stop.sh/ps1`** runs automatically at session end:
1. Updates `.agent/memory/session-handover.md` with what was done
2. Appends `active-session.md` summary (steps completed, tokens saved, agents used)
3. Reminds to update `architecture-decisions.md` if needed

Next morning, the Boot Sequence reads `session-handover.md` first:

```
📖 Reading: .agent/memory/session-handover.md
   → "Completed: GET /users/:id endpoint, 12 tests added"
   → "Next: POST /users endpoint (bd-d4e5f6)"
📖 Reading: .agent/memory/active-session.md
   → "Steps completed: 9/9, Tokens saved: ~2400"
✅ Context restored — starting next task
```

---

## Pitfall 3: "The AI used 50,000 tokens on a test run"

### What happens
The AI runs `npm test` and dumps 3,000 lines of raw output into the chat context.

### Why it's bad
Token budget blown. The AI forgets earlier context. Next commands fail.

### How AI Toolbox prevents it
**`hook-pre-command.sh/ps1`** intercepts heavy commands:
```
🚨 AI Toolbox Heavy Command Detected!
Please use 'rtk' wrapper for heavy commands to optimize token usage.
Example: rtk npm test
```

If the AI ignores the warning and runs raw `cat file.log`:
```
🚨 AI Toolbox: Large log file detected!
Please use 'rtk read <file-path>' to read large logs efficiently.
```

**rtk** compresses test output by 60-90%:
```
Before: 3,000 lines, ~15,000 tokens
After:  300 lines, ~1,500 tokens (90% saved)
```

---

## Pitfall 4: "The AI made a breaking change without telling anyone"

### What happens
The AI refactors a public API. Tests pass (updated). No documentation. No ADR.

### Why it's bad
The next session doesn't know the API changed. Clients break.

### How AI Toolbox prevents it
**`.agent/workflows/code-review.md`** requires a checklist before finishing:

```markdown
## Pre-Review Checklist
- [ ] All tests pass
- [ ] No lint errors
- [ ] Changes match original plan
- [ ] Edge cases handled
- [ ] Breaking changes documented in architecture-decisions.md
```

If a breaking change is detected, the AI must record it:

```
📋 Applying: .agent/workflows/code-review.md
⚠️ BREAKING: Changed API signature — recording in architecture-decisions.md
### ADR-0042: Changed GET /users/:id response format
- Status: accepted
- Context: Added nested address object
- Decision: Breaking change — consumers must update
```

---

## Pitfall 5: "The AI ran 3 agents and I have no idea what they did"

### What happens
The AI spawns 3 parallel agents for a review. They finish. The AI says "done" without details.

### Why it's bad
User has no idea what was found, what was fixed, what remains.

### How AI Toolbox prevents it
**`.agent/rules/status-reporting.md`** requires reporting at every step:

```
🤖 Spawning Agent 1/3: Review bootstrap.sh (general-purpose)
🤖 Spawning Agent 2/3: Review bootstrap.ps1 (general-purpose)
🤖 Spawning Agent 3/3: Check broken links (Explore)

🤖 Agent 1/3 complete: 5 issues found (2 High, 3 Medium)
🤖 Agent 2/3 complete: 3 issues found (1 High, 2 Low)
🤖 Agent 3/3 complete: All links valid

📊 Synthesizing results — 8 total issues, 3 High priority
```

The **`active-session.md`** file tracks agent count, and **`session-handover.md`** records:
```
## Session Summary
- Sub-agents used: 3
- Issues found: 8 (3 High, 3 Medium, 2 Low)
- All issues resolved
```

---

## Pitfall 6: "I merged without reviewing the changes"

### What happens
The AI says "all tests pass" and merges. User later finds a logic bug.

### Why it's bad
Production bug. Rollback needed.

### How AI Toolbox prevents it
**`.agent/workflows/branch-finish.md`** requires final verification:

```bash
rtk test    # All tests pass
rtk lint    # No lint errors
rtk diff    # Review all changes
```

Before merging, the AI must show the diff and get confirmation:

```
## Final Verification
✅ rtk test — 12 tests pass
✅ rtk lint — 0 issues
📋 rtk diff — 4 files changed, 89 insertions

Changes summary:
- user-repository.ts: +23 lines (interface + in-memory impl)
- user-handler.ts: +31 lines (GET /users/:id)
- router.ts: +5 lines (wired endpoint)
- user-repository.test.ts: +30 lines (4 tests)

Proceed with merge? [y/n]
```

---

## Pitfall 7: "The AI chose a new framework without asking"

### What happens
User says "add caching." AI adds Redis. No discussion. No ADR.

### Why it's bad
New dependency. Deployment complexity. Nobody reviewed the choice.

### How AI Toolbox prevents it
**`.agent/rules/stack-rules.md`** states:

```
Do not introduce a new language, framework, library, database, or major
build tool without a reason.

If a new dependency is necessary:
- explain why it is needed
- explain what problem it solves
- compare it with at least one simpler alternative
- record the decision in architecture-decisions.md
```

The AI must propose options:

```
📋 Applying: .agent/rules/stack-rules.md — New dependency check
Caching needed. Options:
1. In-memory cache (no new dependency, simplest)
2. Redis (robust, but adds deployment complexity)
3. File-based cache (persistent, no infra needed)

Recommendation: In-memory cache — sufficient for current load.
Record decision in architecture-decisions.md? [y/n]
```

---

## Pitfall 8: "The AI skipped the plan and started coding"

### What happens
User describes a complex feature. AI starts writing code immediately.

### Why it's bad
Wrong architecture. Missed edge cases. Wasted time.

### How AI Toolbox prevents it
**`AGENT.md` §3** requires planning before implementation:

```
If the user asks for a new project, a new subsystem, or a large feature:
1. Do not code immediately
2. Start with brainstorming
3. Propose multiple possible approaches
4. Ask for confirmation if direction is unclear
5. Record the selected direction in architecture-decisions.md
6. Create the work structure in Beads
7. Execute only the next ready task
```

The AI must follow the **Unified Workflow** (`.agent/workflows/unified-workflow.md`):

```
📋 Applying: AGENT.md §3 — Planning mode
Analyzing request: "Add user authentication"
This is a large feature — entering Brainstorming mode.

Approaches:
1. JWT-based auth (stateless, simple)
2. Session-based auth (stateful, more control)
3. OAuth2 integration (external provider, least code)

Which direction should we pursue?
```

---

## Summary Table

| Pitfall | What prevents it | Where it's enforced |
|---------|-----------------|---------------------|
| No tests | TDD Rules (RED-GREEN-REFACTOR) | `.agent/rules/tdd-rules.md` |
| Lost context | Session Handover | `hook-stop.sh/ps1` → `session-handover.md` |
| Token bloat | rtk Pre-Command Hook | `hook-pre-command.sh/ps1` |
| Breaking changes | Code Review Checklist | `.agent/workflows/code-review.md` |
| Silent multi-agents | Status Reporting | `.agent/rules/status-reporting.md` |
| Unreviewed merges | Branch Finish Workflow | `.agent/workflows/branch-finish.md` |
| Framework drift | Stack Rules | `.agent/rules/stack-rules.md` |
| No planning | AGENT.md §3 + Unified Workflow | `AGENT.md`, `.agent/workflows/unified-workflow.md` |
