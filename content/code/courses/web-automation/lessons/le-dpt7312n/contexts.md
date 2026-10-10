---
title: Contexts, and two shoppers in one browser
version: 1
---

Starting a browser costs time: a process, its memory, a second or so before it answers. The
obvious way to keep tests apart would be a new browser for each, and the obvious way to save the
time would be to share one and let tests clean up after each other. **Playwright does neither.**
It starts one browser per worker and gives every test a **browser context**, which is a fresh
profile inside that browser: its own cookies, its own `localStorage`, its own cache, as if a
different person had opened a private window.

The nesting is three levels deep. A **browser** holds contexts; a **context** holds pages; a
**page** is one tab. Pages in the same context share everything a profile keeps, like two tabs of
your own browser. Pages in different contexts share nothing, and creating a context takes
milliseconds, which is why there can be one per test.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"One browser holds two contexts. Ana's context has two pages and Bia's has one; each context has its own cookies, storage and cache. Both send requests to the same shop, which keeps one basket for everybody.\"><rect x=\"20\" y=\"20\" width=\"440\" height=\"250\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"36\" y=\"44\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">one browser, launched once</text><rect x=\"40\" y=\"60\" width=\"190\" height=\"190\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"135\" y=\"82\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Ana's context</text><rect x=\"55\" y=\"96\" width=\"160\" height=\"30\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"135\" y=\"116\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a page</text><rect x=\"55\" y=\"136\" width=\"160\" height=\"30\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"135\" y=\"156\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a second page</text><text x=\"135\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">its own</text><text x=\"135\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cookies, storage,</text><text x=\"135\" y=\"228\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cache</text><rect x=\"250\" y=\"60\" width=\"190\" height=\"190\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"345\" y=\"82\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Bia's context</text><rect x=\"265\" y=\"96\" width=\"160\" height=\"30\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"345\" y=\"116\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a page</text><text x=\"345\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">its own</text><text x=\"345\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cookies, storage,</text><text x=\"345\" y=\"228\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cache</text><rect x=\"540\" y=\"90\" width=\"160\" height=\"120\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"620\" y=\"116\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the shop</text><text x=\"620\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/api/basket</text><text x=\"620\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">one basket</text><text x=\"620\" y=\"186\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">for everybody</text><path d=\"M430 120 L536 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M536 120 L527 115 L527 125 Z\" fill=\"var(--phosphor)\"></path><path d=\"M430 170 L536 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M536 170 L527 165 L527 175 Z\" fill=\"var(--phosphor)\"></path><text x=\"498\" y=\"108\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Ana adds</text><text x=\"498\" y=\"158\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Bia reads</text></svg>", "caption": "A context separates everything the browser keeps. The shop's basket is kept by the server, and no context reaches it."}
```

## Two shoppers in one test

The `page` every test so far received was made from a context Playwright created for that test.
A test can also ask for the `browser` itself and make as many contexts as it needs, which is how
one test plays two people. This file does it four times: two contexts that share nothing, two
shoppers in the shop, and a pair of tests showing that the ordinary `page` is isolated too. Save it
as `tests/contexts.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// Every test starts from an empty basket.
test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('two contexts share nothing in the browser', async ({ browser }) => {
  const ana = await browser.newContext();
  const bia = await browser.newContext();
  const anaPage = await ana.newPage();
  const biaPage = await bia.newPage();
  await anaPage.goto('/');
  await biaPage.goto('/');

  const shopper = () => localStorage.getItem('shopper');
  await anaPage.evaluate(() => localStorage.setItem('shopper', 'ana'));
  console.log(`Ana's page reads ${await anaPage.evaluate(shopper)}`);
  console.log(`Bia's page reads ${await biaPage.evaluate(shopper)}`);
  expect(await biaPage.evaluate(shopper)).toBeNull();

  // A second page in Ana's context is her second tab: same storage.
  const anaTab = await ana.newPage();
  await anaTab.goto('/');
  expect(await anaTab.evaluate(shopper)).toBe('ana');

  await ana.close();
  await bia.close();
});

