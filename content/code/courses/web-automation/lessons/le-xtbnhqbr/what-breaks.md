---
title: What breaks a locator
version: 1
---

**A locator breaks when it leans on something that changes for reasons that have nothing to do
with what the test checks.** The test then fails on a page that works, somebody spends an
afternoon finding out that nothing is wrong, and the next red result is believed a little less.
Four things change that way more than anything else: values the page generates, positions,
classes that exist for styling, and long chains that need every step to hold.

## A value the page generates

The card's `id` looks like the best handle there is. It is unique on the page, a selector for it
is ten characters long, and the Elements panel shows it on the first line. Ask for the Banana card
again, then for `#card-4821`, the example lesson 1 gave, and then for any `id` that starts the
way these do:

```
%%CAP count-id%%
```

A different number from the one the previous section printed, and the old one finds nothing.
`app.js` draws it with `Math.random()` every time the page loads. Frameworks do the same thing for
their own reasons: a component library that numbers its fields, a styling tool that names classes
after a hash of their rules. **Anything a program made up while drawing the page is a value the
next drawing can make up differently.**

## A test that leans on the wrong things

Three tests of the Banana card, each by a handle somebody could reasonably pick. The first copies
the `id` from the Elements panel. The second takes the first card in the list. The third does the
same after one line of JavaScript, run inside the page, has put another card at the top of the
list: that is what the shop would look like the day a new fruit came into season. Save it as
`tests/locators.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

test('banana, by the id the Elements panel showed', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('#card-4821 h2')).toHaveText('Banana');
});

test('banana, by its position', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('#products > li:nth-child(1) h2')).toHaveText('Banana');
});

test('banana, by its position, after one more fruit', async ({ page }) => {
  await page.goto('/');
  await page.locator('#products[aria-busy="false"]').waitFor();
  // What the shop's next release might do: one more card, at the top.
  await page.locator('#products').evaluate((list) => {
    list.insertAdjacentHTML('afterbegin', '<li class="card"><h2>Jabuticaba</h2></li>');
  });
  await expect(page.locator('#products > li:nth-child(1) h2')).toHaveText('Banana');
});
```

Run that file alone, by name:

```
%%CAP breaks%%
```

**The first test never passed, not even once.** The `id` it copied was right for the page in your
browser, at the moment you looked; the run opened a fresh page, which drew a fresh number. Playwright
waited the five seconds an assertion waits by default and reported `element(s) not found`. Nothing in
that message says the shop is fine.

**The second test passed, and the third is the same locator.** On the page as it is, the first
card is the Banana. With one more card at the top, the locator still finds exactly one heading, it
is simply the wrong one, and Playwright says so: expected `Banana`, received `Jabuticaba`. Nobody
broke the Banana card. A locator by position tests the order of the list, whether or not the
order is what the test is about.

## Classes for styling, and long chains

The other two kinds do not need a demonstration to be believed. **A class like `.price` exists for
the stylesheet**, and whoever next redesigns the card can rename it, split it into two or move it
to the `small`, with no change anybody would call a defect. A test that leans on it has made the
designer's naming part of what it checks. **A long chain**, `main > ul#products > li.card > p.price`,
needs each of its steps to hold at once, so it breaks when any one of them changes, and the more
steps it has the more often that is.

## The other way to be wrong

A locator can also be wrong in the direction that does not turn anything red. `contains(., "5,90")`
in the previous section found two prices. A test that read the first of them would be checking the
Banana by the luck of the order, and the day the Cashew moved up it would check the wrong price,
and could pass. **A locator that matches more than you meant hides a defect instead of reporting
one**, which is worse than a false alarm, because nobody investigates a green run. The next
section is about a tool that refuses to guess.
