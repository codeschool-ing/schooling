---
title: Typing like a person types
version: 1
---

**`user-event` produces the events a real person produces, in the order a browser produces them.**
`user.type(field, "15")` focuses the field, then sends `keydown`, `keypress`, `input` and `keyup` for
the `1`, and again for the `5`. `user.click(button)` moves the pointer over it, presses, releases and
clicks. Lesson 2 set `.value` and called `requestSubmit()`, which skips every one of those events.

Most of the time both give the same result, and the difference shows when it matters most. Here is
what each approach does with a button that is disabled, set up for the purpose in a scratch test
(save it as `src/scratch.test.ts`, run it, and delete it):

```typescript
// src/scratch.test.ts
// @vitest-environment jsdom
import { expect, test } from "vitest";
import { screen } from "@testing-library/dom";
import userEvent from "@testing-library/user-event";

test("a disabled button cannot be clicked by a person", async () => {
  let clicks = 0;
  document.body.innerHTML = '<button disabled>Add session</button>';
  const button = screen.getByRole("button", { name: "Add session" });
  button.addEventListener("click", () => clicks++);

  button.click();
  expect(clicks).toBe(0);

  await userEvent.setup().click(button);
  expect(clicks).toBe(0);
});

test("a button covered by pointer-events: none cannot be clicked either", async () => {
  document.body.innerHTML = '<button style="pointer-events: none">Add session</button>';
  const button = screen.getByRole("button", { name: "Add session" });
  await expect(userEvent.setup().click(button)).rejects.toThrow("pointer-events");
});
```

```
ana@dev:~/planner$ npx vitest run src/scratch.test.ts

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  2 passed (2)
   Start at  19:53:24
   Duration  1.08s (environment 70%, tests 17%, import 8%, transform 5%)

ana@dev:~/planner$ rm src/scratch.test.ts
```

The first test shows the two agreeing: a disabled button ignores `.click()` and `user.click` alike.
The second shows where they part. A button with `pointer-events: none` cannot receive a click from a
mouse, and `user.click` **refuses to pretend**: it throws, and says which style is in the way. A
plain `.click()` would have run the handler, and the test would have passed for a button nobody can
press.

## The rules that follow

- **Start each test with `userEvent.setup()`** and use the object it returns, as the planner's tests
  do; it keeps the state of the keyboard and the pointer for that test.
- **Every `user.…` call is `async`**, so `await` it. A forgotten `await` lets the test read the page
  before the typing has happened, and pass or fail by timing.
- **`user.keyboard("{Enter}")`, `user.tab()` and `user.hover()`** are the rest of a person's hands.
  Lesson 11 uses `user.tab()` to walk the page with the keyboard alone.

What `user-event` still cannot know is layout. jsdom computes none, so a button hidden behind
another element by CSS positioning is clickable here and not in a browser. That remains lesson 4's.
