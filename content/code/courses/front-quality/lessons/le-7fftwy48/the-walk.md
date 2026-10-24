---
title: The walk through a page, as a test
version: 1
---

**The first test presses Tab and writes down where the focus goes.** That list is the page's tab order,
and a test that holds it turns any change to the order into a decision somebody has to make. Save this as
`e2e/keyboard.spec.ts`:

```typescript
// e2e/keyboard.spec.ts
import { expect, test, type Page } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
});

async function tabThrough(page: Page, presses: number): Promise<string[]> {
  const seen: string[] = [];
  for (let i = 0; i < presses; i++) {
    await page.keyboard.press("Tab");
    seen.push(
      await page.evaluate(() => {
        const e = document.activeElement!;
        return `${e.tagName.toLowerCase()} ${e.getAttribute("name") ?? e.textContent}`;
      }),
    );
  }
  return seen;
}

test("Tab reaches every control of a course page, in reading order", async ({ page }) => {
  await page.goto("/#/course/javascript");
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  expect(await tabThrough(page, 6)).toEqual([
    "a ←",
    "button Done",
    "input date",
    "input minutes",
    "textarea note",
    "button Add session",
  ]);
});
```

`page.keyboard.press("Tab")` is a real key press, sent to the browser as the operating system would send
it. `document.activeElement` is the element holding the focus, and `tabThrough` describes each one by its
tag and its `name`, or its text when it has no name. The expected list is a prediction made by reading the
page from the top: the back link, the one **Done** button of the JavaScript course, the three fields and
the button of the form.

```
ana@dev:~/planner$ npx playwright test e2e/keyboard.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/keyboard.spec.ts:22:1 › Tab reaches every control of a course page, in reading order (378ms)
    - Expected  - 3
    + Received  + 3
    -   "input minutes",
    -   "textarea note",
    -   "button Add session",
    +   "input date",
    +   "input date",
    +   "input date",
  1 failed
```

**The prediction was wrong, and the page was right.** Chromium stops on a date field four times: once on
each part of the date, month, day and year, and once on the button beside them that opens a calendar. A
person filling the form in with the keyboard presses Tab four times to cross it, so six presses never
reached the minutes, the note or the button. In the report, `-` is what the test expected and `+` what
the page did. That is the reason to write the walk down rather
than imagine it. Correct the expectation:

```typescript
  expect(await tabThrough(page, 9)).toEqual([
    "a ←",
    "button Done",
    "input date",
    "input date",
    "input date",
    "input date",
    "input minutes",
    "textarea note",
    "button Add session",
  ]);
```

```
ana@dev:~/planner$ npx playwright test e2e/keyboard.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/keyboard.spec.ts:22:1 › Tab reaches every control of a course page, in reading order (354ms)
  1 passed (3.5s)
```

The order is right: it follows the page from the top, the way it reads. **This test passes and keeps
passing until somebody moves a control**, and then it fails with the new order printed, which is the
moment to ask whether the new order still makes sense. The back link's text, a lone arrow, is a problem
of its own, and it is lesson 12's: a screen reader reads out the symbol's name, something like *left arrow*.
