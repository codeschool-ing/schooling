---
title: Comparing screenshots, briefly
version: 1
---

Every screenshot so far was evidence, taken after a failure to explain it. Playwright can also use
a screenshot as the **check itself**: take a picture of the page, compare it with a picture saved
earlier, and fail when they differ. The idea is attractive because one assertion covers everything
the page draws, colours and spacing included, which no `toHaveText` reaches. **It is also the
check most likely to fail for a reason that is not a defect**, and this section shows both halves.

## The baseline is written by the first run

`expect(page).toHaveScreenshot(name)` compares the page with a stored picture called the
**baseline**. There is none the first time, so the first run writes one and fails. Save it as
`evidence/visual.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// Fails once, on purpose: the first run has no picture to compare with,
// so it writes one and fails. Every run after compares against it.
test('the shop looks as it did', async ({ page, request }) => {
  await request.post('/api/reset');
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(8);
  await expect(page).toHaveScreenshot('shop.png');
});
```

The test empties the basket first, because the header shows the basket's count and total, and a
picture of a basket another test filled is a different picture. It waits for the eight cards for
the same reason: a picture of the list before it filled would be a baseline of nothing.

```
%%CAP visual-first%%
```

```
%%CAP visual-second%%
```

The baseline went beside the test, in `evidence/visual.spec.js-snapshots/`, under the name
`shop-linux.png`: Playwright added the operating system to the name, and it adds the project's
name too when the configuration has projects. The second run compared and passed. The baseline is
a file of the project, and it belongs in version control with the test, because a baseline that
lives on one machine is a test that passes on one machine.

## A change it catches

Now one colour in `app/public/style.css` changes: the border of each card, from `#c9d6c3` to the
shop's dark green, `#2f6f4e`. Nothing a `toHaveText` reads has moved. The same test:

```
%%CAP visual-changed%%
```

**4794 pixels differ**: the borders of eight cards. That is about half a percent of the 921,600
pixels in a 1280 by 720 picture, which the message rounds to a ratio of 0.01. The failure left
three pictures beside the usual evidence: `shop-expected.png`, the baseline; `shop-actual.png`,
what the page drew this time; and `shop-diff.png`, which marks where they differ. The call log
also shows Playwright taking the screenshot twice, 100 ms apart, and comparing only once two
screenshots in a row agreed with each other, so that a page still moving does not fail on its
movement.

This run is what the check is for: a change no text assertion could see, caught by one line. The
style is put back afterwards, as with every change this course makes to the shop.

## Why the picture on another machine differs

Text is drawn by the operating system's fonts. The shop asks for `system-ui`, which is a different
typeface on Ubuntu, on Windows and on macOS, and even two Linux machines with different fonts
installed draw the same word a pixel wider or narrower. Anti-aliasing, the soft edge around each
letter, differs between graphics drivers too. **A baseline written on your laptop compared on a
build server can fail on every line of text** without one thing wrong with the page. That is why
the file name carries `linux`: Playwright keeps one baseline per platform rather than pretend they
agree.

Three things make the check usable, and each has a price:

- **Compare where the baseline was made.** Teams run visual tests only inside one container image,
  so the fonts are always the same ones; the price is that a run on a laptop means running the
  container.
- **Tolerate a little.** `toHaveScreenshot` accepts `maxDiffPixels` or `maxDiffPixelRatio`, and a
  `threshold` for how different one pixel's colour may be before it counts; the price is that a
  change smaller than the tolerance passes.
- **Hide what changes by itself.** The option `mask` takes locators and paints over them, for a
  clock, a random banner, an advertisement; the price is that nothing under the mask is checked.

When a change is intended, `npx playwright test --update-snapshots` writes new baselines, and a
person has to look at them before they are committed: an update run accepts whatever the page
draws, defects included. Whether a visual test earns that upkeep, against the defects it would
catch, is the kind of judgement lesson 22 is about. Here it is enough to know that the check
exists and what its failures usually mean.
