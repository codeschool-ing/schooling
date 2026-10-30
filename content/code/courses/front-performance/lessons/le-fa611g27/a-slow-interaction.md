---
title: A slow interaction, found and fixed
version: 1
---

**INP needs an interaction that does real work, and the planner's do almost none with three
courses.** Lesson 3's `gen.ts` makes a plan of any size. With five thousand courses, the size of a
large school's catalogue, open a course page on a processor slowed four times and click *All
courses*, which draws the home page from the plan in the browser:

```
ana@dev:~/planner$ node gen.ts 5000 && node tools/vitals.ts http://localhost:3000/courses/course-1 --cpu 4 --click "text=All courses"
5000 courses
[vitals] LCP 144 ms good #notice
[vitals] CLS 0.000 good 
[vitals] INP 1888 ms poor  (input 1, processing 1762, presentation 125)
```

`gen.ts` writes `dist/courses.json`, which `server.ts` reads on every request, so no restart is
needed. **The click took almost two seconds to show anything, and almost all of it was processing**:
the input delay was nothing, the handler was everything. The handler is `draw`, which calls
`homePage`, and `homePage` counts each course's sessions by filtering every session, for every
course. Five thousand courses times five thousand sessions is twenty-five million comparisons, in one
task, while the page cannot paint.

## Step one: count once

Counting every course's sessions needs one pass over the sessions, not one per course. In
`src/view.ts`, replace the first lines of `homePage`, up to and including the `courses` it builds,
with these:

```typescript
export function homePage(plan: Plan): string {
  // One pass over the sessions counts every course's, however many courses there are.
  const count = new Map<string, number>();
  for (const s of plan.sessions) count.set(s.course, (count.get(s.course) ?? 0) + 1);
  const courses = plan.courses.map((c) =>
    `<li><a href="/courses/${esc(c.slug)}">${esc(c.title)}</a> · ${count.get(c.slug) ?? 0} sessions</li>`);
```

Build, restart, and click again:

```
ana@dev:~/planner$ node gen.ts 5000 && node tools/vitals.ts http://localhost:3000/courses/course-1 --cpu 4 --click "text=All courses"
5000 courses
[vitals] LCP 152 ms good #notice
[vitals] CLS 0.000 good 
[vitals] INP 848 ms poor  (input 3, processing 723, presentation 123)
```

**More than half the time went, and the interaction is still poor.** The counting is gone from the processing;
what is left is building five thousand list items. `innerHTML` parses them and the browser creates
every one inside the same handler, and then lays them out for the presentation delay.

## Step two: draw less

Nobody reads five thousand courses on one page. A page of a hundred and a line saying how many more
there are is what a person can use, and it is a hundred list items to build. Replace the two lines
that build `courses` with these four:

```typescript
  // A page shows the first hundred courses; a list of thousands is a search, not a page.
  const courses = plan.courses.slice(0, 100).map((c) =>
    `<li><a href="/courses/${esc(c.slug)}">${esc(c.title)}</a> · ${count.get(c.slug) ?? 0} sessions</li>`);
  if (plan.courses.length > 100) courses.push(`<li>and ${plan.courses.length - 100} more</li>`);
```

```
ana@dev:~/planner$ node gen.ts 5000 && node tools/vitals.ts http://localhost:3000/courses/course-1 --cpu 4 --click "text=All courses"
5000 courses
[vitals] LCP 148 ms good #notice
[vitals] CLS 0.000 good 
[vitals] INP 88 ms good  (input 1, processing 61, presentation 25)
```

**Good.** The same click, the same data and the same slowed processor. The first fix removed work
nobody needed; the second removed work nobody would have seen.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Three measurements of the same click on All courses, with five thousand courses and the processor four times slower. As it was: INP 1888 ms, of which 1762 processing. Counting once: 848 ms, 723 processing. Drawing a hundred courses: 88 ms.\"><text x=\"148\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">as it was</text><rect x=\"160.23\" y=\"40\" width=\"405.26\" height=\"24\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"565.49\" y=\"40\" width=\"28.75\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"602.24\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1888 ms</text><text x=\"148\" y=\"104\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">count once</text><rect x=\"160.69\" y=\"92\" width=\"166.29000000000002\" height=\"24\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"326.98\" y=\"92\" width=\"28.290000000000003\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"363.04\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">848 ms</text><text x=\"148\" y=\"156\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">draw a hundred</text><rect x=\"160.23\" y=\"144\" width=\"14.030000000000001\" height=\"24\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"174.26\" y=\"144\" width=\"5.75\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"188.24\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">88 ms</text><line x1=\"206.0\" y1=\"30\" x2=\"206.0\" y2=\"186\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"210.0\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">200 ms: good</text><rect x=\"420\" y=\"194\" width=\"12\" height=\"12\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"438\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">processing</text><rect x=\"540\" y=\"194\" width=\"12\" height=\"12\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"558\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">presentation</text></svg>", "caption": "The first fix removed work nobody needed; the second, work nobody would have seen."}
```

## When the work cannot be removed

Some work is real and has to run: a chart, a long calculation. Then the fix is to **give the browser
a chance to paint before doing it**. A handler that changes something small at once, shows that the
click was received, and leaves the heavy part to a later task, with `setTimeout`, or with
`scheduler.yield()` in a browser that has it, ends its interaction at the first paint. Splitting
long work into pieces that each yield keeps every other tap answered too. The work still costs what
it costs; INP measures how long the person waited to see that something happened.

Put the real plan back when you are done: `npm run build` copies `public/courses.json` into `dist/`
again.
