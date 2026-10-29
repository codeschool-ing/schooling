---
title: Client-side rendering, measured
version: 1
---

**The planner as you built it is client-rendered: the server sends a page with nothing in it, and
the script draws everything.** That is how every single-page app made with a bundler starts,
whatever the framework, and it is worth seeing exactly what it sends before deciding whether it
is a problem.

## The build

The development server of the previous section rebuilds as you edit, which makes it the wrong
thing to measure. `npm run build` writes the site a host would serve into `dist/`, and
`npm run preview` serves that folder exactly as it is. Stop `npm run dev` with `Ctrl-C` first:

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 7 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                 0.46 kB │ gzip: 0.29 kB
dist/assets/index-1yLCgpWc.css  0.25 kB │ gzip: 0.20 kB
dist/assets/index-Dv4jVJdV.js   2.87 kB │ gzip: 1.37 kB

✓ built in 161ms
```

Three files and the data. `tsc` checked the types, and `vite build` bundled the three TypeScript
files into one script and gave it a name made from its content, `index-` and a hash. Lesson 9 is
about why the name changes when the content does. Now serve it, in the second terminal:

```
ana@dev:~/planner$ npm run preview

> planner@0.0.0 preview
> vite preview

  ➜  Local:   http://localhost:4173/
  ➜  Network: use --host to expose
```

## What the first response carries

Ask for the home page the way a program that does not run scripts would, with `curl`:

```
ana@dev:~/planner$ curl -s http://localhost:4173/
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Study planner</title>
    <script type="module" crossorigin src="/assets/index-Dv4jVJdV.js"></script>
    <link rel="stylesheet" crossorigin href="/assets/index-1yLCgpWc.css">
  </head>
  <body>
    <main id="app"></main>
  </body>
</html>
```

**There is no course in it.** The `<main>` is empty, and the only way to fill it is to run
`/assets/index-…js`, which fetches `/courses.json` and then draws. Vite moved the `<script>` into
the `<head>` and marked it `type="module"`, which makes the browser fetch it without stopping to
wait for it, and run it once the page has been read.

## What a browser sees

`curl` reads one response. A browser reads that response, fetches what it names, runs the script
and draws, and the only way to know what a person would see is to ask one. `tools/look.ts` opens a
page in the Chromium that Playwright installed, waits until the network has been quiet for half a
second, and prints what it requested, when the first content was painted and the text on the
screen. Save it in `tools/look.ts`:

```typescript
// tools/look.ts: open a page in Chromium and say what a person would see.
//
//   node tools/look.ts URL [--no-js] [--slow]
//
// --no-js  the browser runs no JavaScript at all, as a simple crawler does
// --slow   every request waits 300 ms longer, as on a phone far from the server
import { chromium } from "playwright";

const url = process.argv[2];
const flags = process.argv.slice(3);
const browser = await chromium.launch();
const context = await browser.newContext({ javaScriptEnabled: !flags.includes("--no-js") });
const page = await context.newPage();
if (flags.includes("--slow")) {
  const cdp = await context.newCDPSession(page);
  await cdp.send("Network.emulateNetworkConditions", {
    offline: false, latency: 300, downloadThroughput: -1, uploadThroughput: -1,
  });
}
const requests: string[] = [];
page.on("request", (r) => requests.push(new URL(r.url()).pathname));
await page.goto(url, { waitUntil: "networkidle" });
const paint = await page.evaluate(() => {
  const fcp = performance.getEntriesByName("first-contentful-paint")[0];
  return fcp ? Math.round(fcp.startTime) : null;
});
console.log("requests:", requests.join(" "));
console.log("first contentful paint:", paint === null ? "none" : `${paint} ms`);
console.log("text on the screen:");
console.log((await page.locator("body").innerText()).trim() || "(nothing)");
await browser.close();
```

Node 22 runs a `.ts` file directly: it strips the types and runs what is left, which is why no build
step comes first. **First contentful paint** is the moment the browser first drew any text or
image, as the browser itself records it; lesson 5 puts it beside the three numbers Google reads.
Run it with JavaScript, and then without:

```
ana@dev:~/planner$ node tools/look.ts http://localhost:4173/
requests: / /assets/index-Dv4jVJdV.js /assets/index-1yLCgpWc.css /courses.json
first contentful paint: 56 ms
text on the screen:
Study planner
HTML and CSS · 2 sessions
JavaScript · 2 sessions
Git · 2 sessions
Weeks
Week of 2026-10-19: 210 min, 105 done
Week of 2026-10-26: 40 min, 0 done
ana@dev:~/planner$ node tools/look.ts http://localhost:4173/ --no-js
requests: / /assets/index-1yLCgpWc.css
first contentful paint: none
text on the screen:
(nothing)
```

With JavaScript, four requests and the whole page. Without it, **two requests and nothing at all**:
the browser read the HTML, fetched the stylesheet it names, had no script to run and so had
nothing to draw, and it never painted anything, which is why the paint reads `none`. That second
run is what a program that reads pages without running scripts receives from a client-rendered
app, and it is also what a person sees for as long as the script is still on its way.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The chain of a client-rendered page. The HTML names a script and a stylesheet; the script, once it runs, asks for courses.json; only when that arrives is anything drawn into the empty main. Each arrow is a request the browser could not have made before the previous response arrived.\"><rect x=\"20\" y=\"40\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/</text><text x=\"95\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;main id=\"app\"&gt;</text><rect x=\"230\" y=\"25\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/assets/index-….js</text><rect x=\"230\" y=\"80\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/assets/index-….css</text><line x1=\"170\" y1=\"60\" x2=\"228\" y2=\"45\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"228.0,45.0 221.6,49.9 220.1,43.8\" fill=\"var(--paper-dim)\"></polygon><line x1=\"170\" y1=\"80\" x2=\"228\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"228.0,100.0 220.0,100.5 222.0,94.7\" fill=\"var(--paper-dim)\"></polygon><rect x=\"470\" y=\"25\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"530\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/courses.json</text><line x1=\"410\" y1=\"45\" x2=\"468\" y2=\"45\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"468.0,45.0 460.6,48.1 460.6,41.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"470\" y=\"140\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"585\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">the list is drawn</text><text x=\"585\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">first contentful paint</text><line x1=\"530\" y1=\"65\" x2=\"560\" y2=\"138\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"560.0,138.0 554.3,132.4 560.1,130.0\" fill=\"var(--phosphor)\"></polygon><text x=\"95\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1st response</text><text x=\"320\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2nd</text><text x=\"530\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3rd</text><text x=\"20\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Without JavaScript the chain stops after the stylesheet, and nothing is drawn.</text></svg>", "caption": "Three responses in a row, each needed before the next request can even be made."}
```

## Why it is popular anyway

Nothing above makes client rendering wrong. After the first load, every click in the planner is
handled in the browser: the link handler in `mount` changes the address and redraws, and nothing
goes to the server at all. The host needs no program, only files, which is the cheapest hosting
there is. And the server never sees anybody's data, so there is nothing per user to protect on
it. A tool used all day by people who are signed in, like an email client, a spreadsheet or an
admin screen, pays for one slow first load and gets a fast app for the rest of the day.

The cost is all at the start, and it lands hardest on the visitors with the slowest connection,
who wait for the three trips one after another. The section after next measures exactly that.
