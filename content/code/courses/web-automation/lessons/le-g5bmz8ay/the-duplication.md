---
title: Three tests, one markup change
version: 1
---

A test of a web page knows two kinds of thing. It knows **what a customer does**: opens the shop,
adds a banana, expects the basket to say 1. And it knows **where things are on the page**: the
banana is the element with the test id `product-banana`, its button is called *Add to basket*,
the count is in `basket-count`. The first kind changes when the shop's behaviour changes. The
second changes whenever somebody edits the markup, which is far more often. A suite that writes
both kinds into every test pays for every markup edit once per test.

## Three tests, written the obvious way

These three are what a suite looks like after a week of honest work. Each one empties the basket,
opens the shop, finds a card by its test id and the button inside it by its role and name, which
lesson 2 argued are the locators that last, and checks the header. Save it as
`tests/page-object.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a banana goes into the basket', async ({ page }) => {
  await page.goto('/');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
});

test('two fruit make two items', async ({ page }) => {
  await page.goto('/');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
  await page.getByTestId('product-mango').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toHaveText('2');
});

test('the total follows the price', async ({ page }) => {
  await page.goto('/');
  await page.getByTestId('product-papaya').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.locator('.basket-total')).toHaveText('R$ 7,90');
});
```

Every run in this lesson that adds to the basket carries `--workers 1`. **The shop keeps one
basket for everybody**, and Playwright's documentation says that test files run in parallel by
default while the tests inside one file run in order in one worker. Run this file beside another
that adds fruit and the two would count each other's bananas. Lesson 15 is about that flaw; here
the flag keeps every transcript about one thing at a time.

```
%%CAP dup%%
```

## The change

Now the shop's owner decides the button should say *Add to cart*. It is a one-word edit to
`app/public/app.js`, the shop still works, and a customer would not notice anything had broken.
Make the edit with `sed`, run the same three tests, and put the word back:

```
%%CAP dup-cart%%
```

**Three failures, one cause, and a minute and a half to find out.** Each test waited for a button
called *Add to basket* until the whole test ran out of time: an action has no clock of its own,
as lesson 10 measured, so each one spent the full 30 seconds. The call log says *waiting for*
and nothing else, which lesson 10 also taught you to read as a locator that matches nothing.

Nothing in the shop was wrong. **The tests failed because each of them held its own copy of a
fact about the markup**, and the fact changed. Count the copies in the file: the button's locator
is written four times across three tests, the count's three times, the address three times. To
repair the suite you edit four lines in three places, and the next suite of thirty tests has
forty. Somebody will miss one, and the test they missed fails next week for a reason that looks
new.

The duplication has a second cost that shows before anything breaks. Read the second test aloud:
it says *get by test id product banana, get by role button named Add to basket, click*. That
is how the page is built, not what the customer did. **A test that reads like a list of selectors
hides its own purpose**, and the reader who must decide whether a failure matters has to translate
it back first.

`manual-testing` lesson 10 covers regression suites and why they grow. The rest of this lesson is
one answer to what growth does to the code of an automated one.
