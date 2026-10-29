---
title: Two fixes, and the test green
version: 1
---

**Each finding has a fix of one line, and each fix is a decision, not a way of silencing axe.**

**The icons are decoration.** Each sits beside the course's name, inside the same link, and says nothing
the name does not: a screen reader reading *book.svg, HTML and CSS* tells the person less than one reading
*HTML and CSS*. A decorative image is marked with an **empty** `alt`, which says "skip me" and is not the
same as no `alt` at all. Lesson 12 is about the difference between the two kinds of image and how to tell
which is which.

**The grey of a done session is too pale.** `#6b6b6b` is still clearly lighter than the planner's
ordinary text and reaches 5.33:1 on white, past the 4.5 AA asks for. Lesson 13 works out ratios like these
by hand and puts the arithmetic in a test of its own.

```
ana@dev:~/planner$ git diff src
diff --git a/src/style.css b/src/style.css
index d3d4775..ada6bc6 100644
--- a/src/style.css
+++ b/src/style.css
@@ -5,7 +5,7 @@ ul { padding: 0; list-style: none; }
 li { padding: 0.4rem 0; border-bottom: 1px solid #ddd; }
 .courses img { vertical-align: middle; margin-right: 0.4rem; }
 .mins { color: #555; }
-.session.done { color: #aaa; }
+.session.done { color: #6b6b6b; }
 .tick { font-size: 0.7rem; padding: 1px 4px; }
 button:focus { outline: none; }
 .add { display: flex; gap: 0.5rem; margin: 1rem 0; }
diff --git a/src/view.ts b/src/view.ts
index 0a81f3f..44588f5 100644
--- a/src/view.ts
+++ b/src/view.ts
@@ -12,6 +12,7 @@ export function render(root: HTMLElement, plan: Plan, day: string, route: string
       link.href = `#/course/${c.id}`;
       const icon = el("img");
       icon.src = "/book.svg";
+      icon.alt = "";
       link.prepend(icon);
       const item = el("li");
       item.append(link, el("span", ` ${weekTotal(plan, day, c.id)} min this week`, "mins"));
```

```
ana@dev:~/planner$ npx playwright test e2e/a11y.spec.ts --reporter=list

Running 2 tests using 1 worker

  ✓  1 [chromium] › e2e/a11y.spec.ts:12:3 › the course list breaks no WCAG 2.2 AA rule axe can check (1.2s)
  ✓  2 [chromium] › e2e/a11y.spec.ts:12:3 › a course page breaks no WCAG 2.2 AA rule axe can check (1.0s)

  2 passed (5.4s)
```

**Both pages pass, and the report agrees:**

```
ana@dev:~/planner$ node server/axe.mjs http://localhost:5173/ 'http://localhost:5173/#/course/javascript'
http://localhost:5173/: 0 rule(s) broken
http://localhost:5173/#/course/javascript: 0 rule(s) broken
```

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "axe at WCAG 2.2 AA: decorative icons, and a done grey that reads"
```

## What the test now promises

That no rule axe can check at WCAG 2.2 AA is broken on these two pages, in this state, today. Each part
of that sentence is a limit. Other states, a course with no sessions or a form showing an error, are other
pages to axe, and lesson 12 adds one. And "rules axe can check" is the largest limit of all, which is the
next section.
