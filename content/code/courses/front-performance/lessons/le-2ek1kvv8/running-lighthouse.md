---
title: Running Lighthouse
version: 1
---

**Lighthouse is a Node program**, maintained by Google, that opens Chrome, loads one address, and
writes a report. Install it into the planner as a development tool, at a fixed version, like every
tool in this course:

```
ana@dev:~/planner$ npm install --save-exact --save-dev lighthouse@13.5.0
npm warn deprecated @opentelemetry/sdk-trace-base@2.12.0: Use @opentelemetry/sdk-trace package

added 112 packages, and audited 136 packages in 5s

28 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

## Which Chrome it opens

Lighthouse looks for Chrome where Chrome is usually installed. **You already have a Chromium**:
Playwright's, from lesson 1. `CHROME_PATH` tells Lighthouse to use it, and Playwright will say
where it is:

```
ana@dev:~/planner$ export CHROME_PATH=$(node -e 'import("playwright").then((p) => console.log(p.chromium.executablePath()))')
ana@dev:~/planner$ echo $CHROME_PATH
/home/ana/.cache/ms-playwright/chromium-1243/chrome-linux64/chrome
```

`export` keeps the variable for the rest of this terminal, and only this one: type it again in every
new terminal you run Lighthouse from. On a computer with Chrome installed you can skip it, and
Lighthouse will open that Chrome instead; the scores may then differ a little from the ones here,
because it is a different browser.

## A script for the options

The options this course always passes are long, so put them in `package.json` once, as a script
called `lighthouse`:

```
ana@dev:~/planner$ npm pkg set scripts.lighthouse='lighthouse --quiet --chrome-flags=--headless=new --only-categories=performance --output=json --output=html --output-path=report'
```

- `--quiet` prints nothing while it works;
- `--chrome-flags=--headless=new` runs the browser with no window;
- `--only-categories=performance` leaves out accessibility, best practices and SEO, which
  Lighthouse also grades and which other courses cover;
- `--output=json --output=html --output-path=report` writes the same report twice:
  `report.report.html` to read in your browser, and `report.report.json` for a program to read.

## The first report

`tools/report.ts` prints the part of the JSON this lesson reads: the score, the five metrics behind
it, the insights that found something, and when each request finished. Save it in `tools/`:

```typescript
// tools/report.ts: the part of a Lighthouse report this course reads, out of the
// JSON it writes: the score and the five metrics behind it, the insights that
// found something, and when each request finished.
//
//   node tools/report.ts report.report.json
import { readFile } from "node:fs/promises";

const report = JSON.parse(await readFile(process.argv[2], "utf8"));
const performance = report.categories.performance;
console.log(`performance ${Math.round(performance.score * 100)}, throttling ${report.configSettings.throttlingMethod}`);
for (const ref of performance.auditRefs.filter((r: any) => r.weight > 0)) {
  console.log(`  ${ref.acronym.padEnd(4)} ${report.audits[ref.id].displayValue.padEnd(8)} weight ${ref.weight}`);
}
// An insight scores 1 when it found nothing; anything less is worth reading.
for (const audit of Object.values<any>(report.audits)) {
  if (audit.id.endsWith("-insight") && audit.score !== null && audit.score < 1) {
    console.log(`  insight: ${audit.title}${audit.displayValue ? `, ${audit.displayValue}` : ""}`);
  }
}
// A data: address is part of the page, not a request to anybody, so only http ones are listed.
for (const r of report.audits["network-requests"].details.items.filter((r: any) => r.url.startsWith("http"))) {
  console.log(`  request ${new URL(r.url).pathname.padEnd(28)} done at ${String(Math.round(r.networkEndTime)).padStart(5)} ms, ${r.transferSize} B`);
}
```

With `server.ts` running as lesson 5 left it, run Lighthouse on the course page and read the report:

```
ana@dev:~/planner$ npm run lighthouse -- http://localhost:3000/courses/git >/dev/null && node tools/report.ts report.report.json
performance 100, throttling simulate
  FCP  1.1 s    weight 10
  LCP  1.1 s    weight 25
  TBT  0 ms     weight 30
  CLS  0        weight 25
  SI   1.1 s    weight 10
  insight: Use efficient cache lifetimes, Est savings of 18 KiB
  insight: Network dependency tree
  insight: Render-blocking requests, Est savings of 150 ms
  request /courses/git                 done at    20 ms, 1802 B
  request /assets/index-C9VFYfGa.js    done at    46 ms, 17819 B
  request /assets/index-CGM1waBA.css   done at    45 ms, 538 B
  request /favicon.svg                 done at    79 ms, 9695 B
```

**A hundred, and three insights anyway.** A perfect score and a list of things to look at are not a
contradiction: the score grades five metrics on a simulated phone, and an insight reports something
that could cost time on some other page, network or visit. The next section is how the hundred was
reached; the section "What the report still says" comes back to the three insights.

Open `report.report.html` in your browser too. It is the same report, laid out as Chrome's developer
tools show it, with every insight expanded into the requests and elements it is about.