test('two shoppers, one basket: the shop\'s flaw', async ({ browser }) => {
  const ana = await browser.newContext();
  const bia = await browser.newContext();
  const anaPage = await ana.newPage();
  const biaPage = await bia.newPage();
  const add = (page, id) =>
    page.getByTestId(`product-${id}`).getByRole('button', { name: 'Add to basket' }).click();

  await anaPage.goto('/');
  await add(anaPage, 'banana');
  await expect(anaPage.getByTestId('basket-count')).toHaveText('1');

  await biaPage.goto('/');
  console.log(`cookies: Ana ${JSON.stringify(await ana.cookies())}, Bia ${JSON.stringify(await bia.cookies())}`);
  // Bia has added nothing, and her basket already holds Ana's banana.
  await expect(biaPage.getByTestId('basket-count')).toHaveText('1');

  await add(biaPage, 'mango');
  await anaPage.reload();
  await expect(anaPage.getByTestId('basket-count')).toHaveText('2');
  console.log(`Ana's total after Bia's mango: ${await anaPage.locator('.basket-total').textContent()}`);

  await ana.close();
  await bia.close();
});

test('the page fixture: storage written in one test…', async ({ page }) => {
  await page.goto('/');
  await page.evaluate(() => localStorage.setItem('shopper', 'ana'));
  expect(await page.evaluate(() => localStorage.getItem('shopper'))).toBe('ana');
});

test('…is gone in the next, in the same browser', async ({ page }) => {
  await page.goto('/');
  expect(await page.evaluate(() => localStorage.getItem('shopper'))).toBeNull();
});
```

The `request` in `beforeEach` is a fixture that sends HTTP requests with no page at all, and it
empties the basket through `POST /api/reset` before each test. Contexts made with
`browser.newContext()` take `baseURL` and the other `use` settings from the configuration, so
`goto('/')` works in them as it does in `page`.

```
%%CAP contexts%%
```

## What the run says

The first test is the isolation you were promised. Ana's page wrote `shopper` into
`localStorage` and reads it back; Bia's page, the same shop in the same browser, reads `null`. A
second page in Ana's context reads `ana`, because it is her second tab.

The second test is **the shop's flaw, shown by the tool that hides nothing**. Bia's context is
fresh. It has no cookies, and the line printed in the middle shows that neither shopper has any:
the shop never sets one, so it has nothing to tell two people apart by. Bia opens the shop having
added nothing, and her basket says `1`, because the banana is Ana's and **the basket lives on the
server, as one list for everybody**. Bia adds a mango, Ana reloads, and Ana's total is now
@@TOTAL@@. A context isolates what the browser keeps. It cannot isolate what the server keeps, and no
setting in Playwright can.

Read the test as what it is: a description of the shop as it behaves today. If a later version
gave each visitor a basket of their own, the expectation of `1` on Bia's page would fail, and that
failure would be good news. Lesson 15 is about test data and isolation on the server's side, and it
starts from this flaw.

The last two tests use the plain `page`. The first writes `shopper` and reads it back; the next
runs **in the same worker and the same browser**, a moment later, and finds nothing, because its
`page` belongs to a context made for it alone. That is the default, and it is why the order of
tests in a file does not matter to what the browser remembers.

## Where isolation ends

Each worker has its own browser, and each test its own context, so nothing in the browser leaks
between tests. **Everything outside the browser still does.** The basket, a database, a file the
server writes, an e-mail it sends: two tests running at once in two workers share all of them, as
the two contexts above shared the basket. Inside one file, tests run one after another by default,
which is why this file's resets do not trip over each other. Run the whole suite with several
workers and the shop's one basket becomes one basket for every test at once; lesson 19 is about
running in parallel, and it meets that head on.

One context per test is also the reason a test that needs a signed-in user has to sign in again,
or load a saved state: the cookies of the last test went with its context. Playwright's
`storageState` saves a context's cookies and storage to a file and starts a new context from it.
The shop has no sign-in, so it is not shown here.
