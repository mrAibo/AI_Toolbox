# Template Usage Rules

This file defines when and how to use the 413+ specialist agent templates from the Template Bridge project.

---

## When to use templates

Use a specialist template when:

1. **Existing skills don't cover the need** — TDD, Planning, Debugging, and Code Review rules are insufficient for the task
2. **Working with specialized technology** — Rust async, Kubernetes operators, GraphQL APIs, smart contracts, etc.
3. **Need established patterns** — Don't improvise when a proven template exists

Do NOT use templates for:
- Simple CRUD operations (TDD rules are sufficient)
- Basic bug fixes (debugging workflow is sufficient)
- Documentation changes (no template needed)

---

## How to access templates

### Claude Code (recommended)
```
/browse-templates
```
Interactive search through all 413+ templates directly in the chat.

### Direct install (any client)
```bash
npx claude-code-templates@latest --agent <category/name> --yes
```

### Manual browse (any client)
Visit [github.com/maslennikov-ig/template-bridge](https://github.com/maslennikov-ig/template-bridge) and browse the template catalog.

---

## Template Categories (26 total)

| Category | Examples |
|----------|----------|
| **ai-specialists** | ML pipeline design, prompt engineering, model evaluation |
| **api-graphql** | GraphQL schema design, resolver patterns, federation |
| **api-rest** | REST API design, pagination, versioning, HATEOAS |
| **blockchain-web3** | Smart contracts, DeFi protocols, token standards |
| **database** | Schema design, migration strategies, query optimization |
| **devops-infrastructure** | Docker, Kubernetes, CI/CD pipelines, IaC |
| **mobile** | React Native, Flutter, iOS/Android native patterns |
| **programming-languages** | Rust, Go, TypeScript, Python, Java, C++ patterns |
| **security** | Auth design, secret management, penetration testing |
| **ui-analysis** | Component architecture, accessibility, performance |

... and 16 more categories.

---

## Usage process

When using a template:

1. **Identify the gap** — What can't existing skills handle?
2. **Search** — Use `/browse-templates` or `npx claude-code-templates@latest`
3. **Select** — Choose the most relevant template for the task
4. **Adapt** — Apply the template to the current project context
5. **Document** — Record in `.agent/memory/architecture-decisions.md`:
   ```markdown
   ### ADR-XXXX: Used [template-name] template for [task]
   - Status: accepted
   - Date: YYYY-MM-DD
   - Context: Existing skills were insufficient for [specific need]
   - Decision: Used template [category/name] from Template Bridge
   - Consequences: [How the template shaped the implementation]
   ```
6. **Execute** — Follow the template's guidance for the task

---

## Anti-Patterns

| Anti-Pattern | Why it's bad | What to do instead |
|--------------|-------------|-------------------|
| Using a template for a simple task | Over-engineering; wastes time | Use existing TDD/debugging skills |
| Blindly following a template without adaptation | May not fit the project context | Always adapt to the specific project |
| Not documenting which template was used | Future maintainers won't know the reasoning | Record in architecture-decisions.md |
| Mixing multiple templates for one task | Conflicting patterns and approaches | Pick one primary template |
