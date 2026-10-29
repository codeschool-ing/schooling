---
title: What to test, and one command for all of it
version: 1
---

**The planner now has three kinds of check, and each catches what the others cannot**:

| check | what it reads | what it catches | how long |
|---|---|---|---|
| `npm run check` | the code, without running it | a property that does not exist, a value of the wrong type, markup a keyboard cannot use | seconds |
| `npm run test:unit` | functions and components, run on their own | a rule that gives the wrong answer: a week, a total, a check | under a second |
| `npm run test:e2e` | the whole planner, built and served, in a browser | a journey that no longer works: a form, a link, a redirect, JavaScript off | seconds, and a build |

**Most of the tests belong in the middle row.** A unit test is fast and points at the exact line that
broke; it can list twenty edge cases of a date in a table. An end-to-end test is slower and, when it
fails, says only that a journey broke somewhere between the browser and the file, so it is kept for the
few journeys that matter most. The planner has five, and adding a sixth for every feature would make
the suite slow and tell you little more.

Two things are worth never testing. **The framework**: whether `$derived` recalculates or `use:enhance`
sends a form is Svelte's and SvelteKit's to test, and they do. **The exact markup**: a test that checks
for `<p class="svelte-1x2y3z">` breaks every time a style changes and catches nothing. The planner's
tests ask for text a person reads and controls a person uses, which is why they can survive a redesign.

One script runs everything, in order from the fastest:

```
ana@dev:~/planner$ npm pkg set scripts.test='npm run check && npm run test:unit && npm run test:e2e'
```

```
ana@dev:~/planner$ npm test 2>&1 | grep -E 'svelte-check found|Tests|passed|failed'
svelte-check found 0 errors and 0 warnings
 Test Files  4 passed (4)
      Tests  22 passed (22)
  5 passed (8.2s)
```

**All green**, from the type checker to a browser with JavaScript off. `&&` stops at the first command
that fails, so a type error is reported before the slower tests spend time on code that does not
compile. Run `npm test` before every commit; a project that runs it on every push, in a service such as
GitHub Actions, is a project where nobody has to remember to.

Commit the lesson's work:

```sh
git add -A && git commit -m "Lesson 19: unit tests with Vitest, end-to-end tests with Playwright"
```
