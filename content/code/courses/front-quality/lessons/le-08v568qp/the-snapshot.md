---
title: Holding the tree in a test
version: 1
---

**Here is the course page as the browser now describes it**, from the same program as before:

```
ana@dev:~/planner$ node server/tree.mjs 'http://localhost:5173/#/course/javascript'
http://localhost:5173/#/course/javascript
- main:
  - link "All courses":
    - /url: "#/"
  - heading "JavaScript" [level=1]
  - list:
    - listitem: 2026-10-20 · 60 min done
    - listitem:
      - text: 2026-10-22 · 30 min
      - button "Done"
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes"
  - text: Note
  - textbox "Note"
  - button "Add session"
  - paragraph: "This week: 90 min"
  - status
```

The back link is *All courses*, everything sits inside `main`, and the status line is there, empty and
waiting. **Playwright can hold this whole shape in one assertion**, `toMatchAriaSnapshot`, which compares
a part of the page with a template in the same YAML. Add a last test to `e2e/screen-reader.spec.ts`:

```typescript
// e2e/screen-reader.spec.ts, below what is there
test("a course page reads as it should", async ({ page }) => {
  await page.goto("/#/course/javascript");
  await expect(page.getByRole("main")).toMatchAriaSnapshot(`
    - link "All courses"
    - heading "JavaScript" [level=1]
    - list:
      - listitem: 2026-10-20 · 60 min done
      - listitem:
        - text: 2026-10-22 · 30 min
        - button "Done"
    - textbox "Date"
    - spinbutton "Minutes"
    - textbox "Note"
    - button "Add session"
    - paragraph: "This week: 90 min"
  `);
});
```

The template does not need every line: it matches when the page has these elements, in this order, with
these roles and names, and it ignores what the template leaves out, such as each link's address and the
labels' own text. **A change to a name, a role, a heading's level or the order fails it**, and the failure
prints both trees. That is the tree a person hears, held as firmly as a unit test holds a function's result.

```
ana@dev:~/planner$ npx playwright test e2e/screen-reader.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/screen-reader.spec.ts:8:1 › the back link says where it goes (249ms)
  ✓  2 [chromium] › e2e/screen-reader.spec.ts:13:1 › every page has one main landmark (199ms)
  ✓  3 [chromium] › e2e/screen-reader.spec.ts:20:1 › adding a session says so, and leaves the focus in the form (246ms)
  ✓  4 [chromium] › e2e/screen-reader.spec.ts:29:1 › a course page reads as it should (171ms)
  4 passed (4.1s)
```

And everything, both runners, before the commit:

```
ana@dev:~/planner$ npx tsc --noEmit && npx vitest run 2>&1 | grep -E "Test Files|Tests "
 Test Files  5 passed (5)
      Tests  35 passed (35)
ana@dev:~/planner$ npx playwright test 2>&1 | tail -1
  21 passed (7.6s)
```

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "What a screen reader is told: a named back link, a main landmark, a status line"
```

## What the snapshot is not

It is a record of what the tree says today, and it is only worth what was checked when it was written.
Playwright can write the template for you from the page as it is, and a template written that way, never
read, holds a mistake as firmly as it holds the right answer. Read every line of it as the screen reader
user who will hear it.
