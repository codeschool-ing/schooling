---
title: Drawn is not the same as working
version: 1
---

The HTML from `/ssr` draws eight cards, each with an **Add to basket** button. They are real
`<button>` elements, visible and enabled, and **they do nothing** until a script gives each one a
click handler. Frameworks that render on the server call that step **hydration**: the HTML arrives
dry, and a script that comes after it makes it respond. The shop does it by hand, in the file the
server sends from `/slow/ssr.js`. Save it as `app/public/ssr.js`:

```javascript
// Until this file has run, the buttons on /ssr are drawn and do nothing.
for (const button of document.querySelectorAll('button[data-id]')) {
  button.addEventListener('click', async () => {
    const response = await fetch('/api/basket', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: button.dataset.id }),
    });
    const basket = await response.json();
    const count = basket.lines.reduce((n, line) => n + line.qty, 0);
    document.querySelector('[data-testid=basket-count]').textContent = count;
  });
}
document.body.dataset.ready = 'true';
```

Its last line sets `data-ready="true"` on the `<body>`, after every button has its handler. The
next section has a use for it.

## The gap, measured

`look.mjs` from lesson 1 prints every response a page receives, with the milliseconds since it
asked for the page. The home page first:

```
%%CAP look-csr%%
```

Then `/ssr`, with its address as the argument:

```
%%CAP look-ssr%%
```

On `/`, the products arrive at TIME_PRODUCTS ms in a request of their own, and until then the list is
empty. On `/ssr` they came with the document at TIME_DOC ms, and the script that makes the buttons work
arrived at TIME_SCRIPT ms. **For about a second and a half the page shows eight buttons that ignore
every click.**

FIGURE

## A test that clicks at once

The obvious test opens the page, clicks Banana's button and checks that the basket says 1. The
`beforeEach` empties the basket first through the shop's reset, because the basket is one list
shared by everybody and an earlier test may have filled it; lesson 15 is about that. Save it as
`tests/ssr.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// The basket is shared, so every test starts by emptying it.
test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a click on /ssr adds to the basket', async ({ page }) => {
  await page.goto('/ssr');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
});
```

```
%%CAP click-at-once%%
```

**The click succeeded and the basket stayed at 0.** Playwright did not object to the click itself.
Before clicking, it checks that the element is visible, stable, enabled and not covered by
anything else, which its documentation calls **actionability checks**, and the button passed all
of them. It then waited the five seconds an assertion waits by default for the text to become `1`,
and gave up. No check on the button could have caught this, because a button with no handler and a
button with one look exactly alike from outside.

## Several runs, in case it varies

A timing problem often passes some of the time, so before deciding what to do about one, find out
which kind you have. `--repeat-each` runs the test that many times, `--workers 1` runs the copies
one after another, and `grep` keeps the lines that say how each run ended. The copies run in
parallel by default, and in parallel they would share the shop's one basket, so one copy's click
could show up in another copy's count; that is lesson 15's subject, and here it would only muddy
the answer:

```
%%CAP click-repeat%%
```

Five failures out of five. `page.goto` returns when the page's `load` event has fired, and only
then does the inline script ask for `/slow/ssr.js`; the click lands inside the 1.5 s the server
holds it back, every time. Shorten that pause to a few milliseconds and the same test would pass
on a fast machine and fail on a loaded one, which is the shape of the flaky tests in lesson 14.
