---
title: Coverage, and what it does not measure
version: 1
---

**Coverage reports which lines of the code ran while the tests ran; it says nothing about whether
anything checked what those lines did.** It is a map of what is untested, and a poor score of what
is tested. Vitest measures it through V8, the JavaScript engine inside Node, with one more package
at the same version as Vitest:

```
ana@dev:~/planner$ npm install --save-exact -D @vitest/coverage-v8@5.0.5

added 12 packages, and audited 89 packages in 2s

found 0 vulnerabilities
```

```
ana@dev:~/planner$ npx vitest run --coverage

 RUN  v5.0.5 /home/ana/planner
      Coverage enabled with v8


 Test Files  3 passed (3)
      Tests  25 passed (25)
   Start at  19:31:46
   Duration  922ms (environment 63%, transform 16%, worker 8%, tests 8%, import 6%)

 % Coverage report from v8
No files with missing coverage.
3 files fully covered.

=============================== Coverage summary ===============================
Statements   : 100% ( 71/71 )
Branches     : 100% ( 26/26 )
Functions    : 100% ( 17/17 )
Lines        : 100% ( 62/62 )
================================================================================
```

**Every line, every branch and every function: 100%.** Twenty-five tests reach all of `planner.ts`
and all of `view.ts`, and the only files counted are the ones a test imported. Now read what it
leaves out. `main.ts` is not counted at all, because no test imports it: it fetches, it waits, it
listens for `hashchange`, and none of that can be reached from Node. And `view.ts` at 100% still has
an input with no label and a grey that nobody can read, which lessons 3 and 10 find, because no line
of it is wrong in the way a line can be wrong. `main.ts` is not a gap to fill
with a cleverer unit test. It is the part of the app that only exists in a browser, and lesson 4
tests it there.

## Why not a target

Make 100% a rule and the suite fills up with tests that run lines without asserting anything, since
that is the cheapest way to raise the number. **A line can run in a test and be wrong**: before this
lesson's fix, a test that called `weekOf` and checked only that it returned two strings would have
covered every line of it and found nothing. The number would have been perfect and the planner wrong.

So the rule this course keeps is the one a red test teaches: write the test that would have caught
the failure you just found, and the one for the failure you can name before it happens. Coverage tells
you where nobody has looked yet; it cannot tell you who looked carefully.

The report goes in `coverage/`, which is output and not source. Keep it out of Git:

```
ana@dev:~/planner$ echo coverage >> .gitignore
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Unit and component tests with Vitest"
ana@dev:~/planner$ git log --oneline
13c594d Unit and component tests with Vitest
925ced3 Test the week, and compute it in UTC
050e2d3 The study planner
```
