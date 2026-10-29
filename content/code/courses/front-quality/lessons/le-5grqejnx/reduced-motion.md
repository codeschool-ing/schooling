---
title: Movement somebody asked not to see
version: 1
---

**For some people, movement on a page is not decoration; it is nausea.** Vestibular disorders make the
inner ear's sense of balance disagree with what the eyes report, and a zoom, a parallax scroll or a
pulse can bring on dizziness that lasts for hours. Every major system has a setting for it, *Reduce
motion* on macOS and iOS, *Animation effects* on Windows, *Remove animations* on Android, and the browser
passes it on to the page as the media query `prefers-reduced-motion: reduce`.

The planner's weekly total pulses three times when the page is drawn, from lesson 1's stylesheet. The
criteria are 2.3.3 *Animation from Interactions*, at AAA, and, for anything that moves on its own for more
than five seconds, 2.2.2 *Pause, Stop, Hide* at A. Three seconds of pulse is under both bars at AA, and the
setting is still a request somebody made; honouring it costs one media query.

```typescript
// e2e/display.spec.ts, below what is there
test("with reduced motion asked for, nothing on the page moves", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.goto("/");
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  expect(await page.evaluate(() => document.getAnimations().map((a) => (a as CSSAnimation).animationName))).toEqual([]);
});
```

`document.getAnimations()` lists every animation running in the document, CSS ones included, and each CSS
animation carries the name of its `@keyframes`, so a failure says which one moved.

```
ana@dev:~/planner$ npx playwright test e2e/display.spec.ts -g 'reduced motion' 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/display.spec.ts:21:1 › with reduced motion asked for, nothing on the page moves (269ms)
    - Expected  - 1
    + Received  + 3
    - Array []
    + Array [
    +   "pulse",
    + ]
  1 failed
```

The fix moves the animation inside a query that only matches when nobody asked for less, so that the
default is still the pulse and the request removes it:

```
ana@dev:~/planner$ git diff src/style.css
diff --git a/src/style.css b/src/style.css
index c47851f..f02dc1e 100644
--- a/src/style.css
+++ b/src/style.css
@@ -28,6 +28,9 @@ li { padding: 0.4rem 0; border-bottom: 1px solid var(--line); }
 .tick { font-size: 0.7rem; padding: 2px 8px; min-width: 24px; min-height: 24px; }
 :focus-visible { outline: 3px solid var(--link); outline-offset: 2px; }
 .add { display: flex; gap: 0.5rem; margin: 1rem 0; }
-.week { font-weight: bold; animation: pulse 1s ease-in-out 3; }
+.week { font-weight: bold; }
+@media (prefers-reduced-motion: no-preference) {
+  .week { animation: pulse 1s ease-in-out 3; }
+}
 @keyframes pulse { 50% { transform: scale(1.06); } }
 .note { white-space: pre-line; margin: 0.2rem 0 0; }
```

```
ana@dev:~/planner$ npx playwright test e2e/display.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/display.spec.ts:8:1 › every button is at least 24 by 24 pixels (301ms)
  ✓  2 [chromium] › e2e/display.spec.ts:21:1 › with reduced motion asked for, nothing on the page moves (170ms)
  2 passed (3.6s)
ana@dev:~/planner$ git commit -qam "No pulse for somebody who asked for less motion"
```

**`no-preference` rather than `reduce`** is the safer way round: a browser that does not know the query at
all matches neither, and gets no animation. The reverse, an animation everywhere and a `reduce` block
that removes it, gives the animation to everybody whose browser does not pass the setting on.
