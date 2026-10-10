---
title: What to check in each, and what to leave to a person
version: 1
---

The two kinds of layout fail in different places, so they are checked in different places. **A
responsive page fails at a width; an adaptive page fails at a guess.** Most real sites are both:
an adaptive server choosing between pages that are each responsive, which means each page it can
send needs the responsive checks of its own. The deals page showed why. The phone page has no
viewport tag, so the page made for phones is the one a phone draws at 980 pixels.

## A checklist for each kind

| | responsive | adaptive |
|---|---|---|
| decided by | the window's width, in the browser | the `User-Agent`, on the server |
| where to test | either side of every breakpoint in the stylesheet | either side of the server's rule, with descriptors |
| the window alone | is the whole test | tests nothing: a narrow desktop window gets the desktop page |
| what each test asks | what shows, what hides, what the controls do | which page arrived, and that it says `Vary: User-Agent` |
| what breaks quietly | a sideways scroll, text cut off | a cache serving one page to everybody, a device the rule did not expect |

And for both, at every width a phone can have:

- **No sideways scroll.** The overflow section's test, at each width you test anything at.
- **Nothing cut off.** An element with `overflow: hidden` and a fixed width or height hides what
  does not fit, without a scroll bar. The same comparison finds it on the element rather than the
  page: its `scrollWidth` larger than its `clientWidth`.
- **Targets a finger can hit.** WCAG 2.2's success criterion 2.5.8, *Target Size (Minimum)*, at
  level AA, asks for a pointer target of at least 24 by 24 CSS pixels, or enough space around a
  smaller one, and it lists exceptions besides. Read the criterion's own text at w3.org before
  relying on one: it could not be fetched from the machine these transcripts come from, so this
  lesson quotes only the number. `non-functional-testing` lessons 12 to 15 test accessibility
  properly.
- **Both orientations**, which the next paragraph shows.

Most phones in Playwright's list have a `landscape` entry beside them, and turning a phone on its
side can carry it across a breakpoint:

```
ana@laptop:~/quitanda$ node -p "require('@playwright/test').devices['iPhone 13 landscape'].viewport"
{ width: 750, height: 342 }
```

On its side the iPhone 13 is 750 wide, so it gets the shop's desktop layout, links and no Menu
button, in a window 342 pixels high. Whether that layout still fits is a question worth a test of
its own.

## A robot that measures, and a person who judged

A test can measure every target's box. It cannot apply the criterion's spacing alternative without
the geometry of every neighbour, and a test that tried would be a second implementation of the
standard, written by somebody who has not read all of it. So the test below measures, and **what
is small was looked at by a person, who wrote down why it is acceptable**. A new small target fails
the test until somebody has looked at it too. Save it as `tests/targets.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// WCAG 2.2, success criterion 2.5.8: a target is at least 24 by 24 CSS
// pixels, or has enough space around it. The robot measures the size.
// Whether the space is enough, a person judged, and wrote down here.
const judged = {
  Shop: 'under 24 px tall, with the 1rem gap of the open menu below it',
  Search: 'under 24 px tall, with the same gap above it',
};

test('every target on a phone is 24 by 24, or was judged', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 664 });
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(8);
  await page.getByRole('button', { name: 'Menu' }).click();
  const small = [];
  for (const target of await page.locator('a:visible, button:visible').all()) {
    const box = await target.boundingBox();
    if (box.width < 24 || box.height < 24) small.push((await target.textContent()).trim());
  }
  expect(small).toEqual(Object.keys(judged));
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/targets.spec.js

Running 1 test using 1 worker

  ✓  1 tests/targets.spec.js:11:1 › every target on a phone is 24 by 24, or was judged (367ms)

  1 passed (1.6s)
```

The two links of the open menu are the only targets under 24 pixels, and the
column they sit in has `gap: 1rem` between them, which is what the person judged. Every button in the shop is above 24 in both directions. The `:visible` in the
selector keeps out what is not on screen: in a window wider than 600 the hidden Menu button has a
box of 0 by 0, and an element nobody can see is nobody's target.

## What a robot should not judge

**Whether the page looks right.** A robot can say the basket line is 400 pixels wide; it cannot say
whether the phone layout is pleasant, whether the Menu button is where a thumb expects it, or
whether a heading that wraps onto three lines reads badly. Screenshots compared against a reviewed
copy are the robot's nearest approach, and lesson 16 shows what they catch and what they cost.
Lesson 22 is about the tests that cost more than the defects they find, and a test asserting what a page looks like is often one of them.

So the split is the one this lesson has followed throughout: **the robot measures what has one
right answer** (a width, a count, a header, which page arrived) and a person looks at the rest, on
a real phone, now and then.
