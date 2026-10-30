---
title: The logic travels, the screen does not
version: 1
---

**The planner's core from lesson 1 is plain TypeScript with no screen in it, and that is exactly why
it can go anywhere JavaScript runs.** A React Native app, a Capacitor app, a web page and a terminal
can all import `planner.ts` unchanged. A screen cannot travel the same way, because a screen is
written against one thing that draws, and that thing is not everywhere. You can watch both halves
of that sentence on your own computer.

## The core, unchanged

In `~/planner`, run lesson 1's `week.ts` again. Nothing in it or in `planner.ts` has changed:

```
ana@dev:~/planner$ node week.ts
{ monday: '2026-10-19', planned: 180, done: 120 }
```

**Same numbers, on a machine that has no phone and no browser.** Node.js is one more host for the
core, alongside the phone's JavaScript engine in a React Native app and the WebView in a wrapper.

## A screen written for the browser

Now write the week's line the way a web page would draw it, with the DOM: create a paragraph, put the
text in it, add it to the page. Save it as `screen-web.ts`:

```typescript
// screen-web.ts: the week's line, drawn with the browser's DOM
import { weekTotal, type Plan } from "./planner.ts";

export function drawWeek(plan: Plan, today: string) {
  const t = weekTotal(plan, today);
  const line = document.createElement("p");
  line.textContent = `${t.done} of ${t.planned} minutes done`;
  document.body.append(line);
}

drawWeek({ courses: [], sessions: [] }, "2026-10-21");
```

Run it:

```
ana@dev:~/planner$ node screen-web.ts
file:///home/ana/planner/screen-web.ts:6
  const line = document.createElement("p");
               ^

ReferenceError: document is not defined
    at drawWeek (file:///home/ana/planner/screen-web.ts:6:16)
    at file:///home/ana/planner/screen-web.ts:11:1
    at ModuleJob.run (node:internal/modules/esm/module_job:343:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:665:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:117:5)

Node.js v22.22.0
```

**Read where it stopped.** The `import` on line 2 worked, and so did `weekTotal`: the error points at
line 6, column 16, the first use of `document`. `document` is the page, and it exists only where a
browser engine made one. Node.js has no page, and neither does a React Native app, whose screen is
the platform's views, nor a Flutter app, whose screen is its own engine's surface. This file runs in
a browser and in a wrapper's WebView, and nowhere else.

## The same line, for a screen that exists here

The fix is not to bring the browser along. It is to write the screen again for whatever draws in this
place, and keep calling the same core. In a terminal, a screen is lines of text. Save this as
`screen-term.ts`:

```typescript
// screen-term.ts: the same line and button, drawn as text in a terminal
import { markDone, weekTotal, type Plan } from "./planner.ts";

function draw(plan: Plan, today: string) {
  const t = weekTotal(plan, today);
  console.log(`Week of ${t.monday}: ${t.done} of ${t.planned} minutes done   [ Mark done ]`);
}

let plan: Plan = {
  courses: [{ id: "sql", title: "SQL Databases" }],
  sessions: [
    { id: "s1", courseId: "sql", date: "2026-10-19", minutes: 50, done: true },
    { id: "s3", courseId: "sql", date: "2026-10-23", minutes: 60, done: false },
  ],
};

draw(plan, "2026-10-21");
plan = markDone(plan, "s3"); // what pressing the button does
draw(plan, "2026-10-21");
```

```
ana@dev:~/planner$ node screen-term.ts
Week of 2026-10-19: 50 of 110 minutes done   [ Mark done ]
Week of 2026-10-19: 110 of 110 minutes done   [ Mark done ]
```

Before the press, only `s1` is done: 50 of the 110 minutes planned for that week. After `markDone`,
`s3`'s 60 minutes join them, and the line reads 110 of 110. The sums came from the same `weekTotal`
that the browser screen called a moment ago.

**Two screens, one core, and only the screen was written twice.** That is the trade every approach
in this lesson makes somewhere. React Native writes the screen once against its components and lets
the platform draw it. A native team writes it twice, in Compose and SwiftUI. The core goes with
whichever language the app runs: as it is, to React Native or a wrapper; rewritten in Kotlin and in
Swift for two native apps; or written once in Kotlin, for Kotlin Multiplatform to carry to both.

Delete the browser screen, which has no host on this computer, and keep the terminal one:

```
ana@dev:~/planner$ rm screen-web.ts
ana@dev:~/planner$ git add screen-term.ts
ana@dev:~/planner$ git commit -q -m "A terminal screen over the same core"
ana@dev:~/planner$ git log --oneline
4027da0 A terminal screen over the same core
87ae50d The planner core, as lesson 1 gives it
```
