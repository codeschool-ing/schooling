---
title: The page that scrolls sideways
version: 1
---

On a phone, a page is meant to scroll in one direction: down. **A page wider than the window
scrolls sideways as well**, and whatever sits off to the right is out of sight until somebody
thinks to drag the page across, which most people never do. It is the commonest way a responsive
layout breaks, and the cheapest one for a robot to find: two numbers, compared.

## The flaw in the shop

Lesson 1's stylesheet carries a line marked as a known flaw, and this lesson is the one it was
waiting for:

```css
/* A known flaw, on purpose: this line refuses to wrap. */
.basket { margin: 0 0 0 auto; white-space: nowrap; min-width: 24rem; text-align: right; }
```

`white-space: nowrap` keeps *Basket: 0 items · R$ 0,00* on one line whatever happens, and
`min-width: 24rem` makes the paragraph at least 384 CSS pixels wide, at the browser's usual 16
pixels to a rem. Add the header's padding of 1rem on the left and the line needs 400 pixels. In a
desktop window nobody notices. In a window 360 wide, the page grows by 40 pixels to the right.

## The check

A page's full width is `document.documentElement.scrollWidth`. If it is larger than the window,
the page scrolls sideways. The test sets the width, waits for the eight cards so that it measures
the finished page rather than the empty one lesson 1 described, and compares. It goes in the same
file as the breakpoints, below them. Save it as `tests/responsive.spec.js`:

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

// Nothing may be wider than the window. Compared with the width the test
// asked for, because a phone widens its own window to fit the page.
for (const width of [360, 390, 768]) {
  test(`nothing scrolls sideways at ${width} px`, async ({ page }) => {
    await page.setViewportSize({ width, height: 800 });
    await page.goto('/');
    await expect(page.locator('#products li')).toHaveCount(8);
    const scrollWidth = await page.evaluate(() => document.documentElement.scrollWidth);
    expect(scrollWidth, 'the page is wider than the window').toBeLessThanOrEqual(width);
  });
}
```

The three widths are a small phone, the iPhone 13 of the last two sections, and a tablet held
upright. Run it:

```
%%CAP overflow-fail%%
```

**400 at 360, and 400 at 390.** The same number twice is itself a finding: the page is 400 wide
whatever the window, so something in it has a fixed minimum, which points straight at
`min-width`. At 768 there is room, and it passes.

**Compare with the width the test asked for, never with `innerWidth`.** The `viewport` section
measured it: under the iPhone 13 descriptor the shop reported a window of 400 inside a screen of
390, because a phone honouring the viewport tag widens its window to fit the page. A check written
as `scrollWidth <= innerWidth` would compare 400 with 400 under that descriptor and pass on the
exact page this test exists to catch.

## Why this check is worth more than the others

Most of what makes a responsive layout good is a matter of looking: whether a column is too
narrow, whether the spacing is pleasant. A sideways scroll has **one right answer, a number, at
every width**, and it catches a whole family of causes with one test: a fixed width, a long word or
address that does not break, a wide table, an image without a maximum width. Lesson 1's flaw is
one line. The same test would find any of the others without knowing which it was looking for.

## What to leave in the file

The test has found a real defect, and the defect is not yours to fix in a test. Somebody reports it
(`manual-testing` lesson 15 is about what the report needs); until it is fixed, the file has to
say something. There are three choices, and two are worse than they look:

- **Skip the two widths.** The suite goes green and stops measuring: if the basket grows another
  hundred pixels, or if somebody fixes it, nothing tells you.
- **Assert the defect**, `expect(scrollWidth).toBe(400)`. The suite goes green and now calls the
  defect correct. A font change that makes it 401 fails a test about nothing, and the fix fails
  too, as a regression.
- **Mark the widths as expected to fail**, with `test.fail(condition, description)`. The check
  still runs on every width. Playwright reports an expected failure as a pass, and **fails the test
  the day it passes**, which is the day somebody fixed the CSS and the mark has to come off.

The third keeps the test honest in both directions, and it writes the defect into the file where
the next reader meets it. The file as it stays. Save it as `tests/responsive.spec.js`:

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

// Nothing may be wider than the window. Compared with the width the test
// asked for, because a phone widens its own window to fit the page.
// A known defect, reported and not fixed yet: .basket in style.css does
// not wrap and is 24rem wide, so these widths are expected to fail. The
// day one of them passes, Playwright fails it, and this list shrinks.
const overflows = [360, 390];

for (const width of [360, 390, 768]) {
  test(`nothing scrolls sideways at ${width} px`, async ({ page }) => {
    test.fail(overflows.includes(width), 'known defect: .basket is wider than a phone');
    await page.setViewportSize({ width, height: 800 });
    await page.goto('/');
    await expect(page.locator('#products li')).toHaveCount(8);
    const scrollWidth = await page.evaluate(() => document.documentElement.scrollWidth);
    expect(scrollWidth, 'the page is wider than the window').toBeLessThanOrEqual(width);
  });
}
```

```
%%CAP overflow-known%%
```

Seven passed, and the list still draws the two known failures with a cross, so they stay visible
in every run. Here is the same file the day the two declarations in `.basket` are deleted:

```
%%CAP overflow-fixed%%
```

**Expected to fail, but passed.** The suite is red until somebody removes 360 and 390 from
`overflows`, which is the moment the fix gets noticed and the test goes back to guarding the line.
`test.fail` is for a failure you understand and expect on every run. A test that fails only
sometimes is lesson 14's subject, and this mark is the wrong tool for it.
