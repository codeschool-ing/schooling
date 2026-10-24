---
title: Moving the focus on navigation, and only then
version: 1
---

**When a browser loads a new page, it puts the focus back at the top of the document**, and a screen
reader announces the new page's title. The planner never loads a new page. Following a link changes the
`#` part of the address, the app draws another screen into the same document, and the browser does
neither of those things: the focus is lost with the link that had it, exactly as with **Done**, and the
person using a screen reader is told nothing.

**So a single-page app has to do what the browser would have done.** The usual answer, and the planner's,
is to move the focus to the new screen's main heading. A screen reader then reads the heading, which says
where the person is, and the next Tab goes to the first control after it.

## Only on navigation

The first screen is the opposite case. Nothing was followed; the browser has just loaded the page, and
it has already put the focus where a new page's focus goes. Moving it to the heading then would put
everything above the heading behind the person, and Tab would go forwards from the middle of the page.
So there are two tests, one for each half:

```typescript
// e2e/keyboard.spec.ts, below what is there
test("a link followed puts the focus on the new page's heading", async ({ page }) => {
  await page.goto("/");
  await page.getByRole("link", { name: "JavaScript" }).press("Enter");
  await expect(page.getByRole("heading", { name: "JavaScript", level: 1 })).toBeFocused();
});

test("the first page leaves the focus where it was", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  expect(await tabThrough(page, 1)).toEqual(["a HTML and CSS"]);
});
```

```
ana@dev:~/planner$ npx playwright test e2e/keyboard.spec.ts -g 'link followed|first page' 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/keyboard.spec.ts:57:1 › a link followed puts the focus on the new page's heading (5.3s)
  ✓  2 [chromium] › e2e/keyboard.spec.ts:63:1 › the first page leaves the focus where it was (236ms)
    Error: expect(locator).toBeFocused() failed
    Locator:  getByRole('heading', { name: 'JavaScript', level: 1 })
    Expected: focused
    Received: inactive
  1 failed
  1 passed (9.7s)
```

**The second passes already, and is written now so that the fix cannot break it.** A fix that focused the
heading on every draw would pass the first and fail the second, and that is the mistake this pair is
built to catch.

## The fix

The move belongs where the app knows that a navigation happened, which is the `hashchange` listener in
`src/app.ts`. A heading cannot take the focus either, so it gets the same `tabindex="-1"` as the session
row:

```
ana@dev:~/planner$ git diff src/app.ts
diff --git a/src/app.ts b/src/app.ts
index bd23cce..9ba01d9 100644
--- a/src/app.ts
+++ b/src/app.ts
@@ -14,6 +14,13 @@ export async function start(root: HTMLElement, load = () => fetch("/courses.json
       plan = next;
       draw();
     });
-  window.addEventListener("hashchange", draw);
+  window.addEventListener("hashchange", () => {
+    draw();
+    const heading = root.querySelector("h1");
+    if (heading) {
+      heading.tabIndex = -1;
+      heading.focus();
+    }
+  });
   draw();
 }
```

This run is the whole suite, not only the keyboard file, because the session rows and the headings now
carry a `tabindex` and axe has an opinion about anything that can take the focus. It has none here.

```
ana@dev:~/planner$ npx playwright test 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓   1 [chromium] › e2e/empty.spec.ts:4:1 › a course with nothing planned says 0 for its week (657ms)
  ✓   3 [chromium] › e2e/frame.spec.ts:9:1 › another site cannot put the built planner in a frame (227ms)
  ✓   4 [chromium] › e2e/frame.spec.ts:13:1 › without the policy, the same frame loads: the control (244ms)
  ✓   5 [chromium] › e2e/headers.spec.ts:6:1 › the built site is served with its security headers (28ms)
  ✓   6 [chromium] › e2e/headers.spec.ts:16:1 › the built site works under its own policy (250ms)
  ✓   2 [chromium] › e2e/a11y.spec.ts:12:3 › the course list breaks no WCAG 2.2 AA rule axe can check (1.9s)
  ✓   7 [chromium] › e2e/keyboard.spec.ts:22:1 › Tab reaches every control of a course page, in reading order (578ms)
  ✓   9 [chromium] › e2e/keyboard.spec.ts:38:1 › the focused control can be seen (393ms)
  ✓  10 [chromium] › e2e/keyboard.spec.ts:51:1 › after Done, the focus is on the session it marked (265ms)
  ✓  11 [chromium] › e2e/keyboard.spec.ts:57:1 › a link followed puts the focus on the new page's heading (281ms)
  ✓  12 [chromium] › e2e/keyboard.spec.ts:63:1 › the first page leaves the focus where it was (367ms)
  ✓   8 [chromium] › e2e/a11y.spec.ts:12:3 › a course page breaks no WCAG 2.2 AA rule axe can check (1.5s)
  ✓  13 [chromium] › e2e/planner.spec.ts:8:1 › the home page shows the week (266ms)
  ✓  14 [chromium] › e2e/storage.spec.ts:4:1 › the session cookie is out of reach of the page's scripts (296ms)
  ✓  15 [chromium] › e2e/planner.spec.ts:14:1 › a session added to a course counts in its week (361ms)
  ✓  16 [chromium] › e2e/planner.spec.ts:24:1 › Done marks a session and takes its button away (238ms)
  ✓  17 [chromium] › e2e/planner.spec.ts:30:1 › a failed load says so (167ms)
  17 passed (8.8s)
```

**The heading shows its ring when the link was followed by Enter, and not when it was clicked**, by the
rule the last section but one described: the focus inherits how the person arrived. Commit the three fixes and their tests:

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Keyboard: a focus that can be seen, and that stays where it makes sense"
```
