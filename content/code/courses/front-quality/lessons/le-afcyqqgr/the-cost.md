---
title: What a browser test costs, measured
version: 1
---

**Lesson 1 argued that the top of the pyramid is slow and the bottom fast; here are the planner's own
numbers.** Both suites, as they stand at the end of this lesson:

```
ana@dev:~/planner$ npm test

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner


 Test Files  4 passed (4)
      Tests  27 passed (27)
   Start at  19:54:00
   Duration  1.12s (environment 64%, tests 21%, import 11%, transform 2%, worker 1%)

ana@dev:~/planner$ npx playwright test

Running 5 tests using 2 workers

  ✓  2 [chromium] › e2e/empty.spec.ts:4:1 › a course with nothing planned says 0 for its week (444ms)
  ✓  1 [chromium] › e2e/planner.spec.ts:8:1 › the home page shows the week (450ms)
  ✓  3 [chromium] › e2e/planner.spec.ts:14:1 › a session added to a course counts in its week (416ms)
  ✓  4 [chromium] › e2e/planner.spec.ts:24:1 › Done marks a session and takes its button away (235ms)
  ✓  5 [chromium] › e2e/planner.spec.ts:30:1 › a failed load says so (159ms)

  5 passed (3.1s)
```

**Twenty-seven tests in Vitest, a little over a second, most of it starting jsdom. Five in a real
browser, several seconds.** A browser test costs hundreds of times more than a unit test, and the
starting cost is paid once per run, so the gap is smaller per test than per suite. Both are still fast
enough to run before every push, and that is the point to defend: when the browser suite takes
minutes, people stop running it locally, and the first person to see a failure is the CI server.

## Where each suite runs

- **While you write code**, `npx vitest` in watch mode: the unit and component tests rerun on every
  save, in well under a second each.
- **Before a commit**, `npm test` and `npx playwright test`, both of them. Add a script so it is one
  command:

```
ana@dev:~/planner$ npm pkg set scripts.check="npm test && npx playwright test"
ana@dev:~/planner$ npm run check 2>&1 | tail -n 4
  ✓  4 [chromium] › e2e/planner.spec.ts:24:1 › Done marks a session and takes its button away (234ms)
  ✓  5 [chromium] › e2e/planner.spec.ts:30:1 › a failed load says so (167ms)

  5 passed (2.4s)
```

- **On every pull request**, the same `npm run check`, on a CI server, where a red result blocks the
  merge. Setting that up is lesson 3 of `front-delivery`, on continuous integration.

## What this suite still does not check

Every test so far asks whether the planner **works**. None asks whether it can be **trusted** with
somebody's sessions, and none asks whether a person who cannot use a mouse, or see the screen, can use
it at all. Lessons 5 to 9 are the first question, and lessons 10 to 13 the second, and both will add
tests to these two suites rather than start new ones.

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "An empty course, and one command for both suites"
ana@dev:~/planner$ git log --oneline | head -n 3
abef326 An empty course, and one command for both suites
86a656b End-to-end tests with Playwright
aae0330 Start the app from a function a test can call
```
