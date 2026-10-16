---
title: From Puppeteer to Playwright, line by line
version: 1
---

Playwright was started at Microsoft by engineers who had built Puppeteer at Google, and the two
libraries still look alike: `launch()`, `newPage()`, `goto()` and `click()` are in both. **The family
resemblance makes the differences easy to read**: each one is a lesson the authors
took from Puppeteer, and most of them are about waiting.

Here is the same check as a Playwright test: empty the basket, open the shop, add a banana, and
expect the count to say 1. Save it as `tests/banana.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('a banana goes into the basket', async ({ page, request }) => {
  await request.post('/api/reset');
  await page.goto('/');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/banana.spec.js

Running 1 test using 1 worker

  ✓  1 tests/banana.spec.js:3:1 › a banana goes into the basket (264ms)

  1 passed (1.6s)
```

Four lines inside the test, and not one wait written by hand. Side by side:

| the step | Puppeteer | Playwright Test |
|---|---|---|
| start a browser | `puppeteer.launch()` and `browser.newPage()` | the `page` fixture: the runner starts one and closes it |
| empty the basket | Node's `fetch`, with the whole address | the `request` fixture, with `baseURL` from the configuration |
| find the button | a CSS string, `[data-testid=product-banana] button` | a **locator**: the card by its test id, then the button by its role and name |
| wait for it | `waitForSelector`, written by you | built into `click()`: it waits until the button is there, visible, enabled and still |
| check the count | `waitForFunction` in the page, then `$eval` to read it | `expect(...).toHaveText('1')`, which retries until it matches or times out |
| report | `console.log`, read by a person | a test name, ✓ or ✘, and the runner's summary |

**What changed is where the waiting lives.** In Puppeteer a script that forgets a wait still
runs, and as the last section showed, gives whatever answer the race gave it. In Playwright the
action waits for the element before acting, and an assertion that starts with `expect(locator)`
keeps asking until the page agrees or the timeout runs out; Playwright's documentation calls
these **web-first assertions**. The removal you made by hand in the last section has no equivalent here: there is
no line to delete.

**Locators are the second change.** A Puppeteer selector is a string the page is searched with
once. A Playwright locator is a description, *the button called Add to basket inside the banana
card*, searched for again every time it is used, so it survives the page redrawing the card. It
also prefers what a person sees, a role and a name, over the page's structure; lesson 2 is about
why that holds up better.

**And the runner is the third.** The fixtures, the parallel workers, the retries and the report
all come from Playwright Test. Puppeteer leaves each of those to whatever runner you put around it.

**Puppeteer has moved too**, and the comparison would be unfair without saying so. The version you
installed has `page.locator()`, whose documentation says an action on it is retried
until the element is ready and checks the conditions a click needs. In this script it would
replace the `waitForSelector` line and the click with one line. What it still does not have is an
assertion that waits, or a runner. Puppeteer stays a library; Playwright became a framework.

`tests/banana.spec.js` resets the shared basket, so it can disturb another test that is using the
basket at the same moment. That is the shop's unmarked flaw from lesson 1, and lessons 15 and 19
deal with it.
