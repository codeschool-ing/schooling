---
title: The planner so far
version: 1
---

**Three components now, nested the way lesson 1's tree drew them, and each one standalone.** `App`
imports `Week`, `Week` imports `WeekSummary`, and none of them is declared anywhere else. This section
looks at the result, runs the tests, and commits.

```
ana@dev:~/planner$ look http://localhost:4200/
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Study planner
This week

This week: nothing planned yet.
```

Three lines of the page, one per component: the heading is `App`'s, `This week` is `Week`'s, and the
sentence is `WeekSummary`'s. The page does not show where one component ends and the next begins, and
that is as it should be. The accessibility tree, the structure a screen reader announces, shows the
same thing: two headings at two levels and a paragraph, and no trace of the components around them.

```
ana@dev:~/planner$ look http://localhost:4200/ --a11y body
[vite] connecting...
[vite] connected.
Angular is running in development mode.
- heading "Study planner" [level=1]
- heading "This week" [level=2]
- paragraph
  - text: This week: nothing planned yet.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Lesson 1&#x27;s component tree again, with the three components built so far drawn solid: App, Week and WeekSummary. The others, CoursePage, CourseCard, SessionList, SessionRow and AddSession, are drawn dashed, with the lesson that builds each.\"><rect x=\"290\" y=\"12\" width=\"140\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">App</text><text x=\"360.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">built</text><rect x=\"110\" y=\"90\" width=\"180\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Week</text><text x=\"200.0\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">built</text><rect x=\"430\" y=\"90\" width=\"180\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"520.0\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">CoursePage</text><text x=\"520.0\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lesson 8</text><line x1=\"330\" y1=\"54\" x2=\"220\" y2=\"88\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"220.0,88.0 226.1,82.8 228.0,88.8\" fill=\"var(--wire)\"></polygon><line x1=\"390\" y1=\"54\" x2=\"500\" y2=\"88\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"500.0,88.0 492.0,88.8 493.9,82.8\" fill=\"var(--wire)\"></polygon><rect x=\"20\" y=\"176\" width=\"150\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekSummary</text><text x=\"95.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">built</text><rect x=\"190\" y=\"176\" width=\"150\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"265.0\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">CourseCard</text><text x=\"265.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lesson 8</text><rect x=\"380\" y=\"176\" width=\"150\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"455.0\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SessionList</text><text x=\"455.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lesson 8</text><rect x=\"550\" y=\"176\" width=\"150\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"625.0\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">AddSession</text><text x=\"625.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lesson 14</text><line x1=\"170\" y1=\"132\" x2=\"95\" y2=\"174\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"95.0,174.0 99.9,167.7 103.0,173.1\" fill=\"var(--wire)\"></polygon><line x1=\"230\" y1=\"132\" x2=\"265\" y2=\"174\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"265.0,174.0 257.9,170.3 262.7,166.3\" fill=\"var(--wire)\"></polygon><line x1=\"490\" y1=\"132\" x2=\"455\" y2=\"174\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"455.0,174.0 457.3,166.3 462.1,170.3\" fill=\"var(--wire)\"></polygon><line x1=\"550\" y1=\"132\" x2=\"625\" y2=\"174\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"625.0,174.0 617.0,173.1 620.1,167.7\" fill=\"var(--wire)\"></polygon></svg>", "caption": "Three of lesson 1's components exist; the dashed ones say which lesson builds them."}
```

## The tests

`ng generate` wrote a test for `Week` as it did for `WeekSummary`, and both check only that the
component can be created. `App`'s second test still looks for the heading:

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | tail -9
 ✓ |planner| src/app/week/week.spec.ts (1 test) 53ms
 ✓ |planner| src/app/week-summary/week-summary.spec.ts (1 test) 73ms
 ✓ |planner| src/app/app.spec.ts (2 tests) 73ms

 Test Files  3 passed (3)
      Tests  4 passed (4)
   Start at  20:38:08
   Duration  1.56s (transform 229ms, setup 1.10s, import 234ms, tests 199ms, environment 2.22s)
```

Four tests, three files, all passing. **Creating `App` in a test creates `Week` and `WeekSummary` as
well**, because `App`'s template uses them: a component test runs the real components it imports, not
stand-ins, unless you replace them on purpose. Lesson 24 is about when you would.

## A commit

```
ana@dev:~/planner$ git add -A && git commit -q -m "Standalone components: the week and its summary"
```

From here on, each lesson ends with the planner committed, and the lesson after starts from that
commit. If yours and the course's drift apart, `git diff` against your last commit is the first
thing to read.
