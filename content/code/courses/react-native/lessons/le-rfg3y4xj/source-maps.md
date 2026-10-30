---
title: A release crash, read with a source map
version: 1
---

**The fourth kind of release bug is data the developer never had.** Suppose the planner's server is
redeployed with `sessions` renamed to `items`. Every development build, against the developer's own server,
still works. Every released app meets the new server. This program plays that server: it answers the app's
request for the plan with the renamed field and prints what the screen shows, the error, and the first line
of the stack that points into the app's code. Save `crash.mjs`:

```javascript
// crash.mjs: hand the planner a plan in a shape it does not expect, as a server deployed with a renamed
// field would, and print what the screen says and the first place the stack points at.
//
//   node crash.mjs URL
import { chromium } from "playwright";

const [url] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
const logged = [];
page.on("console", (m) => m.type() === "error" && logged.push(m.text()));
// "sessions" renamed to "items" on the server, and nobody told the app
await page.route("**/plan", (route) =>
  route.fulfill({ json: { courses: [], items: [] }, headers: { "access-control-allow-origin": "*" } }),
);
await page.goto(url);
console.log("screen:", await page.getByText(/^Something went wrong|^The plan could not be loaded/).innerText());
const report = logged.find((t) => t.startsWith("render failed:"));
if (report) {
  console.log("error: ", report.split("\n")[0]);
  console.log("stack: ", report.split("\n").find((l) => l.includes("/_expo/static/js/"))?.trim());
}
await browser.close();
```

`page.route` answers a request in the browser itself, before it leaves, which is how a test pretends to be
a server it does not control. Export the web build with `--source-maps`, which writes a `.map` file beside
each bundle, and serve it:

```
ana@dev:~/planner$ node crash.mjs 'http://localhost:8082/?today=2026-10-21'
screen: Something went wrong on this screen. Your sessions are safe.
error:  render failed: Cannot read properties of undefined (reading 'filter') 
stack:  at e.weekTotal (http://localhost:8082/_expo/static/js/web/index-3779a6eed14c6112750693ef8e942cf2.js:1324:820)
```

**The boundary held**: the screen says something went wrong, not nothing. The error is a `TypeError` about
`filter`, and the stack says where: line 1324, column 820, of a file that is the whole app squeezed into a
few hundred very long lines. That place means nothing to a person.

## The map back

**A source map is the table from each place in the bundle to the place in the source it came from**, which
Metro writes while it builds. Node.js can read one without any package. Save `whereis.mjs`:

```javascript
// whereis.mjs: turn a place in the minified web bundle, as a stack trace prints it, back into the
// source file, line and name, with the bundle's source map and Node's own reader for them.
//
//   node whereis.mjs DIST index-….js:LINE:COLUMN
import { readFileSync } from "node:fs";
import { SourceMap } from "node:module";

const [dist, at] = process.argv.slice(2);
const [file, line, column] = at.split(":");
const map = new SourceMap(JSON.parse(readFileSync(`${dist}/_expo/static/js/web/${file}.map`, "utf8")));
const origin = map.findOrigin(Number(line), Number(column));
console.log(`${origin.fileName}:${origin.lineNumber}:${origin.columnNumber}`, origin.name ? `(${origin.name})` : "");
```

Give it the position exactly as the stack printed it:

```
ana@dev:~/planner$ node whereis.mjs dist index-3779a6eed14c6112750693ef8e942cf2.js:1324:820
/src/planner.ts:30:30 (filter)
ana@dev:~/planner$ sed -n 30p src/planner.ts
  const week = plan.sessions.filter((s) => s.date >= monday && s.date < last);
```

**`src/planner.ts`, line 30**, `weekTotal`'s first line, filtering `plan.sessions`, which no longer exists.
A crash report from a released app is that minified position and nothing more, so **every release keeps its
source maps**, stored where the team can find them and never served to users. Crash reporters such as
Sentry take them at build time and do this lookup for every report they receive.
