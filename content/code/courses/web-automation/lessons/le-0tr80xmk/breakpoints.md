---
title: Breakpoints, tested on both sides of the line
version: 1
---

A **responsive** page is one page for every visitor. The server sends the same HTML to a phone and
to a desktop, and the stylesheet changes the layout at certain widths called **breakpoints**. The
shop has one. The block at the bottom of the `style.css` lesson 1 built starts with
`@media (max-width: 600px)`, and inside it three rules: `.menu-toggle { display: inline-block; … }`
shows the **Menu** button, `nav { display: none; … }` hides the links, and `nav.open { display:
flex; }` brings them back once the button has been pressed. The script in `app.js` does the
pressing: it flips the button's `aria-expanded` between `false` and `true` and the `open` class on
the `<nav>` with it.

## Where to test: either side of each line

The common habit is to test "mobile" and "desktop", one phone-sized window and one large one.
That checks two layouts and not the line between them, which is where this kind of defect lives:
a rule written with `min-width` where `max-width` was meant, a breakpoint at 600 in one file and 640
in another, a layout that holds at 390 and falls apart at 560. **The widths worth testing are
read off the stylesheet**, and each breakpoint gets the width on each side of it.

`max-width: 600px` means *600 or narrower*, so 600 is still the phone layout and 601 is the first
desktop one. A window of 360 and one of 1280 add the two ends. Four widths, two layouts, and the
tests ask a different question of each layout:

- **at 360 and 600**, the links are hidden, the Menu button is there with `aria-expanded="false"`,
  and pressing it shows the links and sets `aria-expanded="true"`;
- **at 601 and 1280**, the links are visible and the Menu button is not.

## One file, one describe block per width

`test.use` inside a `test.describe` sets options for every test in that block, and `viewport` is
one of them: Playwright opens each test's page in a context of that size. A loop writes the block
once per width. Save it as `tests/responsive.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// style.css changes the layout at (max-width: 600px): 600 is still a
// phone, 601 is not. Each side gets the width next to the line and one
// far from it.
for (const width of [360, 600]) {
  test.describe(`${width} px wide`, () => {
    test.use({ viewport: { width, height: 800 } });

    test('the links hide behind the Menu button', async ({ page }) => {
      await page.goto('/');
      const menu = page.getByRole('button', { name: 'Menu' });
      const shop = page.getByRole('link', { name: 'Shop', includeHidden: true });
      await expect(menu).toHaveAttribute('aria-expanded', 'false');
      await expect(shop).toBeHidden();
      await menu.click();
      await expect(menu).toHaveAttribute('aria-expanded', 'true');
      await expect(shop).toBeVisible();
    });
  });
}

for (const width of [601, 1280]) {
  test.describe(`${width} px wide`, () => {
    test.use({ viewport: { width, height: 800 } });

    test('the links show and the Menu button does not', async ({ page }) => {
      await page.goto('/');
      const menu = page.getByRole('button', { name: 'Menu', includeHidden: true });
      await expect(page.getByRole('link', { name: 'Shop' })).toBeVisible();
      await expect(menu).toHaveCount(1);
      await expect(menu).toBeHidden();
    });
  });
}
```

```
ana@laptop:~/quitanda$ npx playwright test tests/responsive.spec.js

Running 4 tests using 1 worker

  ✓  1 tests/responsive.spec.js:10:5 › 360 px wide › the links hide behind the Menu button (213ms)
  ✓  2 tests/responsive.spec.js:10:5 › 600 px wide › the links hide behind the Menu button (161ms)
  ✓  3 tests/responsive.spec.js:27:5 › 601 px wide › the links show and the Menu button does not (121ms)
  ✓  4 tests/responsive.spec.js:27:5 › 1280 px wide › the links show and the Menu button does not (107ms)

  4 passed (2.0s)
```

**Four passed**, and the titles say which width each one ran at, because the `describe` block is
named after it. The width in a title is what makes a failure readable: *601 px wide › the links
show* tells you where to look before you open anything.

## A hidden element that does not exist

Two details in that file guard against a test that passes for the wrong reason. `getByRole`
leaves out elements that are hidden, which is right for finding what a person can use and wrong
for proving that something is hidden: a locator that matches nothing is hidden too, so
`toBeHidden()` passes on a button that was renamed or deleted. **`includeHidden: true`** makes the
locator find the element whether or not it shows, and on the wide side **`toHaveCount(1)`** proves
the Menu button is in the page before `toBeHidden()` says it is not on screen. On the narrow side
the click does the same job: the test cannot press a button that is not there, and the link it
then sees is the one it said was hidden.

## `test.use` or `setViewportSize`

`page.setViewportSize({ width, height })` resizes a page that is already open, in the middle of a
test. Use it for the question *what happens when the window changes*, such as a tablet turned on
its side with the menu open. `test.use` decides the size before the page exists, which is the
question *what does this width get*. For a test that sets the size once and then opens the page,
the two do the same job, and the next section uses the other one.
Both change only the window. A phone's touch, pixel ratio and name stay those of a desktop
Chromium, and for this page that is enough, because nothing in `style.css` asks about anything
but width.
