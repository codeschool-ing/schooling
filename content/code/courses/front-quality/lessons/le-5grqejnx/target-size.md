---
title: A target big enough to hit
version: 1
---

**A control has to be big enough to press without pressing its neighbour.** It is a question for anyone
with a tremor, anyone on a phone in a moving bus, anyone with large fingers. 2.5.8 *Target Size
(Minimum)*, level AA and new in WCAG 2.2, asks that each target is **at least 24 by 24 CSS pixels**, or
that a circle of 24 pixels around its centre touches no other target. 2.5.5 at AAA asks for 44 by 44.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l13-target\" aria-label=\"Two drawings at the same scale. On the left, a dashed square of 24 by 24 CSS pixels beside the planner's Done button before the fix, 39 by 18: the button is shorter than the square. On the right, the same square beside the button after the fix, at least 24 pixels high, as tall as the square. A note says that a target smaller than 24 pixels still passes if a circle of 24 pixels around its centre touches no other target.\"><rect x=\"40\" y=\"40\" width=\"96\" height=\"96\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"152\" y=\"64\" width=\"156\" height=\"72\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Done</text><text x=\"174.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">before: 39 × 18</text><text x=\"88\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">24 × 24 CSS px</text><rect x=\"390\" y=\"40\" width=\"96\" height=\"96\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"502\" y=\"40\" width=\"188\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"596.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Done</text><text x=\"540.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--phosphor)\">after: at least 24 high</text><text x=\"438\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">24 × 24 CSS px</text><text x=\"360\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">smaller still passes if a 24 px circle around it touches no other target</text></svg>", "caption": "2.5.8 Target Size (Minimum), level AA. The rule is about the box the person has to hit, not about the size of the text inside it."}
```

Lesson 1 drew the **Done** button deliberately small: `font-size: 0.7rem; padding: 1px 4px`. A test that
measures every button, in a new file `e2e/display.spec.ts`:

```typescript
// e2e/display.spec.ts
import { expect, test } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
});

test("every button is at least 24 by 24 pixels", async ({ page }) => {
  await page.goto("/#/course/javascript");
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  const small: string[] = [];
  for (const button of await page.getByRole("button").all()) {
    const box = (await button.boundingBox())!;
    if (box.width < 24 || box.height < 24) {
      small.push(`${await button.textContent()}: ${Math.round(box.width)}×${Math.round(box.height)}`);
    }
  }
  expect(small).toEqual([]);
});
```

`boundingBox()` is the rectangle the browser drew, in CSS pixels, so it is the size the person meets.

```
ana@dev:~/planner$ npx playwright test e2e/display.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/display.spec.ts:8:1 › every button is at least 24 by 24 pixels (349ms)
    - Expected  - 1
    + Received  + 3
    - Array []
    + Array [
    +   "Done: 39×18",
    + ]
  1 failed
```

**Eighteen pixels high.** It is wide enough, because *Done* is four letters, and too short, because the
padding is one pixel. The fix keeps the small text and gives the button the size around it:

```
ana@dev:~/planner$ git diff src/style.css
diff --git a/src/style.css b/src/style.css
index ee4b83f..c47851f 100644
--- a/src/style.css
+++ b/src/style.css
@@ -25,7 +25,7 @@ li { padding: 0.4rem 0; border-bottom: 1px solid var(--line); }
 .courses img { vertical-align: middle; margin-right: 0.4rem; }
 .mins { color: var(--quiet); }
 .session.done { color: var(--done); }
-.tick { font-size: 0.7rem; padding: 1px 4px; }
+.tick { font-size: 0.7rem; padding: 2px 8px; min-width: 24px; min-height: 24px; }
 :focus-visible { outline: 3px solid var(--link); outline-offset: 2px; }
 .add { display: flex; gap: 0.5rem; margin: 1rem 0; }
 .week { font-weight: bold; animation: pulse 1s ease-in-out 3; }
```

```
ana@dev:~/planner$ npx playwright test e2e/display.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/display.spec.ts:8:1 › every button is at least 24 by 24 pixels (290ms)
  1 passed (3.3s)
ana@dev:~/planner$ git add -A && git commit -qm "A Done button at least 24 pixels square"
```

`min-height` and `min-width` set the floor without fixing the size, so a longer label, in another
language, still makes a longer button.

**The rule is written for `.tick`, and only `.tick`.** The other button passes because it happens to be
large: the form lays its fields out on one line, and a flex line stretches every item to the height of
the tallest, the note's textarea. Keep that *happens to* in mind for two sections.
