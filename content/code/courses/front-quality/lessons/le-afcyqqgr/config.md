---
title: The configuration, and two runners in one project
version: 1
---

**Playwright Test reads `playwright.config.ts` at the project's root: where the tests are, which
browser to use, and how to start the app before the first test.** Save this as
`playwright.config.ts`:

```typescript
// playwright.config.ts
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "e2e",
  use: {
    baseURL: "http://localhost:5173",
    timezoneId: "America/Sao_Paulo",
    trace: "retain-on-failure",
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  webServer: {
    command: "npm run dev",
    url: "http://localhost:5173",
    reuseExistingServer: true,
  },
});
```

- **`testDir: "e2e"`** keeps the browser tests in a folder of their own, `e2e/`, apart from the unit
  and component tests beside the code in `src/`.
- **`baseURL`** lets a test say `page.goto("/")` instead of the whole address.
- **`timezoneId`** gives the browser a time zone of its own, whatever the machine's is. Lesson 2
  showed what a time zone does to the planner; this way every student's run sees the same week.
- **`trace: "retain-on-failure"`** records everything a failing test did, for the viewer two
  sections on.
- **`webServer`** starts `npm run dev` and waits until port 5173 answers before the first test;
  `reuseExistingServer` uses the one already running in your other terminal, if there is one.

Playwright's output folders are not source, and Git should not keep them:

```
ana@dev:~/planner$ printf "test-results\nplaywright-report\n" >> .gitignore
ana@dev:~/planner$ cat .gitignore
# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
lerna-debug.log*

node_modules
dist
dist-ssr
*.local

# Editor directories and files
.vscode/*
!.vscode/extensions.json
.idea
.DS_Store
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?
coverage
test-results
playwright-report
```

## Two runners, one project

A Playwright test file is a `.spec.ts` file, and so is a Vitest one: Vitest's default pattern is
anything ending in `.test.ts` or `.spec.ts`. So the moment `e2e/` holds a test, `npm test` finds it
and runs it with the wrong runner. The next section writes the first one, and here is what `npm test`
then says:

```
ana@dev:~/planner$ npm test 2>&1 | head -n 20

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner

 ❯ e2e/planner.spec.ts (0 test)

⎯⎯⎯⎯⎯⎯ Failed Suites 1 ⎯⎯⎯⎯⎯⎯⎯

 FAIL  e2e/planner.spec.ts [ e2e/planner.spec.ts ]
Error: Playwright Test did not expect test.beforeEach() to be called here.
Most common reasons include:
- You are calling test.beforeEach() in a configuration file.
- You are calling test.beforeEach() in a file that is imported by the configuration file.
- You have two different versions of @playwright/test. This usually happens
  when one of the dependencies in your package.json depends on @playwright/test.
- You are calling test.beforeEach() from an async test.describe() block. Only sync ones are supported.
 ❯ _TestTypeImpl._currentSuite node_modules/playwright/lib/common/index.js:2224:13
```

**Each runner has to be told what is not its own.** Vite's configuration file holds Vitest's
settings too. Save this as `vite.config.ts`:

```typescript
// vite.config.ts
import { configDefaults, defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    exclude: [...configDefaults.exclude, "e2e/**"],
  },
});
```

`configDefaults.exclude` is what Vitest already leaves out, `node_modules` among it; the line adds
`e2e/` to it rather than replacing it.

```
ana@dev:~/planner$ npm test

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner


 Test Files  4 passed (4)
      Tests  27 passed (27)
   Start at  19:53:37
   Duration  1.27s (environment 59%, tests 20%, import 10%, transform 10%, worker 1%)
```
