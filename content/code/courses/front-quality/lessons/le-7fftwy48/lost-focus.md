---
title: Where the focus goes when the page changes
version: 1
---

**Press Done from the keyboard and the focus disappears.** The planner draws every screen with
`root.replaceChildren()`, so marking a session done removes the button that had the focus, and an element
that is no longer in the page cannot hold it. The focus falls back to the `body`. The next Tab starts
again from the top of the page, and a screen reader says nothing at all, or the name of the page,
somewhere a person did not ask to be.

That fails 2.4.3 *Focus Order*: the focus is supposed to move in an order that keeps the meaning, and
being thrown back to the start keeps none.

## Where should it go?

To the element that took the place of the one that went, if there is one, and if there is not, to the
nearest thing that makes sense. After **Done**, the button is replaced by the word *done* on the same row,
so the row is the right place: a screen reader then reads *2026-10-22 · 30 min done*, which is the
confirmation that the press worked.

## The test

```typescript
// e2e/keyboard.spec.ts, below what is there
test("after Done, the focus is on the session it marked", async ({ page }) => {
  await page.goto("/#/course/javascript");
  await page.getByRole("button", { name: "Done" }).press("Enter");
  await expect(page.getByRole("listitem").filter({ hasText: "2026-10-22" })).toBeFocused();
});
```

`press("Enter")` on a locator focuses the element and presses the key, the way somebody does who has
tabbed to it.

```
ana@dev:~/planner$ npx playwright test e2e/keyboard.spec.ts -g 'after Done' 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/keyboard.spec.ts:51:1 › after Done, the focus is on the session it marked (5.3s)
    Error: expect(locator).toBeFocused() failed
    Locator:  getByRole('listitem').filter({ hasText: '2026-10-22' })
    Expected: focused
    Received: inactive
  1 failed
```

*inactive* is Playwright's word for an element that does not have the focus.

## The fix

A list item cannot take the focus, so it is given **`tabindex="-1"`**, which lets a script focus it
without adding it to the tab order: Tab still goes from button to button. Each row also carries the
session's id, so that the click handler can find the new row once the screen has been drawn again:

```
ana@dev:~/planner$ git diff src/view.ts
diff --git a/src/view.ts b/src/view.ts
index 44588f5..d627dd2 100644
--- a/src/view.ts
+++ b/src/view.ts
@@ -27,11 +27,16 @@ export function render(root: HTMLElement, plan: Plan, day: string, route: string
   const list = el("ul", "", "sessions");
   for (const s of plan.sessions.filter((s) => s.course === course.id)) {
     const item = el("li", `${s.date} · ${s.minutes} min `, s.done ? "session done" : "session");
+    item.dataset.session = String(s.id);
+    item.tabIndex = -1;
     if (s.done) {
       item.append(el("span", "done", "state"));
     } else {
       const tick = el("button", "Done", "tick");
-      tick.addEventListener("click", () => update(markDone(plan, s.id)));
+      tick.addEventListener("click", () => {
+        update(markDone(plan, s.id));
+        root.querySelector<HTMLElement>(`[data-session="${s.id}"]`)?.focus();
+      });
       item.append(tick);
     }
     if (s.note) {
```

`update` draws the new screen before it returns, so the `querySelector` on the next line finds the new
row, not the old one.

```
ana@dev:~/planner$ npx playwright test e2e/keyboard.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/keyboard.spec.ts:22:1 › Tab reaches every control of a course page, in reading order (350ms)
  ✓  2 [chromium] › e2e/keyboard.spec.ts:38:1 › the focused control can be seen (258ms)
  ✓  3 [chromium] › e2e/keyboard.spec.ts:51:1 › after Done, the focus is on the session it marked (172ms)
  3 passed (3.9s)
```
