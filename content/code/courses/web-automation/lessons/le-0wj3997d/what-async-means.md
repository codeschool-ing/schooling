---
title: The page has loaded, and the data has not
version: 1
---

**A page that has loaded is not a page that has finished.** The browser says a page has loaded
when the document and the files it names, its stylesheets, scripts and images, have arrived. A
request a script makes after that is not part of the count, and on a great many pages the content
a test cares about comes from exactly such a request. The word for it,
*Ajax*, is older than the `fetch` function that makes the request now. It means only this: the
page asks the server for data **asynchronously**, without leaving the page and without the
browser waiting for the answer before it calls the page ready.

The shop's home page from lesson 1 is the first instance. Its HTML arrives with an empty list;
`app.js` runs, calls `fetch('/api/products')`, and fills the list when the answer comes. Lesson 1
showed the order in the Network panel: the document, then the script, then the request for
products, last. Between the document and that answer, the page is on screen and empty.

## Where a test looks

The usual first belief is that `page.goto()` waits for *the page*, so that once it returns,
everything is there. It waits for the browser's **`load` event**, by default, and nothing more.
Whether the products are in the list at that moment depends on which finished first: the `load`
event or the request for products. Nothing in the page decides that. Timing does.

This program makes the race visible. It prints when the `load` event fires, when each request to
`/api/` is answered, how many products the list holds the moment `goto` returns, and how many once
a product has appeared. One call, `page.route`, lets it hold the answer for products back by a
number of milliseconds you give it, which stands in for a slower server or a slower network.
Save it as `at-load.mjs`:

```javascript
// When the home page counts as loaded, and when its products arrive.
// Run it with the shop started: node at-load.mjs [ms to hold the products back]
import { chromium } from '@playwright/test';

const hold = Number(process.argv[2] ?? 0);
const browser = await chromium.launch();
const page = await browser.newPage();
const start = Date.now();
const log = (text) => console.log(String(Date.now() - start).padStart(5) + ' ms  ' + text);

// Holding the answer back stands in for a slower server or network.
await page.route('**/api/products', async (route) => {
  await new Promise((resolve) => setTimeout(resolve, hold));
  await route.continue();
});
page.on('load', () => log('the load event'));
page.on('response', (response) => {
  const path = new URL(response.url()).pathname;
  if (path.startsWith('/api/')) log(`answered ${path}`);
});

const products = page.locator('#products li');
await page.goto('http://localhost:3000/');
log(`goto returned: ${await products.count()} products`);
await products.first().waitFor();
log(`one appeared: ${await products.count()} products`);
await browser.close();
```

With the shop started, run it as it is, and then holding the products back for half a second:

```
%%CAP at-load%%
```

On this machine the shop answers in a few milliseconds, so in the first run the products arrived
around the same moment as the `load` event, and the list was full when `goto` returned. **That
is luck, of a reliable kind.** In the second run nothing in the page changed, only the speed of
one answer, and `goto` returned to a list with **0** products. A test that counted them at that
moment would have failed on a page with nothing wrong with it.

## The two ways out

There are two ways to stop the speed of the server from deciding a test.

The first is to **wait for a length of time**: half a second, two seconds, whatever made it pass
on the day it was written. It turns *usually fast enough* into *usually slow enough*, and it fails
the first time the answer takes longer than the guess, on a busy build server, for instance.

The second is to **wait for the state the test needs**. `at-load.mjs` does that before its last line:
`products.first().waitFor()` returns as soon as a product exists, whether that takes four
milliseconds or four hundred. The smoke test from lesson 1 does the same thing in a shorter form.
`expect(page.locator('#products li')).toHaveCount(8)` does not count once; it counts again and
again until the answer is 8 or the time allowed runs out, so a slow answer makes it slower and
not wrong.

The rest of this lesson is about a page where waiting for a state is not enough on its own,
because the page passes through the right state on its way to a wrong one.
