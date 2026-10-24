---
title: Loading the chart on demand
version: 1
---

**`import()`, written as a function, loads a module when the line runs**, not when the page loads. It
returns a promise of the module, so `(await import("./chart.ts")).showChart(p)` fetches the chart's
code the first time it is needed and calls it once it has arrived. And when Vite sees an `import()`, it
gives that module and what only it imports a file of its own: a **chunk**.

In `src/main.ts`, delete the line that imports `showChart`, and replace the call to `mount` with:

```typescript
mount(document.querySelector<HTMLElement>("#app")!, plan, async (p) => {
  // The chart's code is fetched the first time a page needs it, and on no other page.
  if (location.pathname === "/stats") (await import("./chart.ts")).showChart(p);
});
```

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

**Three JavaScript files now.** The `index` file every page loads is back near its old size. The `chart`
chunk is Chart.js and `chart.ts`, and only `/stats` will ask for it. The third, `planner`, half a
kilobyte, is `planner.ts`: both the entry and the chart import it, so Vite put it in a chunk of its own
that both can share, rather than a copy in each.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"The three files of the split build and which page loads them. index, 19.85 kilobytes, and planner, 0.52, are loaded by every page. chart, 132.39 kilobytes, is loaded only by the stats page, when its code asks for it.\"><rect x=\"40\" y=\"40\" width=\"63.52000000000001\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"71.76\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">index · 19.85 kB</text><rect x=\"117.52000000000001\" y=\"40\" width=\"34\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"134.52\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">planner · 0.52 kB</text><rect x=\"165.52\" y=\"40\" width=\"423.64799999999997\" height=\"40\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"377.344\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">chart · 132.39 kB</text><text x=\"150\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">every page: the course page, the home page</text><line x1=\"71.76\" y1=\"82\" x2=\"150\" y2=\"116\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><line x1=\"134.52\" y1=\"82\" x2=\"150\" y2=\"116\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><text x=\"377.344\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">only /stats, after its import()</text><line x1=\"377.344\" y1=\"82\" x2=\"377.344\" y2=\"116\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Before the split, all of it was one file, and every page loaded the chart.</text></svg>", "caption": "The code a page does not use is no longer the page's to download."}
```

Build, restart `server.ts`, and look at both pages:

```
ana@dev:~/planner$ node tools/unused.ts http://localhost:3000/courses/git
/assets/index-yh2nfJj3.js       17.7 KB, ran   8.2 KB (46%)
```

**The course page downloads no Chart.js at all**, and the stats page downloads it once it knows it needs
it. That is the whole of code splitting: the code a page does not use is not the page's to download.

## Where it arrives

```
ana@dev:~/planner$ node tools/waterfall.ts http://localhost:3000/stats --slow
/stats                         306 ms    1102 B  ######
/fonts/plex-400.woff2          621 ms   22611 B        ######
/fonts/plex-700.woff2          621 ms   22842 B        ######
/assets/index-DKgaS_OS.js      626 ms    7611 B        #######
/assets/planner-BNdUlffC.js    625 ms     321 B        #######
/assets/chart-Cq-hfvCR.js      939 ms   46407 B               ######
```

**The chart chunk is a step later than the rest.** The browser only learns that `/stats` needs it when
`main.ts` runs and reaches the `import()`, which is after the script itself has arrived: a chain, as
lesson 6's waterfalls called it. The `planner` chunk is not late, because Vite wrote a line for it into
the HTML:

```
ana@dev:~/planner$ grep -o '<link rel="modulepreload"[^>]*>' dist/index.html
<link rel="modulepreload" crossorigin href="/assets/planner-BNdUlffC.js">
```

`modulepreload` is lesson 7's hint for modules: the entry imports `planner` statically, so the browser
can fetch both at once instead of discovering the second inside the first. A module that is imported
with `import()` gets no such line, because whether it is needed is decided by the code at run time. That
step later is the price of the split, and the next section measures it from the visitor's side.
