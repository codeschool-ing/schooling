---
title: Testing the cache on purpose
version: 1
---

A cache can be tested two ways, and a suite wants both. **The promise** is the header the server
sends: cheap to check, exact, and the cause of everything else. **The consequence** is what a
returning customer sees: slower, and the only proof that the promise does what you think.

## The promise, without a browser

The `request` fixture sends HTTP requests from the test itself, with no browser and **no cache of
any kind**, so it sees exactly what the server says every time. `response.headers()` returns the
headers with their names in lower case. A page can read them too, through the response
`page.waitForResponse` returns, but a page's responses may come out of its cache, which is the very
thing in doubt; `request` asks the server.

## A test that expects to fail

The returning-customer test from the last section is correct: it describes what the shop should do.
The shop does not do it yet, and deleting the test would throw the finding away. **`test.fail()`**
says exactly that: this test is expected to fail, and here is why. The run counts it as passed while
it fails, and reports it as a failure **the day it passes**, which is the day somebody fixed the
flaw and the mark has to go. A test switched off with `test.skip()` would say nothing on that day.

## The whole file

The final version keeps the first test, marks the returning customer, and adds three: the offer's
header, marked the same way; a static file's header and its `304`, which the shop gets right; and
the returning customer once more, with routing switched on, which the next section explains. Save it
as `tests/cache.spec.js`:


```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a new offer reaches the page', async ({ page, request }) => {
  await request.post('/api/offer', { data: { id: 'banana', price: 290 } });
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Banana');
});

test('a returning customer sees the new offer', async ({ page, request }) => {
  test.fail(true, 'known flaw: GET /api/offer may be kept for ten minutes');
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Mango');
  await request.post('/api/offer', { data: { id: 'banana', price: 290 } });
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Banana');
});

test('the offer is checked with the server before it is reused', async ({ request }) => {
  test.fail(true, 'known flaw: GET /api/offer may be kept for ten minutes');
  const response = await request.get('/api/offer');
  expect(response.headers()['cache-control']).toMatch(/no-cache|no-store/);
});

test('a static file is reused only when the server agrees', async ({ request }) => {
  const first = await request.get('/style.css');
  expect(first.headers()['cache-control']).toBe('no-cache');
  const etag = first.headers()['etag'];
  expect(etag).toBeTruthy();

  const again = await request.get('/style.css', { headers: { 'If-None-Match': etag } });
  expect(again.status()).toBe(304);
});

// The returning customer again, with routing switched on. It passes, and
// that is the warning: routing turns the browser's cache off.
test('routing hides the flaw', async ({ page, request }) => {
  await page.route('**/*', (route) => route.continue());
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Mango');
  await request.post('/api/offer', { data: { id: 'banana', price: 290 } });
  await page.goto('/offer.html');
  await expect(page.locator('#offer')).toContainText('Banana');
});
```

Start the shop in one terminal with its log on, and run the file from another; Playwright finds the
shop already listening and uses it:

```
ana@laptop:~/quitanda$ npx playwright test tests/cache.spec.js

Running 5 tests using 1 worker

  ✓  1 tests/cache.spec.js:7:1 › a new offer reaches the page (251ms)
  ✘  2 tests/cache.spec.js:13:1 › a returning customer sees the new offer (5.2s)
  ✘  3 tests/cache.spec.js:22:1 › the offer is checked with the server before it is reused (14ms)
  ✓  4 tests/cache.spec.js:28:1 › a static file is reused only when the server agrees (20ms)
  ✓  5 tests/cache.spec.js:40:1 › routing hides the flaw (221ms)

  5 passed (7.0s)
```

**Two crosses, and five passed.** The `✘` marks the two tests that failed, and the count says
passed because both failed as they were marked to. Read the cross as *the flaw is still there*.

The shop's terminal shows what each test did. The first two `GET /api/products` are Playwright
checking that the shop is up; after that, each test begins with its `POST /api/reset`:

```
ana@laptop:~/quitanda$ QUITANDA_LOG=1 npm start

> start
> node app/server.js

quitanda is listening on http://localhost:3000
GET /api/products 200
GET /api/products 200
POST /api/reset 200
POST /api/offer 200
GET /offer.html 200
GET /style.css 200
GET /api/offer 200
POST /api/reset 200
GET /offer.html 200
GET /style.css 200
GET /api/offer 200
POST /api/offer 200
GET /offer.html 304
GET /style.css 304
POST /api/reset 200
GET /api/offer 200
POST /api/reset 200
GET /style.css 200
GET /style.css 304
POST /api/reset 200
GET /offer.html 200
GET /style.css 200
GET /api/offer 200
POST /api/offer 200
GET /offer.html 200
GET /style.css 200
GET /api/offer 200
```

- **the returning customer**, the second block, asked for the page and the stylesheet again and got
  `304` for both, and **never asked for the offer a second time**. That is the flaw, in the
  server's own words;
- **the header tests** asked for `/api/offer` once, and for `style.css` twice: the second time with
  the fingerprint, answered `304`;
- **the routing test**, the last block, asked for everything again on its second visit, all `200`,
  with no `304` among them: with routing on, the browser did not
  even send the conditional request a kept copy would have caused.

## The day the flaw is fixed

To see what the marks do, imagine somebody changes `max-age=600` to `no-cache` in
`app/routes/offer.js` and restarts the shop. This run was made with that change, then put back:

```
ana@laptop:~/quitanda$ npx playwright test tests/cache.spec.js

Running 5 tests using 1 worker

  ✓  1 tests/cache.spec.js:7:1 › a new offer reaches the page (195ms)
  ✓  2 tests/cache.spec.js:13:1 › a returning customer sees the new offer (177ms)
  ✓  3 tests/cache.spec.js:22:1 › the offer is checked with the server before it is reused (46ms)
  ✓  4 tests/cache.spec.js:28:1 › a static file is reused only when the server agrees (65ms)
  ✓  5 tests/cache.spec.js:40:1 › routing hides the flaw (231ms)


  1) tests/cache.spec.js:13:1 › a returning customer sees the new offer ────────────────────────────

    Expected to fail, but passed.

  2) tests/cache.spec.js:22:1 › the offer is checked with the server before it is reused ───────────

    Expected to fail, but passed.

  2 failed
    tests/cache.spec.js:13:1 › a returning customer sees the new offer ─────────────────────────────
    tests/cache.spec.js:22:1 › the offer is checked with the server before it is reused ────────────
  3 passed (3.8s)
```

Every test drew a tick, and two of them are reported as failures anyway, each with the same line:
**`Expected to fail, but passed.`** That is the run telling whoever fixed the flaw to take the
`test.fail` lines out, after which the file describes a shop with no flaw in it.
