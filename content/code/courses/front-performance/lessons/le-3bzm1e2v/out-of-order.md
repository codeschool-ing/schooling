---
title: What the browser does with the pieces
version: 1
---

**The browser drew the first piece without waiting for the second.** That is what makes streaming
worth having, and it is easy to check: `tools/appear.ts` opens a page in Chromium and records when
each piece of text it is told about first appeared on the screen. Save it in `tools/`:

```typescript
// tools/appear.ts: open a page in Chromium and say when each piece of text
// first appeared on the screen, in milliseconds after the request.
//
//   node tools/appear.ts URL TEXT...   [--no-js]
import { chromium } from "playwright";

const args = process.argv.slice(2);
const js = !args.includes("--no-js");
const [url, ...texts] = args.filter((a) => a !== "--no-js");
const browser = await chromium.launch();
const page = await browser.newPage({ javaScriptEnabled: js });
await page.addInitScript((wanted: string[]) => {
  const seen: Record<string, number> = {};
  (window as any).seen = seen;
  const check = () => {
    for (const t of wanted) if (!(t in seen) && document.body?.innerText.includes(t)) seen[t] = Math.round(performance.now());
  };
  new MutationObserver(check).observe(document, { childList: true, subtree: true, characterData: true });
}, texts);
await page.goto(url, { waitUntil: "load" });
await page.waitForTimeout(300);
const seen = js ? await page.evaluate(() => (window as any).seen) : {};
for (const t of texts) console.log(`${js ? (t in seen ? `${String(seen[t]).padStart(5)} ms` : "  never ") : "     -  "}  ${t}`);
if (!js) console.log((await page.locator("body").innerText()).trim());
await browser.close();
```

It watches with a `MutationObserver`, the browser's own notice that the document changed, so it sees
text as the parser adds it, before the page has finished loading. With `--no-js` it cannot run its
watcher, and prints the text of the page at the end instead.

```
ana@dev:~/planner$ node tools/appear.ts http://localhost:3005/courses/git Git "Loading sessions" 2026-10-24
   19 ms  Git
   19 ms  Loading sessions
 1010 ms  2026-10-24
ana@dev:~/planner$ node tools/appear.ts http://localhost:3005/courses/git Git "Loading sessions" 2026-10-24 --no-js
     -    Git
     -    Loading sessions
     -    2026-10-24
All courses

Git
Loading sessions…
```

**The heading and the placeholder were on the screen a second before the sessions.** A page that
waited for its slowest query would have shown nothing for that second.

## Out of order

The sessions arrived last, but they are not at the end of the page: they belong in the middle, in the
list. The server could not send them in their place, because the HTML after them, the end of the
list and of `<main>`, had already gone. So it sent them **out of order**, at the end of the response,
inside a `<template>` the browser parses and does not show, and a line of script moved them where
they belong. React's streaming does the same with more care: a hidden element per boundary and a
small function that swaps each one in, which is the `<div hidden id="S:0">` you will see Next.js send
in the section after next.

**The swap is JavaScript, and without JavaScript it never happens**: the placeholder stays, and the
sessions sit in a template nobody shows. The second run, with JavaScript off, shows exactly that.
Streaming in order, where each piece is sent in its place as soon as everything before it is ready,
works without any script, and it is what a server does when the slow part is at the end of the page.
