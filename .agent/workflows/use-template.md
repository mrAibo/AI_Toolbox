# Template Usage Workflow

This workflow defines the step-by-step process for using a specialist template from the Template Bridge catalog.

---

## When to run this workflow

- Existing skills (TDD, Planning, Debugging) don't cover the current task
- Working with a specialized technology that needs established patterns
- The user explicitly asks for a template

---

## Steps

### Step 1: Identify the gap

Document what existing skills cannot handle:

```
## Gap Analysis
- Task: [What needs to be done]
- Existing skills cover: [TDD / Planning / Debugging / Review]
- Gap: [What's missing — why existing skills are insufficient]
```

### Step 2: Search for a template

```bash
# Claude Code:
/browse-templates

# Direct install:
npx claude-code-templates@latest --agent <category/name> --yes
```

Search terms should match:
- The technology (e.g., "rust", "kubernetes", "graphql")
- The pattern (e.g., "repository pattern", "event sourcing", "CQRS")
- The domain (e.g., "auth", "payment", "notification")

### Step 3: Select the most relevant template

Evaluate candidates by:
1. **Relevance** — Does it solve the identified gap?
2. **Recency** — Is it up-to-date with current best practices?
3. **Complexity match** — Not too simple, not over-engineered for the task

### Step 4: Adapt to project context

Before applying the template:
1. Read the template fully
2. Identify which parts apply to the current project
3. Identify which parts need modification
4. Check compatibility with existing project patterns (`.agent/rules/stack-rules.md`)

### Step 5: Document the decision

Record in `.agent/memory/architecture-decisions.md`:

```markdown
### ADR-XXXX: Used [template-name] template for [task]
- Status: accepted
- Date: YYYY-MM-DD
- Context: [Why existing skills were insufficient]
- Decision: Used template [category/name] from Template Bridge
- Adaptations: [What was changed from the original template]
- Consequences: [How the template shaped the implementation]
```

### Step 6: Execute

Follow the template's guidance:
- Apply the patterns and structures it recommends
- Adapt code to fit the project's existing style
- Run verification (`.agent/workflows/code-review.md`) before finishing

---

## Example: Building a GraphQL API

```
Gap Analysis:
- Task: Build a GraphQL API with DataLoader pattern
- Existing skills cover: TDD (test-first), Debugging (systematic)
- Gap: GraphQL-specific patterns (schema design, resolvers, DataLoader) not in existing skills

Search: /browse-templates → "api-graphql/resolver-patterns"
Select: Resolver patterns template with DataLoader guidance
Adapt: Project uses TypeScript + Express, adjust from Node.js generic
Document: ADR entry with template reference
Execute: Follow template for schema, resolvers, DataLoader setup
```
