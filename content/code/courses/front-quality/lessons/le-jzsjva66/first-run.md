---
title: What axe finds in the planner
version: 1
---

**The planner was written in lesson 1 with nobody checking its accessibility, and lesson 3 fixed one
thing by accident.** Here is what axe makes of it now, with the dev server running:

```
ana@dev:~/planner$ node server/axe.mjs http://localhost:5173/ 'http://localhost:5173/#/course/javascript'
http://localhost:5173/: 1 rule(s) broken
  image-alt (critical): Images must have alternative text
    a[href$="#/course/html-css"] > img  Element does not have an alt attribute
    a[href$="#/course/javascript"] > img  Element does not have an alt attribute
    a[href$="#/course/git"] > img  Element does not have an alt attribute
http://localhost:5173/#/course/javascript: 1 rule(s) broken
  color-contrast (serious): Elements must meet minimum color contrast ratio thresholds
    .done  Element has insufficient color contrast of 2.32 (foreground color: #aaaaaa, background color: #ffffff, font size: 12.0pt (16px), font weight: normal). Expected contrast ratio of 4.5:1
    span  Element has insufficient color contrast of 2.32 (foreground color: #aaaaaa, background color: #ffffff, font size: 12.0pt (16px), font weight: normal). Expected contrast ratio of 4.5:1
```

**Two rules, five elements.** Read each line as axe wrote it:

- **`image-alt`, critical.** The three book icons on the home page are `<img>` elements with no `alt`
  at all. A screen reader meeting one says something, usually the file name, `book.svg`, three times in
  a list of three courses. This is criterion 1.1.1 *Non-text Content*, level A.
- **`color-contrast`, serious.** The sessions marked done are drawn in `#aaaaaa` on white, at **2.32:1**,
  where AA asks for 4.5:1 for text this size. Two elements break it, the session's line and the word
  *done* inside it. This is 1.4.3 *Contrast (Minimum)*, level AA.

## A test that holds the floor

The program reads; a test refuses. Save this as `e2e/a11y.spec.ts`:

```typescript
// e2e/a11y.spec.ts
import { expect, test } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

const wcag22aa = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"];
const pages = [
  ["the course list", "/"],
  ["a course page", "/#/course/javascript"],
];

for (const [name, address] of pages) {
  test(`${name} breaks no WCAG 2.2 AA rule axe can check`, async ({ page }) => {
    await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
    await page.goto(address);
    await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
    const { violations } = await new AxeBuilder({ page }).withTags(wcag22aa).analyze();
    expect(violations.map((v) => `${v.id}: ${v.nodes.length}`)).toEqual([]);
  });
}
```

**The assertion is an empty list, and the failure prints what is in it**: each rule's id and how many
elements break it, which is enough to know what to run `axe.mjs` on.

```
ana@dev:~/planner$ npx playwright test e2e/a11y.spec.ts --reporter=list 2>&1 | grep -E "^  (✓|✘)|^    [-+] |passed|failed"
  ✘  1 [chromium] › e2e/a11y.spec.ts:12:3 › the course list breaks no WCAG 2.2 AA rule axe can check (1.4s)
  ✘  2 [chromium] › e2e/a11y.spec.ts:12:3 › a course page breaks no WCAG 2.2 AA rule axe can check (1.3s)
    - Expected  - 1
    + Received  + 3
    - Array []
    + Array [
    +   "image-alt: 3",
    + ]
    - Expected  - 1
    + Received  + 3
    - Array []
    + Array [
    +   "color-contrast: 2",
    + ]
  2 failed
```
