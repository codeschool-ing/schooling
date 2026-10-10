---
title: The address nobody can open
version: 1
---

A SPA's addresses exist only inside its script. `/spa/basket` is a key in the `pages` object of
`spa.js`, and the server has never heard of it. Clicking **Basket** works because the click never
reaches the server. **Reloading the page does**, and so does pasting the address into a new tab,
following a bookmark or opening a link somebody sent: each one asks the server for `/spa/basket`
as a document, and the server answers what it answers for any file it does not have.

The belief this breaks is that an address that works once works always. It is also the defect
that a click-through, by hand or by robot, is built to miss: every test so far starts at `/spa/`
and clicks.

## The 404

Lesson 1's `look.mjs` takes an address as its argument. Given this one, with the shop started:

```
ana@laptop:~/quitanda$ node look.mjs http://localhost:3000/spa/basket
   12 ms  404 GET /spa/basket  (document)
   13 ms  console.error: Failed to load resource: the server responded with a status of 404 (Not Found)
```

**One line, a 404 for the document**, and nothing after it: no stylesheet, no script, because the
page that would have named them never arrived. In a browser you see the shop's plain `not found`
and nothing else, which the browser also reports in its console. It is a known flaw, on purpose,
and the `catch` in `serveFile` in `app/server.js` is where it comes from: the server looks for a
file called `basket` in `app/public/spa/`, finds none, and says so.

## A test that knows about the defect

The test to write is the one for the behaviour you want: open `/spa/basket` directly, expect a 200
and the basket. Today it fails, and there are two honest ways to keep it in the suite.

- **Assert the defect as current behaviour**: expect the 404. The suite is green, and the test is
  a record of what the app does. The day a developer fixes the server, that test fails with a
  message that reads exactly like a regression, and somebody has to work out that the red is good
  news.
- **Write the test for the right behaviour and mark it with `test.fail()`**, which tells Playwright
  that the test is expected to fail. The suite stays green while it does. The day it passes,
  Playwright reports it as a failure, *expected to fail, but passed*, which is the prompt to remove
  the mark.

This lesson takes the second. The test says what the app should do, so it never needs rewriting,
and the mark is one line with the reason in it, easy to find with a search. Its weakness is real:
**`test.fail()` is satisfied by any failure**, so a test that broke for an unrelated reason, a
renamed heading or a server that did not start, would pass too. Keep such a test short, and make
its first check the symptom itself, the status. Save it as `tests/spa.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('Basket opens the basket without loading a page', async ({ page }) => {
  await page.goto('/spa/');
  await expect(page.getByRole('heading', { name: 'Fruit' })).toBeVisible();
  const documents = [];
  page.on('request', (request) => {
    if (request.resourceType() === 'document') documents.push(request.url());
  });

  await page.getByRole('link', { name: 'Basket' }).click();
  await page.waitForURL('**/spa/basket');
  await expect(page.getByRole('heading', { name: 'Basket' })).toBeVisible();
  await expect(page.locator('#view')).toHaveAttribute('aria-busy', 'false');
  expect(documents).toEqual([]);
});

test('Basket opens the basket on a slow network', async ({ page }) => {
  await page.route('**/api/basket', async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 500));
    await route.continue();
  });
  await page.goto('/spa/');
  await expect(page.getByRole('heading', { name: 'Fruit' })).toBeVisible();
  await page.getByRole('link', { name: 'Basket' }).click();
  await page.waitForURL('**/spa/basket');
  await expect(page.getByRole('heading', { name: 'Basket' })).toBeVisible();
});

test('the basket opens from its own address', async ({ page }) => {
  test.fail(true, 'known defect: the server has no fallback for /spa/basket');
  const response = await page.goto('/spa/basket');
  expect(response.status()).toBe(200);
  await expect(page.getByRole('heading', { name: 'Basket' })).toBeVisible();
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/spa.spec.js

Running 3 tests using 1 worker

  ✓  1 tests/spa.spec.js:3:1 › Basket opens the basket without loading a page (204ms)
  ✓  2 tests/spa.spec.js:18:1 › Basket opens the basket on a slow network (1.0s)
  ✘  3 tests/spa.spec.js:30:1 › the basket opens from its own address (107ms)

  3 passed (2.8s)
```

Three tests, and the summary says `3 passed`, although the third line carries a `✘`. The cross
is the truth about the test: it failed. The summary counts it as passed because it failed as
declared. Read both, because a run that says `3 passed` can still carry a known defect, and the
mark is where the suite says which.

## The fix is the server's

The remedy is a rule on the server, usually called a **fallback**: an address under the app's path
that is not a file is answered with the app's `index.html`, and the script, reading
`location.pathname`, draws the right view. Every web server and static host has a way to say it,
and which one applies depends on where the app is deployed. It is the developer's change to make,
and the tester's part is the test above and a defect report that names the steps: open the
address directly, see the 404. `manual-testing` lesson 15 is about that report.

To watch the mark do its job, a route can stand in for the fix. The file below answers
`/spa/basket` with the app's page, which is the smallest fallback that makes the test pass. It is not
part of your project: save it in `app/routes/` as `spa-fallback.js` for one run, and delete it
afterwards:

```javascript
// Not part of quitanda: the developer's fix, for one run.
import fs from 'node:fs/promises';
import path from 'node:path';

const page = path.join(import.meta.dirname, '..', 'public', 'spa', 'index.html');

export const routes = [{
  method: 'GET', path: '/spa/basket',
  handle: async ({ res }) => {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(await fs.readFile(page));
  },
}];
```

```
ana@laptop:~/quitanda$ npx playwright test tests/spa.spec.js

Running 3 tests using 1 worker

  ✓  1 tests/spa.spec.js:3:1 › Basket opens the basket without loading a page (191ms)
  ✓  2 tests/spa.spec.js:18:1 › Basket opens the basket on a slow network (1.0s)
  ✓  3 tests/spa.spec.js:30:1 › the basket opens from its own address (101ms)


  1) tests/spa.spec.js:30:1 › the basket opens from its own address ────────────────────────────────

    Expected to fail, but passed.

  1 failed
    tests/spa.spec.js:30:1 › the basket opens from its own address ─────────────────────────────────
  2 passed (2.5s)
```

With the fallback in place, the third test passes, its line gets a tick, and the run fails:
`Expected to fail, but passed.`, with `1 failed` in the summary. That red is the message the mark
exists to send: the defect is fixed, so delete the `test.fail` line. With the route file deleted
again, the shop is back to its 404.

A real fallback answers **every** unknown address under `/spa/`, and that has a consequence of its
own: `/spa/nonsense` then answers 200, and the only thing that says *not found* is the app's own
view, the `Not found` heading at the bottom of `show()`. A suite for an app with a fallback checks
that view as well, because the status code can no longer say it.
