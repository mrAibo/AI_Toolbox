# Node.js / npm Conventions

This plugin contributes Node.js-specific rules. They sit on top of the
universal toolbox rules; they don't replace them.

## Package management

- **Always commit the lockfile** (`package-lock.json`, `pnpm-lock.yaml`,
  or `yarn.lock`). Mismatch between local and CI is a recurring cause of
  "works on my machine" bugs.
- **Use `npm ci` in CI**, `npm install` locally. `npm ci` is reproducible
  and faster.
- **Pin Node.js versions** via `engines` in `package.json` and
  `.nvmrc` / `.node-version` in the repo root. Don't rely on the global
  default.
- **Don't commit `node_modules/`.** It must be in `.gitignore`.

## Scripts

- Keep `scripts` in `package.json` short and composable. Prefer
  `"test": "vitest"` over `"test": "vitest run --reporter=verbose ..."`;
  pass flags via the CLI.
- Use lifecycle hooks (`prepare`, `pretest`, `postinstall`) sparingly.
  Each one runs in unexpected contexts (CI, dependents, fresh checkouts).
- For a one-off command users will run, expose it as `npm run <verb>`.

## Dependencies

- Distinguish `dependencies` (runtime), `devDependencies` (build/test),
  and `peerDependencies` (consumer-provided). Putting a build tool in
  `dependencies` bloats production installs.
- Avoid duplicate packages — `npm dedupe` or `pnpm install` resolves
  hoist conflicts.
- For security: `npm audit` in CI, but treat low-severity advisories
  as informational, not blocking.

## TypeScript

- Type the public API. Internal helpers can use inference.
- Set `"strict": true` in `tsconfig.json`. Disable individual flags only
  with a comment explaining why.
- Use `tsx` or `ts-node` for runnable scripts; don't ship `.ts` to
  production without compilation.

## Test runners

- Prefer Vitest or Node's built-in test runner over Jest for new code:
  faster, fewer dependencies, native ESM.
- Place tests next to source (`foo.test.ts` next to `foo.ts`) unless the
  project has an established `tests/` convention.
- Run tests via `rtk vitest run` to keep output bounded — see
  [`.agent/rules/diff-editing.md`](../../rules/diff-editing.md).
