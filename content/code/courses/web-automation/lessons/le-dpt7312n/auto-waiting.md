---
title: Waiting without being told to
version: 1
---

A test written for a page that changes under it would seem to need a pause before every step:
wait for the button, then click, then wait for the total, then check it. **Playwright tests in
this course have no pauses and no sleeps**, and they pass. Two mechanisms do the waiting, one
before every action and one inside every assertion, and both give up after a fixed time. This
section names them and measures the times; lesson 13 is about waits in depth, and lesson 3 about
the asynchronous loading that makes them necessary.

## Before an action: actionability

Before `click()` presses anything, Playwright finds the element the locator describes and checks,
in its documentation's words, that it is **visible**, **stable** (not moving in an animation),
**receives events** (no other element covers it) and is **enabled**. A `fill()` also needs it to be
**editable**. If any check fails, it looks again, and again, until they all pass or time runs out.
A button that appears half a second after the page loads is clicked half a second later, and the
test says nothing about it.

That is also why a locator is a description rather than an element. `page.getByRole('button')`
finds nothing when it is written; it is resolved each time it is used, against the page as it is
at that moment.

## After an action: an assertion that retries

The shop's **Add to basket** sends a request and redraws the count when the answer arrives.
`click()` returns once the click is delivered, not once the request has finished. This test reads
the count both ways. Save it as `tests/waiting.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a read is a snapshot, an assertion retries', async ({ page }) => {
  await page.goto('/');
  const count = page.getByTestId('basket-count');
  await page.getByTestId('product-mango').getByRole('button', { name: 'Add to basket' }).click();
  console.log(`read straight after the click: ${await count.textContent()}`);
  await expect(count).toHaveText('1');
});
```

```
%%CAP waiting%%
```

`textContent()` read the count at once and got `0`: **a read is a snapshot**, taken the instant it
runs, before the shop's answer had come back. `expect(count).toHaveText('1')` passed on the same
page, because an assertion on a locator is a **web-first assertion**: it reads, compares, and reads
again until the text matches. A test that checked the snapshot with `expect(text).toBe('1')` would
fail here on most runs and pass on a few, which is the flaky test lesson 14 is about.

## How long is "until"

Neither mechanism waits for ever, and the defaults are worth knowing from a run rather than from
memory. To see them, add these two tests to the end of `tests/waiting.spec.js`, run the file, and
take them out again. Each waits for something that never happens:

```javascript
test('an assertion that is never true', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByTestId('basket-count')).toHaveText('1');
});

test('a click on a button that is not there', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: 'Buy now' }).click();
});
```

```
%%CAP waiting-fail%%
```

The two failures report two different clocks:

- **an assertion gives up after @@EXPECT@@**, and the message says so, `Timeout: @@EXPECT@@`, with a
  call log showing how many times it looked and what it found each time;
- **an action has no clock of its own.** The click waited for a button called *Buy now* until the
  whole test ran out of time, `Test timeout of @@TEST@@ exceeded`, and the duration beside the test
  name shows it.

Both can be changed: `expect.timeout` and `timeout` in the configuration, `actionTimeout` under
`use`, or a `{ timeout }` on a single call. Changing them is lesson 13's subject. What matters here
is reading the failure: a call log that says the locator **resolved** and held the wrong value is a
page that did something unexpected; a call log that only ever says **waiting for** is a locator
that matches nothing, which is usually the test's fault.
