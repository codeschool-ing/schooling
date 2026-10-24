---
title: Saying that something changed
version: 1
---

**A screen reader reads what the person moves to. A change somewhere else on the page is silent** unless
the page asks for it to be read. When a session is added, the planner draws a new row and a new total,
and somebody who cannot see them is told nothing, and worse, their focus has gone with the button.

A **live region** is the way to ask. An element with `role="status"`, or `aria-live="polite"`, has its
new text read out when it changes, once the reader has finished what it is saying. `role="alert"`, or
`aria-live="assertive"`, interrupts, and belongs to errors that cannot wait. This one can wait, so it is a
status. The criterion is 4.1.3 *Status Messages*, level AA.

**The region has to exist before the text arrives.** A reader watches the live regions that are in the page;
one created already holding its message is usually read by nobody. The planner draws its whole screen
with `replaceChildren()`, which would throw the region away with everything else, so it cannot be part of
the screen: it is made once, beside the root, and kept.

## The test

```typescript
// e2e/screen-reader.spec.ts, below what is there
test("adding a session says so, and leaves the focus in the form", async ({ page }) => {
  await page.goto("/#/course/javascript");
  await page.getByLabel("Date").fill("2026-10-23");
  await page.getByLabel("Minutes").fill("15");
  await page.getByRole("button", { name: "Add session" }).press("Enter");
  await expect(page.getByRole("status")).toHaveText("Session added: 2026-10-23, 15 min");
  await expect(page.getByLabel("Date")).toBeFocused();
});
```

The focus goes back to **Date**, the first field, because the likeliest next thing after adding one session
is adding another.

```
ana@dev:~/planner$ npx playwright test e2e/screen-reader.spec.ts -g 'says so' 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/screen-reader.spec.ts:20:1 › adding a session says so, and leaves the focus in the form (5.4s)
    Error: expect(locator).toHaveText(expected) failed
    Locator: getByRole('status')
    Expected: "Session added: 2026-10-23, 15 min"
  1 failed
```

## The fix

`render` gets a second, optional argument to `update`: what to say. The form's handler says what it did,
and puts the focus back in the form; **Done** says nothing, because lesson 11 already moves the focus to a
row that reads *done*. The app makes the region once and fills it on every update, and empties it on
navigation, so that a message about one course is not left standing on another. The diff of `src/view.ts`
also shows the back link from two sections ago, which is not committed yet:

```
ana@dev:~/planner$ git diff src
diff --git a/src/app.ts b/src/app.ts
index 9ba01d9..6d3b757 100644
--- a/src/app.ts
+++ b/src/app.ts
@@ -9,12 +9,17 @@ export async function start(root: HTMLElement, load = () => fetch("/courses.json
     return;
   }
   let plan: Plan = await response.json();
+  const status = document.createElement("p");
+  status.setAttribute("role", "status");
+  root.after(status);
   const draw = (): void =>
-    render(root, plan, today(), location.hash, (next) => {
+    render(root, plan, today(), location.hash, (next, said = "") => {
       plan = next;
       draw();
+      status.textContent = said;
     });
   window.addEventListener("hashchange", () => {
+    status.textContent = "";
     draw();
     const heading = root.querySelector("h1");
     if (heading) {
diff --git a/src/view.ts b/src/view.ts
index d627dd2..51c4797 100644
--- a/src/view.ts
+++ b/src/view.ts
@@ -1,7 +1,7 @@
 // src/view.ts
 import { addSession, markDone, weekTotal, type Plan } from "./planner";
 
-export function render(root: HTMLElement, plan: Plan, day: string, route: string, update: (next: Plan) => void): void {
+export function render(root: HTMLElement, plan: Plan, day: string, route: string, update: (next: Plan, said?: string) => void): void {
   const course = plan.courses.find((c) => route === `#/course/${c.id}`);
   root.replaceChildren();
   if (!course) {
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
@@ -55,7 +58,10 @@ export function render(root: HTMLElement, plan: Plan, day: string, route: string
     event.preventDefault();
     const data = new FormData(form);
     const note = String(data.get("note") ?? "");
-    update(addSession(plan, course.id, String(data.get("date")), Number(data.get("minutes")), note));
+    const date = String(data.get("date"));
+    const minutes = Number(data.get("minutes"));
+    update(addSession(plan, course.id, date, minutes, note), `Session added: ${date}, ${minutes} min`);
+    root.querySelector<HTMLInputElement>(`input[name="date"]`)?.focus();
   });
   root.append(list, form, el("p", `This week: ${weekTotal(plan, day, course.id)} min`, "week"));
 }
```

```
ana@dev:~/planner$ npx playwright test e2e/screen-reader.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/screen-reader.spec.ts:8:1 › the back link says where it goes (265ms)
  ✓  2 [chromium] › e2e/screen-reader.spec.ts:13:1 › every page has one main landmark (215ms)
  ✓  3 [chromium] › e2e/screen-reader.spec.ts:20:1 › adding a session says so, and leaves the focus in the form (259ms)
  3 passed (3.9s)
```

The text is visible as well: a line under the form saying what was just added is useful to everybody, and
a message only a screen reader can hear is one nobody else can check.
