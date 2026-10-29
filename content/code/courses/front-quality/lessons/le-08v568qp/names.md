---
title: Every control has a name
version: 1
---

**A control's accessible name is what a screen reader says for it, and what `getByRole` finds it by.** The
browser works it out from the first of these that the element has:

1. `aria-labelledby`, which points at other elements by id and uses their text;
2. `aria-label`, a string written on the element itself;
3. for a form field, its `<label>`; for an image, its `alt`;
4. for a link or a button, the text inside it, including the `alt` of any image inside;
5. as a last resort, the `title` attribute, which most people never see.

**The visible words should be the name, or the start of it.** 2.5.3 *Label in Name*, level A, asks that
the name of a control contains the text it shows, because a person using voice control says what they
see: *click Add session*. An `aria-label` that renames a button to something else breaks that person's
only way to press it.

## The back link

The planner's back link shows an arrow and nothing else, so its name is the arrow. Its job is to go back
to the list of courses, so that is what it should say. The arrow can stay for the eye and be hidden from
the tree with `aria-hidden="true"`, which removes an element from the accessibility tree and leaves it on
the screen.

Start a test file for what a screen reader is told, `e2e/screen-reader.spec.ts`:

```typescript
// e2e/screen-reader.spec.ts
import { expect, test } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
});

test("the back link says where it goes", async ({ page }) => {
  await page.goto("/#/course/javascript");
  await expect(page.getByRole("link", { name: "All courses" })).toBeVisible();
});
```

```
ana@dev:~/planner$ npx playwright test e2e/screen-reader.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/screen-reader.spec.ts:8:1 › the back link says where it goes (5.3s)
    Error: expect(locator).toBeVisible() failed
    Locator: getByRole('link', { name: 'All courses' })
    Expected: visible
  1 failed
```

The fix gives the link its words and hides the arrow from the tree:

```
ana@dev:~/planner$ git diff src/view.ts
diff --git a/src/view.ts b/src/view.ts
index d627dd2..2e2aadd 100644
--- a/src/view.ts
+++ b/src/view.ts
@@ -21,7 +21,10 @@ export function render(root: HTMLElement, plan: Plan, day: string, route: string
     root.append(list, el("p", `This week: ${weekTotal(plan, day)} min`, "week"));
     return;
   }
-  const back = el("a", "←", "back");
+  const back = el("a", " All courses", "back");
+  const arrow = el("span", "←");
+  arrow.setAttribute("aria-hidden", "true");
+  back.prepend(arrow);
   back.href = "#/";
   root.append(back, el("h1", course.title));
   const list = el("ul", "", "sessions");
```

```
ana@dev:~/planner$ npx playwright test e2e/screen-reader.spec.ts e2e/keyboard.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  2 [chromium] › e2e/screen-reader.spec.ts:8:1 › the back link says where it goes (428ms)
  ✘  1 [chromium] › e2e/keyboard.spec.ts:22:1 › Tab reaches every control of a course page, in reading order (649ms)
  ✓  3 [chromium] › e2e/keyboard.spec.ts:38:1 › the focused control can be seen (329ms)
  ✓  4 [chromium] › e2e/keyboard.spec.ts:51:1 › after Done, the focus is on the session it marked (207ms)
  ✓  5 [chromium] › e2e/keyboard.spec.ts:57:1 › a link followed puts the focus on the new page's heading (186ms)
  ✓  6 [chromium] › e2e/keyboard.spec.ts:63:1 › the first page leaves the focus where it was (168ms)
    - Expected  - 1
    + Received  + 1
    -   "a ←",
    +   "a ← All courses",
  1 failed
  5 passed (6.6s)
```

**The new test passes, and lesson 11's walk fails**, because it describes each stop by its text, and the
first stop's text changed. The order did not. This is the walk test doing what it was written for: it
stops a change to the keyboard path from going through unnoticed, and somebody decides. Here the decision
is easy; correct its first line:

```typescript
    "a ← All courses",
```

```
ana@dev:~/planner$ npx playwright test e2e/screen-reader.spec.ts e2e/keyboard.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/screen-reader.spec.ts:8:1 › the back link says where it goes (316ms)
  ✓  2 [chromium] › e2e/keyboard.spec.ts:22:1 › Tab reaches every control of a course page, in reading order (444ms)
  ✓  3 [chromium] › e2e/keyboard.spec.ts:38:1 › the focused control can be seen (238ms)
  ✓  4 [chromium] › e2e/keyboard.spec.ts:51:1 › after Done, the focus is on the session it marked (182ms)
  ✓  5 [chromium] › e2e/keyboard.spec.ts:57:1 › a link followed puts the focus on the new page's heading (209ms)
  ✓  6 [chromium] › e2e/keyboard.spec.ts:63:1 › the first page leaves the focus where it was (186ms)
  6 passed (4.6s)
```

The walk reads `textContent`, which includes the hidden arrow; the screen reader reads the name, which
does not. Both are right about what they measure.
