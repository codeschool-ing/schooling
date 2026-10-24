---
title: Zoomed in, and on a narrow screen
version: 1
---

**People enlarge pages, a lot.** 1.4.4 *Resize Text*, level AA, asks that text can be made twice its size without losing content or
function. 1.4.10 *Reflow*, level AA, asks that at **320 CSS pixels** wide the page works without scrolling
sideways, except for things that need two dimensions, such as a map or a data table. 320 is not an arbitrary phone: it is what a screen 1280 pixels wide becomes at 400% zoom, so a
page that reflows at 320 also survives the zoom that somebody with low vision uses every day.

```typescript
// e2e/display.spec.ts, below what is there
test("at 320 pixels wide, nothing scrolls sideways", async ({ page }) => {
  await page.setViewportSize({ width: 320, height: 640 });
  for (const address of ["/", "/#/course/javascript"]) {
    await page.goto(address);
    await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
    expect(await page.evaluate(() => document.documentElement.scrollWidth), address).toBeLessThanOrEqual(320);
  }
});
```

`scrollWidth` is how wide the document is, drawn; a value over the window's width is a page that scrolls
sideways. The second argument to `expect` is printed with a failure, so it says which page failed.

```
ana@dev:~/planner$ npx playwright test e2e/display.spec.ts -g '320' 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/display.spec.ts:28:1 › at 320 pixels wide, nothing scrolls sideways (283ms)
    Expected: <= 320
    Received:    473
  1 failed
```

The course list fits; the course page is 473 pixels wide. The form puts its three fields and its button on
one line with `display: flex`, and a line that cannot break is as wide as what is on it. **One property
lets it break:**

```
ana@dev:~/planner$ git diff src/style.css
diff --git a/src/style.css b/src/style.css
index f02dc1e..a07fbf4 100644
--- a/src/style.css
+++ b/src/style.css
@@ -27,7 +27,7 @@ li { padding: 0.4rem 0; border-bottom: 1px solid var(--line); }
 .session.done { color: var(--done); }
 .tick { font-size: 0.7rem; padding: 2px 8px; min-width: 24px; min-height: 24px; }
 :focus-visible { outline: 3px solid var(--link); outline-offset: 2px; }
-.add { display: flex; gap: 0.5rem; margin: 1rem 0; }
+.add { display: flex; flex-wrap: wrap; gap: 0.5rem; margin: 1rem 0; }
 .week { font-weight: bold; }
 @media (prefers-reduced-motion: no-preference) {
   .week { animation: pulse 1s ease-in-out 3; }
```

```
ana@dev:~/planner$ npx playwright test e2e/display.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/display.spec.ts:8:1 › every button is at least 24 by 24 pixels (343ms)
  ✓  2 [chromium] › e2e/display.spec.ts:21:1 › with reduced motion asked for, nothing on the page moves (242ms)
  ✓  3 [chromium] › e2e/display.spec.ts:28:1 › at 320 pixels wide, nothing scrolls sideways (216ms)
    - Expected  - 1
    + Received  + 3
    - Array []
    + Array [
    +   "Add session: 89×21",
    + ]
  1 failed
  2 passed (4.8s)
```

**The reflow test passes, and the target test fails: *Add session* is 21 pixels high.** Wrapping the form
put the button on a line of its own, at its own height, where before it was stretched to the textarea's.
Nothing about the button changed, and the floor it relied on was an accident of the layout. This is why the
test measures every button rather than the one the fix was about, and why each criterion's test runs with
all the others. The floor belongs to every button, so it moves to `button`:

```
ana@dev:~/planner$ git diff src/style.css
diff --git a/src/style.css b/src/style.css
index f02dc1e..cdb5b63 100644
--- a/src/style.css
+++ b/src/style.css
@@ -25,9 +25,10 @@ li { padding: 0.4rem 0; border-bottom: 1px solid var(--line); }
 .courses img { vertical-align: middle; margin-right: 0.4rem; }
 .mins { color: var(--quiet); }
 .session.done { color: var(--done); }
-.tick { font-size: 0.7rem; padding: 2px 8px; min-width: 24px; min-height: 24px; }
+button { min-width: 24px; min-height: 24px; }
+.tick { font-size: 0.7rem; padding: 2px 8px; }
 :focus-visible { outline: 3px solid var(--link); outline-offset: 2px; }
-.add { display: flex; gap: 0.5rem; margin: 1rem 0; }
+.add { display: flex; flex-wrap: wrap; gap: 0.5rem; margin: 1rem 0; }
 .week { font-weight: bold; }
 @media (prefers-reduced-motion: no-preference) {
   .week { animation: pulse 1s ease-in-out 3; }
```

```
ana@dev:~/planner$ npx playwright test e2e/display.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/display.spec.ts:8:1 › every button is at least 24 by 24 pixels (290ms)
  ✓  2 [chromium] › e2e/display.spec.ts:21:1 › with reduced motion asked for, nothing on the page moves (179ms)
  ✓  3 [chromium] › e2e/display.spec.ts:28:1 › at 320 pixels wide, nothing scrolls sideways (200ms)
  3 passed (3.7s)
```

Test it by hand as well, in the browser: zoom to 400% with Ctrl and +, or Cmd and + on a Mac, on a window
1280 pixels wide, and read the course page from top to bottom with no sideways scroll.
