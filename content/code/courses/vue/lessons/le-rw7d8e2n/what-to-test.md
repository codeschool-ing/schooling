---
title: What to test, and what to leave
version: 1
---

**The whole suite, once:**

```
ana@dev:~/vue/planner$ npm test -- --run

> planner@0.0.0 test
> vitest --run


 RUN  v5.0.5 /home/ana/vue/planner

 ✓ src/planner.test.ts (7 tests) 6ms
 ✓ src/components/SessionForm.test.ts (3 tests) 93ms
 ✓ src/views/HomeView.test.ts (2 tests) 124ms
 ✓ src/components/SessionRow.test.ts (4 tests) 54ms
 ✓ src/stores/planner.test.ts (4 tests) 16ms

 Test Files  5 passed (5)
      Tests  20 passed (20)
   Start at  22:07:21
   Duration  1.89s (environment 77%, import 13%, tests 7%, transform 3%, worker 1%)

Environment  jsdom was created 5 times · 3.21s total, 77% of tracked time
             create it once per worker with pool: 'vmThreads' (keeps per-file isolation) or isolate: false (shares it across files)
             learn more: https://vitest.dev/guide/improving-performance#test-environments
```

**Twenty tests in five files, in about two seconds**, most of it spent making five jsdom documents,
one per file, so that no file's test can see another's; the note under the summary says how to trade
some of that isolation for speed, and the planner does not need to. The tests are TypeScript, so they
are type-checked with everything else:

```
ana@dev:~/vue/planner$ npm run type-check

> planner@0.0.0 type-check
> vue-tsc --noEmit
```

## Where the tests are, and where they are not

The planner now has tests at three heights, and the counts say something:

| what | tests | what it costs to write one |
| --- | --- | --- |
| `planner.ts`, rules over values | 7 | a line of input and a line of answer |
| components, mounted alone | 7 | a store, props, a few events |
| the store, and a page | 6 | a fake `fetch`, a fake clock |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"What each kind of test in the planner touches. A test of planner.ts gives a function a value and reads the answer, and touches nothing else. A test of SessionRow or SessionForm mounts the component in jsdom with a fresh Pinia store. A test of the store or of the week page also replaces fetch with an answer the test chooses, and the week page&#x27;s test replaces the clock too. The further down, the more each test sets up, and the fewer of them the planner has.\"><text x=\"20\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planner.test.ts</text><text x=\"215\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">7</text><rect x=\"250\" y=\"30\" width=\"86\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"293\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">planner.ts</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SessionRow / SessionForm</text><text x=\"215\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">7</text><rect x=\"250\" y=\"92\" width=\"86\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"293\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">component</text><rect x=\"342\" y=\"92\" width=\"86\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"385\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">jsdom</text><rect x=\"434\" y=\"92\" width=\"86\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"477\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Pinia</text><text x=\"20\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planner / HomeView</text><text x=\"215\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">6</text><rect x=\"250\" y=\"154\" width=\"86\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"293\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">store, page</text><rect x=\"342\" y=\"154\" width=\"86\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"385\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">jsdom</text><rect x=\"434\" y=\"154\" width=\"86\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"477\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Pinia</text><rect x=\"526\" y=\"154\" width=\"86\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"569\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fake fetch</text><rect x=\"618\" y=\"154\" width=\"86\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"661\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fake clock</text><text x=\"215\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tests</text></svg>", "caption": "The cheapest tests touch the least, and the planner has the most of them."}
```

**Most of the tests are where they are cheapest and most precise**, on the pure functions, and the
lessons that put the rules there, lesson 3 and lesson 10, are the reason the components needed so few.
That is the shape to aim for in any Vue project: rules in plain functions and composables that can be
tested alone, components thin enough that a few tests of what they draw and emit are enough.

What these tests do not do, on purpose:

- **They do not check Vue.** No test asserts that a `computed` recomputes or that `v-model` binds; Vue
  has its own tests for that, and a test of the framework fails only when the framework does.
- **They do not check every page.** `CourseView`, the router and the dialog have none. Each would
  need a router or a real browser for what little logic it has, and the router's guard is the one
  piece that would be next: it decides who sees a `not-found` page.
- **They do not run in a real browser.** jsdom has no layout, no focus rings, no real `<dialog>`; a
  test of how the dialog traps focus, lesson 15's concern, belongs to a browser test, Playwright or
  Vitest's own browser mode, which `front-quality` lessons 10 to 12 take up with accessibility.
- **They are not counted by coverage.** Vitest can report which lines ran (`--coverage`, with
  `@vitest/coverage-v8` installed), and the number is a map of what nobody tested, not a target. A
  test written to raise it checks that a line ran, not that it was right.

The Nuxt planner has no tests in this course. `@nuxt/test-utils` runs Vitest inside a Nuxt
environment, with auto-imports and server routes available, and everything in this lesson carries
over; what it adds is the Nuxt runtime, which the next lesson leaves behind for the frameworks beside
Vue.
