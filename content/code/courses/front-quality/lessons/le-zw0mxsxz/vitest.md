---
title: Vitest, installed and pinned
version: 1
---

**Vitest is a test runner built on Vite: it reads the project's own configuration, understands
TypeScript and imports the way the app does, and needs nothing else to start.** That is the
reason to choose it for a Vite project. Jest was the standard before it, and the section on Jest
near the end of this lesson shows what it takes to run the same tests there.

It goes in as a development dependency, at the version this course was recorded with, 5.0.5:

```
ana@dev:~/planner$ npm install --save-exact -D vitest@5.0.5

added 20 packages, and audited 39 packages in 2s

found 0 vulnerabilities
```

`-D` files it under `devDependencies`, because the published site never needs it. A script makes
`npm test` run the whole suite once and stop:

```
ana@dev:~/planner$ npm pkg set scripts.test="vitest run"
ana@dev:~/planner$ npm pkg get scripts
{
  "dev": "vite",
  "build": "tsc && vite build",
  "preview": "vite preview",
  "test": "vitest run"
}
```

`vitest run` runs every test and exits, which is what you want before a commit and what a CI job
runs. `npx vitest` with no `run` stays open, watches the files, and runs again the tests a change
touches each time you save; that is the way to work while writing tests, and its screen is the same
report you see below, redrawn.

## Where it looks

**A test file is any file whose name ends in `.test.ts`**, or `.spec.ts`, anywhere outside
`node_modules`. This course keeps each beside the file it tests: `src/planner.test.ts` next to
`src/planner.ts`. Nothing has to be registered, and with no test files yet there is nothing to run:

```
ana@dev:~/planner$ npm test; echo "exit code $?"

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner

No test files found, exiting with code 1

include: **/*.{test,spec}.?(c|m)[jt]s?(x)
exclude:  **/node_modules/**, **/.git/**

exit code 1
```

Exit code 1, and a message saying so. **A test run that found no tests fails**, which is the right
default: a typo in a file name should not look like a green suite.
