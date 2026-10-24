---
title: A component test, in a page that is not there
version: 1
---

**`view.ts` creates elements and listens for clicks, so its tests need a document, and jsdom is
one: the DOM written in JavaScript, running in Node, with no screen behind it.** Vitest starts it for
any test file that asks. It is a separate package, and this course pins 29.1.1: jsdom 30 asks for
Node 22.22.2 or later, one patch release past the Node this course was recorded with, and npm warns
on every install about a Node it was not promised.

```
ana@dev:~/planner$ npm install --save-exact -D jsdom@29.1.1

added 38 packages, and audited 77 packages in 2s

found 0 vulnerabilities
```

Save this as `src/view.test.ts`:

```typescript
// src/view.test.ts
// @vitest-environment jsdom
import { beforeEach, expect, test, vi } from "vitest";
import { render } from "./view";
import type { Plan } from "./planner";
import data from "../public/courses.json";

const plan: Plan = data;
let root: HTMLElement;

beforeEach(() => {
  document.body.innerHTML = '<div id="app"></div>';
  root = document.querySelector<HTMLElement>("#app")!;
});

test("the home page lists every course with its week", () => {
  render(root, plan, "2026-10-21", "", () => {});
  const items = [...root.querySelectorAll(".courses li")].map((li) => li.textContent);
  expect(items).toEqual(["HTML and CSS 45 min this week", "JavaScript 90 min this week", "Git 25 min this week"]);
});

test("Done hands back a plan in which that session is done", () => {
  const update = vi.fn();
  render(root, plan, "2026-10-21", "#/course/javascript", update);
  root.querySelector<HTMLButtonElement>(".tick")!.click();
  expect(update).toHaveBeenCalledTimes(1);
  const next: Plan = update.mock.calls[0][0];
  expect(next.sessions.find((s) => s.id === 4)?.done).toBe(true);
});

test("the form adds a session and the total follows", () => {
  let current = plan;
  const draw = () =>
    render(root, current, "2026-10-21", "#/course/javascript", (next) => {
      current = next;
      draw();
    });
  draw();
  root.querySelector<HTMLInputElement>("[name=date]")!.value = "2026-10-23";
  root.querySelector<HTMLInputElement>("[name=minutes]")!.value = "15";
  root.querySelector("form")!.requestSubmit();
  expect(root.querySelector(".week")!.textContent).toBe("This week: 105 min");
});
```

The comment on the second line is read by Vitest: **`@vitest-environment jsdom` gives this file a
document**, and `planner.test.ts`, which has no such line, still runs in plain Node, where it starts
faster. `beforeEach` gives every test a fresh, empty `#app`, so no test sees what the last one drew.

The third test is the one the trophy is about. It renders the course page the way `main.ts` does,
with an `update` that keeps the new plan and draws again, then fills the two fields, submits the
form, and reads the total that was drawn as a result. **Three files' worth of wiring is under test,
and no browser was started**: `view.ts` reading the form, `addSession` accepting the values, and
`weekTotal` adding them up.

```
ana@dev:~/planner$ npx vitest run src/view.test.ts

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  3 passed (3)
   Start at  19:52:54
   Duration  833ms (environment 82%, transform 9%, tests 7%, import 2%, worker 1%)
```

## What jsdom does not do

These tests find things with CSS selectors, `.tick` and `[name=minutes]`, which is the habit lesson 1
warned about: rename a class and they break though nothing changed. Lesson 3 replaces them with
queries by what a person reads. And jsdom draws nothing: `requestSubmit()` ran the submit handler, but
nothing here could tell you the button was hidden, or the text grey on grey. **A passing component
test means the wiring works, not that the screen is usable**, and lessons 4 and 10 are where the
screen gets checked.
