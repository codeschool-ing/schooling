---
title: A page object
version: 1
---

**A page object is a class that stands for one page of the application, and it is the only code
in the suite that knows how that page is built.** Tests talk to it in the customer's words:
*open*, *add a banana*, *the basket's count*. It answers by finding the elements, clicking them
and handing back what the test needs to check. When the markup changes, the page object changes
and the tests do not. Martin Fowler's description of the pattern puts it as a rule: the page
object should let a test do and see anything a person can, through an interface that does not
mention the HTML.

The common first idea is that a page object is a place to store selectors: a file of constants,
`BANANA_BUTTON = '[data-testid=product-banana] button'`, imported by every test. That moves the
strings and keeps the problem. The tests still say *click this button*, so they still read like
the markup, and a step that takes three actions is still written out three times. **What the
page object holds is behaviour, and the locators come with it.**

## The class

Playwright needs nothing special for this: a page object is a plain JavaScript class that keeps
the `page` it is given. Make a folder `pages` beside `tests`, so the runner does not mistake the
class for a test file. Save it as `pages/shop-page.js`:

```schooling-example
{"language": "javascript", "file": "pages/shop-page.js", "parts": [{"code": "// The shop's one page, as a test sees it: what a customer can do on it,\n// and what it shows them. Every locator for the page is written here.\nexport class ShopPage {\n  constructor(page) {\n    this.page = page;\n  }\n", "note": "A plain class. It is handed the `page` the test was given and keeps it; it starts no browser and opens nothing of its own. The comment says the one rule the file exists for."}, {"code": "  async open() {\n    await this.page.goto('/');\n  }\n", "note": "The address lives here now. A test says *open the shop* and never mentions where the shop is."}, {"code": "  async addToBasket(product) {\n    const card = this.page.getByTestId(`product-${product}`);\n    await card.getByRole('button', { name: 'Add to basket' }).click();\n  }\n", "note": "The method is named for what the customer does, not for the button. The card's test id and the button's name are written once, here, for every product."}, {"code": "  basketCount() {\n    return this.page.getByTestId('basket-count');\n  }\n\n  basketTotal() {\n    return this.page.locator('.basket-total');\n  }\n}", "note": "These two hand back a **locator**, not the text in it, so the test can put a web-first assertion on it. Section 05 of this lesson is about why that matters."}]}
```

**A locator costs nothing to build.** Lesson 10 showed that `getByTestId(...)` finds nothing when
it is written; it is a description, resolved each time it is used. So a page object can create
its locators as often as it likes, and every one of them looks at the page as it is when the
test uses it, not as it was when the object was made.

## The tests, on top of it

The same three tests, now speaking to the page object. Save it as `tests/page-object.spec.js`:

```javascript
import { test, expect } from '@playwright/test';
import { ShopPage } from '../pages/shop-page.js';

test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a banana goes into the basket', async ({ page }) => {
  const shop = new ShopPage(page);
  await shop.open();
  await shop.addToBasket('banana');
  await expect(shop.basketCount()).toHaveText('1');
});

test('two fruit make two items', async ({ page }) => {
  const shop = new ShopPage(page);
  await shop.open();
  await shop.addToBasket('banana');
  await expect(shop.basketCount()).toHaveText('1');
  await shop.addToBasket('mango');
  await expect(shop.basketCount()).toHaveText('2');
});

test('the total follows the price', async ({ page }) => {
  const shop = new ShopPage(page);
  await shop.open();
  await shop.addToBasket('papaya');
  await expect(shop.basketTotal()).toHaveText('R$ 7,90');
});
```

```
%%CAP po%%
```

Read the second test aloud again: *open the shop, add a banana, the count is 1, add a mango, the
count is 2*. That is the test case a person would have written in `manual-testing`, and a reader
can judge whether it is the right case without knowing a single test id. The assertions stayed
in the test, and the reason is two sections on.

## The same change, again

The button becomes *Add to cart*, and the suite fails exactly as before:

```
%%CAP po-cart%%
```

**Look where the failures point.** All three stack traces run through `pages/shop-page.js`, line
14, the one line that names the button; the test file only says which step was in progress. The
repair is one edit, in the one place that knows:

```
%%CAP po-cart-fixed%%
```

Before, the rename cost four edits in three tests; now it costs one, and it will still cost one
when there are thirty tests. If you made the change yourself, put both files back the same way
with `sed`, swapping the two names.

The failure itself did not go away, and should not. **A page object makes a markup change cheap
to repair; it does not make it invisible.** The suite still went red when the button was renamed,
and somebody still had to decide whether the new text was intended. What changed is that the
decision ends in one line instead of a search through the suite.
