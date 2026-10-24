---
title: A dark theme is a second palette
version: 1
---

**A dark theme is not the light one inverted; it is a second set of colours, and every pair in it has to
pass again.** That is why the platform you are reading this on runs axe in both of its themes, and the
planner is about to need the same.

The browser says which the person asked for, in their system's settings, through the media query
`prefers-color-scheme`. A stylesheet that keeps its colours in custom properties can answer it by
redefining them once. Rewrite `src/style.css` that way:

```css
/* src/style.css */
:root {
  color-scheme: light dark;
  --text: #1d1d1d;
  --page: #ffffff;
  --link: #2f6f4e;
  --quiet: #555555;
  --done: #6b6b6b;
  --line: #dddddd;
}
@media (prefers-color-scheme: dark) {
  :root {
    --text: #e6e6e6;
    --page: #161616;
    --quiet: #a3a3a3;
    --done: #8f8f8f;
    --line: #3a3a3a;
  }
}
body { font-family: system-ui, sans-serif; margin: 2rem auto; max-width: 36rem; padding: 0 1rem; color: var(--text); background: var(--page); }
a { color: var(--link); }
ul { padding: 0; list-style: none; }
li { padding: 0.4rem 0; border-bottom: 1px solid var(--line); }
.courses img { vertical-align: middle; margin-right: 0.4rem; }
.mins { color: var(--quiet); }
.session.done { color: var(--done); }
.tick { font-size: 0.7rem; padding: 1px 4px; }
:focus-visible { outline: 3px solid var(--link); outline-offset: 2px; }
.add { display: flex; gap: 0.5rem; margin: 1rem 0; }
.week { font-weight: bold; animation: pulse 1s ease-in-out 3; }
@keyframes pulse { 50% { transform: scale(1.06); } }
.note { white-space: pre-line; margin: 0.2rem 0 0; }
```

`color-scheme: light dark` tells the browser the page can be drawn either way, so its own parts, the
buttons, the fields, the scroll bars, follow the theme too. The green is left as it was, the way a first
pass usually leaves the colour that looked fine on the screen it was chosen on.

## Two tests, from two sides

**The first asks for the palette**: the value of each custom property, as the browser resolved it in each
scheme, run through the arithmetic of the last section. It is a Playwright test, because only a browser
knows which block of the stylesheet applies; Vitest does not process CSS unless it is told to, and a CSS
file imported into a unit test arrives as an empty string. Save it as `e2e/palette.spec.ts`:

```typescript
// e2e/palette.spec.ts
import { expect, test } from "@playwright/test";
import { contrast } from "../src/contrast";

const text = ["text", "link", "quiet", "done"];

for (const colorScheme of ["light", "dark"] as const) {
  test(`every text colour of the ${colorScheme} palette reaches 4.5:1 on the page`, async ({ page }) => {
    await page.emulateMedia({ colorScheme });
    await page.goto("/");
    const colours = await page.evaluate((names) => {
      const style = getComputedStyle(document.documentElement);
      return Object.fromEntries(names.map((n) => [n, style.getPropertyValue(`--${n}`).trim()]));
    }, ["page", ...text]);
    const short = text
      .map((n) => [n, contrast(colours[n], colours.page)] as const)
      .filter(([, ratio]) => !(ratio >= 4.5))
      .map(([n, ratio]) => `--${n}: ${ratio.toFixed(2)}:1`);
    expect(short).toEqual([]);
  });
}
```

`page.emulateMedia` makes the page see the scheme it is given, and the test imports `contrast` straight
from `src/`, because Playwright compiles TypeScript too. A property that is missing reads as an empty
string, its ratio is `NaN`, and `!(NaN >= 4.5)` is true, so a colour that is not there is reported rather
than passed over in silence.

```
ana@dev:~/planner$ npx playwright test e2e/palette.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/palette.spec.ts:8:3 › every text colour of the light palette reaches 4.5:1 on the page (216ms)
  ✘  2 [chromium] › e2e/palette.spec.ts:8:3 › every text colour of the dark palette reaches 4.5:1 on the page (248ms)
    - Expected  - 1
    + Received  + 3
    - Array []
    + Array [
    +   "--link: 3.02:1",
    + ]
  1 failed
  1 passed (4.7s)
```

**The second asks the page, in each theme.** Playwright's `colorScheme` option makes the browser report
the scheme it is given. In `e2e/a11y.spec.ts`, the loop over the pages becomes a loop over the pages and
the two schemes:

```
ana@dev:~/planner$ git diff e2e/a11y.spec.ts
diff --git a/e2e/a11y.spec.ts b/e2e/a11y.spec.ts
index 241c893..3f2ad80 100644
--- a/e2e/a11y.spec.ts
+++ b/e2e/a11y.spec.ts
@@ -8,12 +8,17 @@ const pages = [
   ["a course page", "/#/course/javascript"],
 ];
 
-for (const [name, address] of pages) {
-  test(`${name} breaks no WCAG 2.2 AA rule axe can check`, async ({ page }) => {
-    await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
-    await page.goto(address);
-    await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
-    const { violations } = await new AxeBuilder({ page }).withTags(wcag22aa).analyze();
-    expect(violations.map((v) => `${v.id}: ${v.nodes.length}`)).toEqual([]);
+for (const colorScheme of ["light", "dark"] as const) {
+  test.describe(`${colorScheme} theme`, () => {
+    test.use({ colorScheme });
+    for (const [name, address] of pages) {
+      test(`${name} breaks no WCAG 2.2 AA rule axe can check`, async ({ page }) => {
+        await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
+        await page.goto(address);
+        await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
+        const { violations } = await new AxeBuilder({ page }).withTags(wcag22aa).analyze();
+        expect(violations.map((v) => `${v.id}: ${v.nodes.length}`)).toEqual([]);
+      });
+    }
   });
 }
```

