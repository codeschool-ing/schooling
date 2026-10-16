---
title: Where a simulated browser earns its place
version: 1
---

The case for a simulated browser has always been speed, and the case was made when starting a
real one took seconds and a display. **Measure it before believing it.** The same check, open the
home page and wait for the eight cards, ten times in jsdom and ten times in Chromium. Chromium is
launched once and each page gets a fresh tab, which is how a Playwright worker runs a file. Save it
as `simulated/timing.mjs`:

```javascript
// The same check, ten times in each: open /, wait for eight cards.
import { chromium } from '@playwright/test';
import { address, open, until } from './shop.mjs';

const runs = 10;
const ms = (start) => Math.round(performance.now() - start);

let start = performance.now();
for (let i = 0; i < runs; i++) {
  const window = await open('/');
  await until(() => window.document.querySelectorAll('#products li').length === 8);
  window.close();
}
console.log(`jsdom:    ${runs} pages in ${ms(start)} ms`);

start = performance.now();
const browser = await chromium.launch();
console.log(`chromium: launched in ${ms(start)} ms`);
start = performance.now();
for (let i = 0; i < runs; i++) {
  const page = await browser.newPage();
  await page.goto(address + '/');
  await page.locator('#products li').nth(7).waitFor();
  await page.close();
}
console.log(`chromium: ${runs} pages in ${ms(start)} ms`);
await browser.close();
```

```
%%CAP timing%%
```

%%CAP-PROSE timing%%

## Where it fits

**Checking HTML that the server sends complete.** Lesson 6's `/ssr` arrives with every card in it,
and lesson 6 checked that with Playwright's `request` fixture and `toContain`, a test on the text
of the response. jsdom adds one thing to that: a parsed tree to ask with selectors, so the test can
say *this card has this heading and this button* instead of *this string occurs somewhere*. No
script needs to run, so neither option of the last two sections is set, and none of the gaps of
the last section is crossed. Node's own runner is enough to run it. Save it as
`simulated/ssr.test.mjs`:

```javascript
// Server-rendered HTML, checked with no browser and no scripts at all.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';

const address = 'http://localhost:3000';

test('every product the API lists is a card in the HTML of /ssr', async () => {
  const products = await (await fetch(address + '/api/products')).json();
  const { document } = (await JSDOM.fromURL(address + '/ssr')).window;
  for (const product of products) {
    const card = document.querySelector(`[data-testid=product-${product.id}]`);
    assert.ok(card, `no card for ${product.id}`);
    assert.equal(card.querySelector('h2').textContent, product.name);
    assert.equal(card.querySelector('button').dataset.id, product.id);
  }
});

test('the HTML of / has an empty list, for app.js to fill', async () => {
  const { document } = (await JSDOM.fromURL(address + '/')).window;
  assert.equal(document.querySelectorAll('#products li').length, 0);
});
```

It lives outside `tests/` on purpose, so that `npx playwright test` does not try to run it. With
the shop running, `node --test` runs it; `--test-reporter=tap` prints plain text rather than
symbols:

```
%%CAP ssr-test%%
```

**Testing code that reads and writes the DOM, without a page around it.** A function that builds a
card from a product, or formats the basket line, can be called in Jest's `jsdom` environment
thousands of times a minute. That is a unit test, and lesson 11 put Jest there. The shop's
`app.js` is not written to be imported, so this course cannot show one against it; a project whose
front-end code is split into modules can.

## Where it does not

Everything in the last section's table. If the question is whether a person can see, reach, read
or use something, or whether it works in the browser they have, the only instrument is a real
browser. A simulated one answers those questions with zeros and passes.

**Put it where it belongs in the suite.** Lesson 21 draws the testing pyramid: many cheap tests at
the bottom, few expensive ones at the top, and `testing-cicd` lesson 1 the layers a pipeline runs.
A jsdom test sits low: faster than a browser test and, as the timing showed, by less than its
reputation, and blind to everything above the DOM. A browser test sits at the top and is the only
one that sees the page a customer sees. The expensive mistake is the one in between: asking the
cheap layer a question only the top one can answer, and counting its green as evidence.
