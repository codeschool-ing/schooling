---
title: Components inside the page
version: 1
---

**A page object for a whole page grows into a long file, and most of its length is the same part
described again and again.** The shop draws eight product cards with identical markup, and a
basket line in its header. A real application repeats far more: a header on every page, a
product card on the home page, in search results and in a basket. Describing a card inside
`ShopPage` means describing it again in the next page object that shows one. The answer is to
give each repeated part a small object of its own, a **component object**, and build page objects
out of them.

A component object is built from a **root locator**: the element that contains the part. Every
locator inside it starts from that root, so the same class describes any card it is given and
cannot reach outside it. This is lesson 2's chaining, `getByTestId('product-mango').getByRole(...)`,
turned into a class.

## The two parts

The card. Save it as `pages/product-card.js`:

```javascript
// One product card. It is built from the card's own locator, so one class
// serves every card, on any page that draws one.
export class ProductCard {
  constructor(root) {
    this.name = root.getByRole('heading');
    this.price = root.locator('.price');
    this.addButton = root.getByRole('button', { name: 'Add to basket' });
  }

  async add() {
    await this.addButton.click();
  }
}
```

The basket line in the header. It only shows, so it has no methods: two locators, built from
whatever root it is handed. Save it as `pages/basket-summary.js`:

```javascript
// The basket line in the header: how many items, and what they cost.
export class BasketSummary {
  constructor(root) {
    this.count = root.getByTestId('basket-count');
    this.total = root.locator('.basket-total');
  }
}
```

## The page, made of them

`ShopPage` now holds a `BasketSummary` built from the page's `header`, and makes a `ProductCard`
for whichever product a test names. Its four methods keep the names they had, so the tests do not
change. Save it as `pages/shop-page.js`:

```javascript
import { ProductCard } from './product-card.js';
import { BasketSummary } from './basket-summary.js';

// The shop's one page, made of the parts it draws.
export class ShopPage {
  constructor(page) {
    this.page = page;
    this.basket = new BasketSummary(page.locator('header'));
  }

  async open() {
    await this.page.goto('/');
  }

  product(id) {
    return new ProductCard(this.page.getByTestId(`product-${id}`));
  }

  async addToBasket(id) {
    await this.product(id).add();
  }

  basketCount() {
    return this.basket.count;
  }

  basketTotal() {
    return this.basket.total;
  }
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 385\" role=\"img\" aria-label=\"Five layers, top to bottom. The test says await shop.addToBasket('banana'). The page object ShopPage offers open, addToBasket, basketCount and basketTotal. It is made of two components, ProductCard, one class for eight cards, and BasketSummary, in the header. Each component holds locators, getByRole button with a name, and getByTestId basket-count, and the locators find elements in the DOM, an li with the test id product-banana and a span with the test id basket-count. A markup change lands at the bottom and stops at the locators row.\"><text x=\"20\" y=\"48\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the test</text><text x=\"20\" y=\"118\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">page object</text><text x=\"20\" y=\"188\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">components</text><text x=\"20\" y=\"258\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">locators</text><text x=\"20\" y=\"328\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the DOM</text><rect x=\"180\" y=\"20\" width=\"520\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"440\" y=\"48\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">await shop.addToBasket('banana')</text><path d=\"M440 66 L440 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M440 88 L435 79 L445 79 Z\" fill=\"var(--phosphor)\"></path><rect x=\"180\" y=\"90\" width=\"520\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"440\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">ShopPage</text><text x=\"440\" y=\"128\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">open() · addToBasket(id) · basketCount() · basketTotal()</text><path d=\"M310 136 L310 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M310 158 L305 149 L315 149 Z\" fill=\"var(--phosphor)\"></path><path d=\"M570 136 L570 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M570 158 L565 149 L575 149 Z\" fill=\"var(--phosphor)\"></path><rect x=\"180\" y=\"160\" width=\"260\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"310\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">ProductCard</text><text x=\"310\" y=\"198\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one class, eight cards</text><rect x=\"460\" y=\"160\" width=\"240\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"580\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">BasketSummary</text><text x=\"580\" y=\"198\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">in the header</text><path d=\"M310 206 L310 228\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M310 228 L305 219 L315 219 Z\" fill=\"var(--phosphor)\"></path><path d=\"M580 206 L580 228\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M580 228 L575 219 L585 219 Z\" fill=\"var(--phosphor)\"></path><rect x=\"180\" y=\"230\" width=\"260\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"310\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">getByRole('button', { name })</text><rect x=\"460\" y=\"230\" width=\"240\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"580\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">getByTestId('basket-count')</text><path d=\"M310 276 L310 298\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M310 298 L305 289 L315 289 Z\" fill=\"var(--phosphor)\"></path><path d=\"M580 276 L580 298\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M580 298 L575 289 L585 289 Z\" fill=\"var(--phosphor)\"></path><rect x=\"180\" y=\"300\" width=\"260\" height=\"46\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--amber)\"></rect><text x=\"310\" y=\"328\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&lt;li data-testid=\"product-banana\"&gt;</text><rect x=\"460\" y=\"300\" width=\"240\" height=\"46\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--amber)\"></rect><text x=\"580\" y=\"328\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&lt;span data-testid=\"basket-count\"&gt;</text><text x=\"440\" y=\"372\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a markup change lands at the bottom and stops at the locators row</text></svg>", "caption": "Each layer knows only the one below it. The test never sees a locator, and only the locators see the HTML."}
```

**This is composition: the page has a basket and has cards.** The other road, which most suites
take first, is inheritance: a `BasePage` with the header in it, and every page object `extends
BasePage`. It works until a page has no header, or has two kinds of card, or a part appears on
some pages and not others. Then the base class collects methods that only some of its children
can honestly offer, and every page object inherits all of them. A part held as a field is present
where the page has it and absent where it does not, and `ShopPage` says in its constructor
exactly what it is made of.

## One component, two pages

Lesson 6 built `/ssr`, the same shop rendered on the server. Its cards have the same markup as
the home page's, and it has no header: its count sits in a plain paragraph, with no total. So `ProductCard` should work there unchanged,
and `BasketSummary` has no business there at all. This file checks the first claim on both pages,
and adds nothing to the basket, which matters on `/ssr`, where a click before its script arrives
does nothing. Save it as `tests/page-object-card.spec.js`:

```javascript
import { test, expect } from '@playwright/test';
import { ProductCard } from '../pages/product-card.js';

// The same component on two pages: the shop, and the one lesson 6 renders
// on the server. Only the card is shared; nothing here adds to the basket.
for (const address of ['/', '/ssr']) {
  test(`the guava card on ${address}`, async ({ page }) => {
    await page.goto(address);
    const guava = new ProductCard(page.getByTestId('product-guava'));
    await expect(guava.name).toHaveText('Guava');
    await expect(guava.price).toContainText('R$ 12,90');
  });
}
```

Run it with the page-object tests, whose file is the one from the previous section, untouched:

```
%%CAP components%%
```

Five passed. **The three basket tests ran against a page object whose inside was rewritten**, and
they could not tell. The two card tests ran one class on two pages built by different code, one
drawn by a script in the browser and one sent whole by the server. `toContainText` is there
because the home page writes the unit after the price, *R$ 12,90 / kg*, and `/ssr` does not.
