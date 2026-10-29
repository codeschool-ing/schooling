---
title: The same page, four ways
version: 1
---

**All four send the course page finished, in the first response, exactly as `server.ts` did in
lesson 1.** That is the part they agree on. Where they differ is in everything that comes with it,
and the differences are large enough to measure. With the four production servers running, on
ports 3001 to 3004, and `server.ts` from lesson 1 on port 3000, ask each for the Git course and keep
only the heading:

```
ana@dev:~/planner$ for p in 3000 3001 3002 3003 3004; do curl -s http://localhost:$p/courses/git | grep -o '<h1>Git</h1>'; done
<h1>Git</h1>
<h1>Git</h1>
<h1>Git</h1>
<h1>Git</h1>
<h1>Git</h1>
```

Five servers, five headings, each in the HTML as it left the server. A crawler and a link preview
would read every one of them.

## A course that does not exist

Three of the four sections before this one gave their course page a line for an unknown slug.
Ask all five servers for one, and print only the status:

```
ana@dev:~/planner$ for p in 3000 3001 3002 3003 3004; do curl -s -o /dev/null -w "$p %{http_code}\n" http://localhost:$p/courses/nonsense; done
3000 200
3001 200
3002 404
3003 404
3004 200
ana@dev:~/planner$ curl -s http://localhost:3001/courses/nonsense | grep -o '<meta name="robots"[^>]*>'
<meta name="robots" content="noindex"/>
```

**Two of the five answer 404, and the three that do not are wrong in three different ways.**
Lesson 1's `server.ts` answers 200 because it never sets a status: its page says *No such course*
and the response says everything is fine. The Angular project as written here answers 200 with an
empty course page, because its component found nothing and rendered nothing, and a component cannot
fail a response on its own. Angular sets a status from the server through `RESPONSE_INIT`, which
this lesson leaves out.

**Next.js called `notFound()` and still answered 200**, and that one is not a mistake in the page.
The course route is partly prerendered: its shell, with the status line, had already been sent when
the server reached the line that found no course. What Next.js could still do, it did: it streamed
its own not-found page into the response and added a tag that tells search engines not to keep it.
A status cannot change once a response has started, and lesson 4 is about responses that start
before the server knows everything.

## What each one costs the browser

`tools/weigh.ts` opens each address in Chromium and reports the size of the HTML, how many script
files the page ran, how much JavaScript that was, and when the first content was painted. **The
sizes are measured before any compression**, because the four servers compress differently, or not
at all, and the comparison should be about what each framework sends and runs, not about how a
server was configured. Chromium's own coverage records which scripts ran. Save it in the planner's
`tools/`, beside `look.ts`:

```typescript
// tools/weigh.ts: what a page costs the browser that opens it.
//
//   node tools/weigh.ts URL...
//
// For each address: the size of the HTML, how many script files the page ran,
// how much JavaScript that was before any compression, and when the first
// content appeared. Sizes are uncompressed, so a server that compresses and
// one that does not are compared on the same footing.
import { chromium } from "playwright";

const browser = await chromium.launch();
console.log("  html KB  files  JS KB run  first paint  address");
for (const url of process.argv.slice(2)) {
  const page = await browser.newPage();
  await page.coverage.startJSCoverage();
  await page.goto(url, { waitUntil: "networkidle" });
  const ran = await page.coverage.stopJSCoverage();
  const r = await page.evaluate(() => {
    const nav = performance.getEntriesByType("navigation")[0] as PerformanceNavigationTiming;
    const fcp = performance.getEntriesByName("first-contentful-paint")[0];
    return { html: nav.decodedBodySize, fcp: fcp ? Math.round(fcp.startTime) : 0 };
  });
  const files = ran.filter((s) => s.url !== url);
  const js = ran.reduce((sum, s) => sum + (s.source?.length ?? 0), 0);
  const kb = (n: number) => (n / 1024).toFixed(1).padStart(9);
  console.log(`${kb(r.html)}  ${String(files.length).padStart(5)}  ${kb(js)}  ${String(r.fcp).padStart(8)} ms  ${url}`);
  await page.close();
}
await browser.close();
```

`JS KB run` counts every script the page ran, the files and the ones written inside the HTML.
Run it against all five:

```
ana@dev:~/planner$ node tools/weigh.ts http://localhost:3000/courses/git http://localhost:3001/courses/git http://localhost:3002/courses/git http://localhost:3003/courses/git http://localhost:3004/courses/git
  html KB  files  JS KB run  first paint  address
      0.9      1        2.8        44 ms  http://localhost:3000/courses/git
      6.6      7      459.9        32 ms  http://localhost:3001/courses/git
      2.3      6      195.8        36 ms  http://localhost:3002/courses/git
      4.1     10       89.1        28 ms  http://localhost:3003/courses/git
      2.2      1      264.2        64 ms  http://localhost:3004/courses/git
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A bar chart of the JavaScript each server&#x27;s Git page ran in Chromium, uncompressed, as tools/weigh.ts measured it. Lesson 1&#x27;s plain planner: 2.8 KB. SvelteKit: 89.1 KB. Nuxt: 195.8 KB. Angular: 264.2 KB. Next.js: 459.9 KB.\"><text x=\"140\" y=\"42\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">plain planner</text><rect x=\"150\" y=\"30\" width=\"2.922374429223744\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"160.92237442922374\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2.8 KB</text><text x=\"140\" y=\"80\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">SvelteKit</text><rect x=\"150\" y=\"68\" width=\"92.9941291585127\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250.9941291585127\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">89.1 KB</text><text x=\"140\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Nuxt</text><rect x=\"150\" y=\"106\" width=\"204.35746901500326\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"362.3574690150033\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">195.8 KB</text><text x=\"140\" y=\"156\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Angular</text><rect x=\"150\" y=\"144\" width=\"275.74690150032615\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"433.74690150032615\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">264.2 KB</text><text x=\"140\" y=\"194\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Next.js</text><rect x=\"150\" y=\"182\" width=\"479.99999999999994\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"638.0\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">459.9 KB</text><line x1=\"150\" y1=\"222\" x2=\"640\" y2=\"222\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"150\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">JavaScript run by the Git page, uncompressed</text></svg>", "caption": "The same page, with the same HTML in its first response, and five very different amounts of code to run once it has arrived."}
```

## Reading those numbers fairly

**Every first paint is between 28 and 64 milliseconds, on this machine.** The
servers are on the same computer as the browser, and each sent the content in its first response,
so nothing waited on JavaScript before painting. The differences in the last column are noise at
this size; lesson 5 measures with the network slowed down, where they stop being noise.

**The JavaScript column is not noise, and it is the price of the framework.** The plain planner
runs its own three files, bundled. Each of the four runs its UI framework, its router and the code
that hydrates the page, for a page that has two links and nothing to click. That is a fixed cost:
it does not grow with the number of pages, and on a large app the app's own code ends up being
most of the total. On a page this small it is all there is, which is why it is easy to see here.

The order of the four in that column says something about how each was designed, and nothing about
which one to choose. **SvelteKit, at 89.1 KB, ships the least**: Svelte compiles each component into
the code that updates it, so there is little general-purpose runtime to send. Next.js, at 459.9 KB,
ships the most: React in the browser receives the description of the page that the server rendered,
the payload of the next section, and keeps the machinery to render from it again on every
navigation. Nuxt and Angular sit between, with Angular's 264.2 KB in a single file that holds its
change detection, its router and its HTTP client together. **A meta-framework's weight is one input
to a decision, and lesson 8 shows how much of any app's JavaScript can be postponed** until a page
needs it.
