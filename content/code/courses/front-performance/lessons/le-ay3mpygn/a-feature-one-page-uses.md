---
title: A feature only one page uses
version: 1
---

**The planner gets a chart of the minutes studied each week**, on a page of its own at `/stats`. The
chart is drawn by **Chart.js**, a popular library that draws charts on a canvas. It runs in the
visitor's browser, so it is a dependency of the app, like `web-vitals`:

```
ana@dev:~/planner$ npm install --save-exact chart.js@4.5.1

added 2 packages, and audited 148 packages in 684ms

34 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

`src/chart.ts` draws the chart on the page's canvas. It imports Chart.js the way its documentation
starts, from `chart.js/auto`, which registers every kind of chart the library has. And it marks when it
drew, as `data-hydrated` does, so a tool can read it later. Save it in `src/`:

```typescript
// src/chart.ts: the minutes of each week as a bar chart, drawn by Chart.js.
import { Chart } from "chart.js/auto";
import { weeks, weekTotal, type Plan } from "./planner.ts";

let chart: Chart | undefined;
export function showChart(plan: Plan): void {
  const labels = weeks(plan.sessions);
  chart?.destroy();
  chart = new Chart(document.querySelector<HTMLCanvasElement>("#chart")!, {
    type: "bar",
    data: { labels, datasets: [{ label: "minutes", data: labels.map((m) => weekTotal(plan.sessions, m)) }] },
    options: { animation: false },
  });
  // When it was drawn, for a tool to read, as data-hydrated says when the page was taken over.
  document.documentElement.dataset.chart = String(Math.round(performance.now()));
}
```

## The page

In `src/view.ts`, the stats page shows a canvas and, under it, the same totals as a list, which is
what a screen reader reads and what a page without its script shows. Add it right before the comment
that starts `// The page an address names`:

```typescript
// The minutes of every week: the list, and a canvas the chart is drawn on in the browser.
export function statsPage(plan: Plan): string {
  const totals = weeks(plan.sessions).map((monday) => `<li>Week of ${monday}: ${weekTotal(plan.sessions, monday)} min</li>`);
  return `<p><a href="/">All courses</a></p>
<h1>Minutes per week</h1>
<canvas id="chart" width="640" height="320" role="img" aria-label="The minutes of each week, as bars"></canvas>
<ul class="weeks">${totals.join("")}</ul>`;
}
```

`page` learns the new address. Replace it, with its comment, with:

```typescript
// The page an address names: /courses/<slug> is one course, /stats the weeks, anything else the list.
export function page(plan: Plan, path: string): string {
  const m = path.match(/^\/courses\/([a-z0-9-]+)$/);
  return m ? coursePage(plan, m[1]) : path === "/stats" ? statsPage(plan) : homePage(plan);
}
```

The home page links to it. Replace the line `<h2>Weeks</h2>` in `homePage` with:

```html
<h2>Weeks</h2>
<p><a href="/stats">Minutes per week</a></p>
```

## Drawing after each draw

A chart is not HTML: it is drawn by a script after the page is. So `mount` takes a third argument, a
function it calls every time it has drawn the page. Replace its first three lines, up to and including
the one that defines `draw`, with:

```typescript
export function mount(root: HTMLElement, start: Plan, drawn: (plan: Plan) => void = () => {}): void {
  let plan = start;
  // drawn is told every time the page has been drawn, so it can add what HTML cannot, such as a chart.
  const draw = () => { root.innerHTML = page(plan, location.pathname); drawn(plan); };
```

and the lines at its end, from `if (!root.firstElementChild) {` down to the one that sets
`data-hydrated`, with these, which also tell `drawn` when the server's page was right as it was:

```typescript
  if (!root.firstElementChild) {
    draw();
  } else if (!same(root, page(plan, location.pathname))) {
    console.warn("hydration mismatch: the page the server sent is not the page this script draws; drawing again");
    draw();
  } else {
    drawn(plan);
  }
  document.documentElement.dataset.hydrated = String(Math.round(performance.now()));
```

Last, `src/main.ts` passes that function. Add the import after the one of `view.ts`:

```typescript
import { showChart } from "./chart.ts";
```

and replace the call to `mount` with:

```typescript
mount(document.querySelector<HTMLElement>("#app")!, plan, (p) => {
  if (location.pathname === "/stats") showChart(p);
});
```

## What it cost every page

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 9 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                  0.69 kB │ gzip: 0.35 kB
dist/assets/index-gserWk4t.css   0.76 kB │ gzip: 0.41 kB
dist/assets/index-yh2nfJj3.js   18.08 kB │ gzip: 6.95 kB

✓ built in 192ms
```

**From eighteen kilobytes to more than two hundred**, and every page pays it. Build, restart
`server.ts`, and ask the coverage of both pages:

```
ana@dev:~/planner$ node tools/unused.ts http://localhost:3000/courses/git
/assets/index-yh2nfJj3.js       17.7 KB, ran   8.2 KB (46%)
```

**The course page runs about an eighth of what it downloads.** It never draws a chart, and it
downloaded, parsed and compiled all of Chart.js anyway. Even the stats page runs less than half of it,
because `chart.js/auto` brought every kind of chart and this page draws one.
