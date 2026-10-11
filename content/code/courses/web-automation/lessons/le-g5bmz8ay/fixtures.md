---
title: Handing every test its page object
version: 1
---

Every test in `tests/page-object.spec.js` still starts with the same three lines: empty the
basket, make a `ShopPage`, open it. **That is setup, and Playwright has a place for setup that is
better than a line at the top of each test: a fixture.** You have used fixtures since lesson 1,
because `page` and `request` are both fixtures: a test names them in its first argument and the
runner builds them before the test and cleans up after it. `test.extend` adds fixtures of your
own to that list.

A `beforeEach` could hold the three lines too, and lesson 10's files do something like it. Its
limits show when the suite grows: it runs for every test in the file whether the test needs the
shop or not, it shares its result through a variable outside the test, and a second file has to
copy it. A fixture is declared once, imported where it is wanted, and built only for a test that
asks for it by name. Playwright's documentation says exactly that: fixtures are set up on demand,
and a test that does not name one does not pay for it.

## The fixture

A fixture is an `async` function. It receives the fixtures it depends on, builds its value, and
passes the value to `use`; the test runs while `use` is waiting, and anything written after it is
the cleanup, which runs when the test ends. Keep the file in `tests` beside the specs: its name
does not end in `.spec.js`, so the runner does not take it for a test file. Save it as
`tests/fixtures.js`:

```javascript
import { test as base, expect } from '@playwright/test';
import { ShopPage } from '../pages/shop-page.js';

// A test that asks for `shop` gets an empty basket and the shop open on it.
export const test = base.extend({
  shop: async ({ page, request }, use) => {
    await request.post('/api/reset');
    const shop = new ShopPage(page);
    await shop.open();
    await use(shop);
  },
});

export { expect };
```

The `shop` fixture depends on two built-in ones, `page` and `request`, and Playwright builds those
first. There is nothing to clean up here, because the runner already closes the page; the reset
happens *before* each test rather than after, so a test always starts from a basket it knows,
even when the test before it crashed halfway.

## The tests, asking for it

The spec imports `test` and `expect` from the fixtures file instead of from `@playwright/test`,
and names `shop` where it used to name `page`. Save it as `tests/page-object.spec.js`:

```javascript
import { test, expect } from './fixtures.js';

test('a banana goes into the basket', async ({ shop }) => {
  await shop.addToBasket('banana');
  await expect(shop.basketCount()).toHaveText('1');
});

test('two fruit make two items', async ({ shop }) => {
  await shop.addToBasket('banana');
  await expect(shop.basketCount()).toHaveText('1');
  await shop.addToBasket('mango');
  await expect(shop.basketCount()).toHaveText('2');
});

test('the total follows the price', async ({ shop }) => {
  await shop.addToBasket('papaya');
  await expect(shop.basketTotal()).toHaveText('R$ 7,90');
});
```

```
%%CAP fixtures%%
```

**Each test is now only the case itself**: what the customer did and what they should see. Compare
the second test with its version in section 02: the opening is the fixture's now, and not one of the
four lines left names an element, a role or an address. The card tests still import from `@playwright/test`
and ask for `page`, so the `shop` fixture never ran for them: no reset, no extra page load.

## What a fixture is not for

A fixture prepares the **world** a test starts in: data, a signed-in user, an open page. It is not
a place for the test's steps. A fixture called `shopWithBananaInBasket` looks convenient and hides
the step the test is about inside a name. The test then reads *given a basket with a banana,
expect 1*, and the one action it exists to check has moved out of sight. If a step is the subject
of the test, it belongs in the test. Lesson 15 is about the data side of that world: isolation, and
cleaning up after a test.
