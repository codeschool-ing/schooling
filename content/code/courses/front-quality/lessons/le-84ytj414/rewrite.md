---
title: The component tests, rewritten
version: 1
---

**The three tests of lesson 2 say the same things in the new queries, and one of them now fails.**
Replace `src/view.test.ts` with this:

```typescript
// src/view.test.ts
// @vitest-environment jsdom
import { expect, test } from "vitest";
import { screen, within } from "@testing-library/dom";
import userEvent from "@testing-library/user-event";
import "@testing-library/jest-dom/vitest";
import { render } from "./view";
import type { Plan } from "./planner";
import data from "../public/courses.json";

const plan: Plan = data;

function show(route: string): void {
  document.body.innerHTML = '<div id="app"></div>';
  const root = document.querySelector<HTMLElement>("#app")!;
  let current = plan;
  const draw = () =>
    render(root, current, "2026-10-21", route, (next) => {
      current = next;
      draw();
    });
  draw();
}

test("the home page lists every course with its week", () => {
  show("");
  const items = within(screen.getByRole("list")).getAllByRole("listitem");
  expect(items.map((li) => li.textContent)).toEqual([
    "HTML and CSS 45 min this week",
    "JavaScript 90 min this week",
    "Git 25 min this week",
  ]);
  expect(screen.getByRole("link", { name: "JavaScript" })).toHaveAttribute("href", "#/course/javascript");
});

test("Done marks the session done and takes its button away", async () => {
  const user = userEvent.setup();
  show("#/course/javascript");
  await user.click(screen.getByRole("button", { name: "Done" }));
  expect(screen.queryByRole("button", { name: "Done" })).not.toBeInTheDocument();
  expect(screen.getByText("2026-10-22 · 30 min")).toHaveTextContent("done");
});

test("the form adds a session and the total follows", async () => {
  const user = userEvent.setup();
  show("#/course/javascript");
  await user.type(screen.getByLabelText("Date"), "2026-10-23");
  await user.type(screen.getByLabelText("Minutes"), "15");
  await user.click(screen.getByRole("button", { name: "Add session" }));
  expect(screen.getByText("This week: 105 min")).toBeInTheDocument();
});
```

`show` draws a page the way `main.ts` does and keeps the plan up to date, so the tests can work it
for several steps. `screen` is the whole document; `within(element)` limits the queries to one part
of it, here the list. The Done test now asserts what a person sees after the click, the session
saying *done* and no button left, rather than reading the plan out of a mock: with `show` drawing
again on every change, the page itself is the output.

```
ana@dev:~/planner$ npx vitest run src/view.test.ts 2>&1 | head -n 30

 RUN  v5.0.5 /home/ana/planner

 ❯ src/view.test.ts (3 tests | 1 failed) 195ms
   × the form adds a session and the total follows 9ms

⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/view.test.ts > the form adds a session and the total follows
TestingLibraryElementError: Unable to find a label with the text of: Date

Ignored nodes: comments, script, style
<body>
  <div
    id="app"
  >
    <a
      class="back"
      href="#/"
    >
      ←
    </a>
    <h1>
      JavaScript
    </h1>
    <ul
      class="sessions"
    >
      <li
        class="session done"
```

**The third test cannot find a field labelled *Date*, because there is none.** The report says what
it looked for, and then prints the page it looked in; the first thirty lines are above, and further
down the same dump shows why. The form's fields carry `placeholder="Date"` and
`placeholder="Minutes"`, and there is no `<label>` anywhere.
Lesson 2's test found the same fields by `name` and never noticed. The next section is about why
this is a real defect, and not a test being fussy.