```
ana@dev:~/planner$ npx playwright test e2e/a11y.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/a11y.spec.ts:15:7 › light theme › the course list breaks no WCAG 2.2 AA rule axe can check (1.1s)
  ✓  2 [chromium] › e2e/a11y.spec.ts:15:7 › light theme › a course page breaks no WCAG 2.2 AA rule axe can check (1.0s)
  ✘  3 [chromium] › e2e/a11y.spec.ts:15:7 › dark theme › the course list breaks no WCAG 2.2 AA rule axe can check (1.2s)
  ✘  4 [chromium] › e2e/a11y.spec.ts:15:7 › dark theme › a course page breaks no WCAG 2.2 AA rule axe can check (1.3s)
    - Expected  - 1
    + Received  + 3
    - Array []
    + Array [
    +   "color-contrast: 3",
    + ]
    - Expected  - 1
    + Received  + 3
    - Array []
    + Array [
    +   "color-contrast: 1",
    + ]
  2 failed
  2 passed (9.2s)
```

**Both say the same thing from two sides.** The planner's green, `#2f6f4e`, reaches 5.99:1 on white and
3.02:1 on `#161616`. The test of the palette names the colour; axe names the elements, the back link
on the course page and the three course links on the list. A green for the dark page, chosen with the
arithmetic, reaches 8.71:1, and goes into the dark block:

```
ana@dev:~/planner$ sed -n '/prefers-color-scheme: dark/,/^}/p' src/style.css
@media (prefers-color-scheme: dark) {
  :root {
    --text: #e6e6e6;
    --page: #161616;
    --link: #6fc596;
    --quiet: #a3a3a3;
    --done: #8f8f8f;
    --line: #3a3a3a;
  }
}
```

```
ana@dev:~/planner$ npx playwright test e2e/palette.spec.ts e2e/a11y.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/palette.spec.ts:8:3 › every text colour of the light palette reaches 4.5:1 on the page (279ms)
  ✓  3 [chromium] › e2e/palette.spec.ts:8:3 › every text colour of the dark palette reaches 4.5:1 on the page (214ms)
  ✓  2 [chromium] › e2e/a11y.spec.ts:15:7 › light theme › the course list breaks no WCAG 2.2 AA rule axe can check (1.2s)
  ✓  4 [chromium] › e2e/a11y.spec.ts:15:7 › light theme › a course page breaks no WCAG 2.2 AA rule axe can check (965ms)
  ✓  5 [chromium] › e2e/a11y.spec.ts:15:7 › dark theme › the course list breaks no WCAG 2.2 AA rule axe can check (966ms)
  ✓  6 [chromium] › e2e/a11y.spec.ts:15:7 › dark theme › a course page breaks no WCAG 2.2 AA rule axe can check (998ms)
  6 passed (7.5s)
ana@dev:~/planner$ git add -A && git commit -qm "A dark theme, its palette and its pages tested in both schemes"
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l13-pairs\" aria-label=\"Four colour pairs, each drawn as a swatch of the text colour on its background, with its ratio. Light theme: #aaaaaa on white, 2.32 to 1, fails; #6b6b6b on white, 5.33 to 1, passes. Dark theme: the light theme's green #2f6f4e on #161616, 3.02 to 1, fails; #6fc596 on #161616, 8.71 to 1, passes. A note says that AA asks 4.5 to 1 for text.\"><text x=\"190\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">light theme</text><text x=\"530\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">dark theme</text><rect x=\"30\" y=\"36\" width=\"150\" height=\"64\" rx=\"4\" fill=\"#ffffff\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"70\" y=\"58\" width=\"70\" height=\"20\" rx=\"3\" fill=\"#aaaaaa\"></rect><text x=\"105\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">#aaaaaa / #ffffff</text><text x=\"105\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">2.32:1</text><text x=\"105\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">fails</text><rect x=\"202\" y=\"36\" width=\"150\" height=\"64\" rx=\"4\" fill=\"#ffffff\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"242\" y=\"58\" width=\"70\" height=\"20\" rx=\"3\" fill=\"#6b6b6b\"></rect><text x=\"277\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">#6b6b6b / #ffffff</text><text x=\"277\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">5.33:1</text><text x=\"277\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--phosphor)\">passes</text><rect x=\"374\" y=\"36\" width=\"150\" height=\"64\" rx=\"4\" fill=\"#161616\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"414\" y=\"58\" width=\"70\" height=\"20\" rx=\"3\" fill=\"#2f6f4e\"></rect><text x=\"449\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">#2f6f4e / #161616</text><text x=\"449\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">3.02:1</text><text x=\"449\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">fails</text><rect x=\"546\" y=\"36\" width=\"150\" height=\"64\" rx=\"4\" fill=\"#161616\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"586\" y=\"58\" width=\"70\" height=\"20\" rx=\"3\" fill=\"#6fc596\"></rect><text x=\"621\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">#6fc596 / #161616</text><text x=\"621\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">8.71:1</text><text x=\"621\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--phosphor)\">passes</text><text x=\"690\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">AA for text: 4.5:1</text></svg>", "caption": "The two failures this course found and the two colours that replaced them. A colour that passes on one background can fail on the other: the green is the same in both failures and passes."}
```

The focus ring uses `--link` as well, so it changed with it: 3.02:1 would have met the 3:1 a ring needs,
barely, and 8.71:1 meets it with room.
