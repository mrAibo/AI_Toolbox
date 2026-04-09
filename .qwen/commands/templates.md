---
name: templates
description: Browse and install 413+ specialist agent templates from claude-code-templates
---
# Templates Command

Browse and install specialist agents on demand from the Template Bridge project.

**Note:** Requires internet access. Templates are served from npm — no local copy stored.

## Interactive Mode

```bash
npx claude-code-templates@latest
```

## Direct Install

```bash
npx claude-code-templates@latest --agent {category}/{name} --yes
```

## Validate Access

Before using, verify the package is reachable:
```bash
npx claude-code-templates@latest --help
```

If this fails, check your npm registry access or try with `--registry https://registry.npmjs.org`.

## Available Categories (26 total, 413+ agents)

| Category | Example Agents |
|----------|---------------|
| ai-specialists | prompt-engineer, llm-architect |
| api-graphql | api-architect, graphql-specialist |
| database | postgres-specialist, redis-expert |
| devops-infrastructure | kubernetes-specialist, terraform-expert |
| development-team | backend-architect, frontend-developer |
| programming-languages | rust-expert, go-specialist, python-architect |
| security | security-auditor, penetration-tester |
| performance-testing | performance-engineer, web-vitals-optimizer |
| ui-analysis | screenshot-analyzer, accessibility-auditor |

[Full list: 26 categories, 413+ agents](https://github.com/davila7/claude-code-templates)

## When to Use

- Task requires specialist knowledge not covered by existing skills
- Working with unfamiliar frameworks or languages
- Need expert review from a specific domain

## Skill Priority

1. Use existing AI Toolbox skills first (brainstorming, TDD, debugging)
2. If no skill covers the need → check templates
3. Install template → follow its instructions
