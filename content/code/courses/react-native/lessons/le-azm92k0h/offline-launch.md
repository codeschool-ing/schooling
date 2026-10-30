---
title: Opening with no server
version: 1
---

**On the web, AsyncStorage is the browser's `localStorage`**, so the whole path can be run in a browser:
load the plan once, cut the server off, open the app again. Playwright can cut a page off from one
address while leaving the rest alone, which is closer to a phone that has lost the server than turning
the network off would be: the web build itself still loads. Save this as `offline.mjs`:

```javascript
// offline.mjs: open the planner three times and say what each visit shows: once with the server, once
// more in the same browser with the server cut off, and once in a fresh browser with it cut off.
//
//   node offline.mjs URL
import { chromium } from "playwright";

const [url] = process.argv.slice(2);
const browser = await chromium.launch();
const cutOff = (target) => target.route("http://localhost:8008/**", (route) => route.abort());

async function visit(context, label) {
  const page = await context.newPage();
  await page.goto(url);
  const shown = page.getByText(/^This week: |^The plan could not be loaded/);
  await shown.waitFor();
  console.log(`${label}: ${await shown.innerText()}`);
  return page;
}

const mine = await browser.newContext();
const first = await visit(mine, "with the server");
await first.waitForTimeout(1500); // the persister writes at most once a second
const stored = await first.evaluate(() => localStorage.getItem("planner-cache")?.length ?? 0);
console.log(`stored: ${stored} characters under planner-cache`);
await first.close(); // one tab at a time: SQLite on the web holds its file for the tab that opened it
await cutOff(mine);
await visit(mine, "same browser, server cut off");
const fresh = await browser.newContext();
await cutOff(fresh);
await visit(fresh, "new browser, server cut off");
await browser.close();
```

A Playwright *context* is a browser profile: its pages share storage, and a new context starts with
none, like a phone the app has just been installed on. With the server running and the web build
exported and served as in lesson 10:

```
ana@dev:~/planner$ node offline.mjs 'http://localhost:8082/?today=2026-10-21'
with the server: This week: 75 of 125 minutes done
stored: 1006 characters under planner-cache
same browser, server cut off: This week: 75 of 125 minutes done
new browser, server cut off: The plan could not be loaded: Failed to fetch
```

**Read the three visits as three phones.** The first had the server and stored the plan, about a
thousand characters of JSON. The second is the same phone with no server: the plan is there at once,
from storage, and the request that fails behind it changes nothing on screen. The third has never seen
the plan and cannot reach the server, so it says so, with lesson 10's sentence.

The second visit is also where the cache would lie if it were left alone: a plan that is a day old looks
exactly like one fetched a second ago. **The planner's answer is the `maxAge` of one day.** A screen that
showed when the plan was fetched, with `dataUpdatedAt` from the query, would be a better one, and it is a
small change you can make to the course screen.
