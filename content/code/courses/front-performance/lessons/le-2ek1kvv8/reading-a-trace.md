---
title: Reading a trace
version: 1
---

**A trace of the slow click from lesson 5**, on the five-thousand-course plan, with the processor
four times slower: open a course page, then click *All courses*, which draws the home page in the
browser.

```
ana@dev:~/planner$ node gen.ts 5000 && node tools/trace.ts http://localhost:3000/courses/course-1 --cpu 4 --click "text=All courses"
5000 courses
long task at 49 ms, 64 ms: other 64
long task at 241 ms, 83 ms: Evaluate module 72, other 6
long task at 1225 ms, 79 ms: Evaluate script 65, other 14
long task at 1381 ms, 102 ms: Event (click) 71, Layout 14, other 8
```

Four long tasks, and **not all of them are the page's**. Read them in order:

- **the first**, a few milliseconds after the navigation began, has nothing named inside it: no HTML,
  no script, no style. It is the browser's own work, messages between its processes, done on the
  page's thread before the page exists. The panel draws it too, and it is nobody's to fix.
- **Evaluate module** is the planner's script: `main.ts` and everything it imports, run once. At a
  quarter of the speed it takes about 70 milliseconds.
- **Evaluate script**, just before the click, is not the planner's at all. It is Playwright,
  evaluating its own script inside the page to find the element called *All courses*. The tool that
  measures is in the measurement.
- **Event (click)** is the planner's handler: it counts five thousand courses' sessions and draws the
  home page, and then the browser lays it out. Lesson 5 brought this click down to a good INP, and it
  is still a long task.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"The long tasks of the traced click, along time. At 49 ms, 64 ms: other. At 241 ms, 83 ms: Evaluate module. At 1225 ms, 79 ms: Evaluate script. At 1381 ms, 102 ms: Event (click). The first is the browser&#x27;s own, the third is Playwright finding the element, and the second and the fourth are the planner&#x27;s.\"><rect x=\"59.6\" y=\"120\" width=\"25.6\" height=\"30\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><line x1=\"72.4\" y1=\"68\" x2=\"72.4\" y2=\"118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"72.4\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nothing named</text><text x=\"72.4\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">64 ms · the browser</text><rect x=\"136.4\" y=\"120\" width=\"33.2\" height=\"30\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><line x1=\"153.0\" y1=\"118\" x2=\"153.0\" y2=\"118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"153.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Evaluate module</text><text x=\"153.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">83 ms · the planner</text><rect x=\"530.0\" y=\"120\" width=\"31.6\" height=\"30\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><line x1=\"545.8\" y1=\"68\" x2=\"545.8\" y2=\"118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"545.8\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Evaluate script</text><text x=\"545.8\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">79 ms · Playwright</text><rect x=\"592.4\" y=\"120\" width=\"40.800000000000004\" height=\"30\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><line x1=\"612.8\" y1=\"118\" x2=\"612.8\" y2=\"118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"612.8\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Event (click)</text><text x=\"612.8\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">102 ms · the planner</text><line x1=\"40\" y1=\"166\" x2=\"680\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"680.0,166.0 672.6,169.1 672.6,162.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"40.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"200.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">400</text><text x=\"360.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">800</text><text x=\"520.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1200</text><text x=\"680.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1600</text></svg>", "caption": "Two of the four long tasks are not the page's."}
```

## Testing a guess

**A trace invites guesses, and the cheap ones can be tested.** Two of them here.

The Evaluate script just before the click is Playwright's: then it goes away without the click.

```
ana@dev:~/planner$ node tools/trace.ts http://localhost:3000/courses/course-1 --cpu 4
long task at 24 ms, 73 ms: other 72
long task at 156 ms, 62 ms: Layout 29, Recalculate style 24, other 5
long task at 251 ms, 81 ms: Evaluate module 71, other 4
```

It went. A style and layout task turned up near the start instead, which the run before did not
have: the first few hundred milliseconds vary a little from one run to the next, which is one more
reason to run twice and trust only the tasks that stay. And a second guess, the one most people make on reading *Evaluate module*: the script is slow
because it reads a plan of five thousand courses out of the page. Then it is fast with the three-course
plan. Put the real plan back and look:

```
ana@dev:~/planner$ cp public/courses.json dist/ && node tools/trace.ts http://localhost:3000/courses/git --cpu 4
long task at 143 ms, 64 ms: Evaluate module 56, other 4
```

**56 milliseconds against 72, so the guess was mostly wrong.** Most of the task is still there with
three courses: the plan's size is a small part of what it costs at most, and evaluating the planner's
script is the rest, whatever the data. Where those milliseconds go is inside the task,
in the panel: open `trace.json`, find the task, and the flame chart under it
says which function took the time.

## What a trace is good for

**Lighthouse found the heavy page; the trace says what each piece of a slow moment was.** A long task
in the panel is the moment a tap would have waited, and its flame chart names the code. That is the
step between "the page is slow" and a change somebody can make, and it is always worth checking that
the slow thing is the page's and not the tool's.
