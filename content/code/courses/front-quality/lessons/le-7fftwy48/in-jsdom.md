---
title: The same questions in a unit test
version: 1
---

**Testing Library's `user-event` presses keys too, so part of this lesson can be tested in Vitest,
without a browser.** `user.tab()` moves the focus the way Tab would, and `user.keyboard("{Enter}")`
presses a key on whatever has it. Add a test to `src/view.test.ts`:

```typescript
// src/view.test.ts, below what is there
test("Done, pressed from the keyboard, leaves the focus on its session", async () => {
  const user = userEvent.setup();
  show("#/course/javascript");
  await user.tab();
  await user.tab();
  expect(screen.getByRole("button", { name: "Done" })).toHaveFocus();
  await user.keyboard("{Enter}");
  expect(screen.getByText("2026-10-22 · 30 min")).toHaveFocus();
});
```

```
ana@dev:~/planner$ npx vitest run src/view.test.ts

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  5 passed (5)
   Start at  21:08:14
   Duration  1.40s (environment 49%, tests 37%, import 8%, transform 6%)

ana@dev:~/planner$ git commit -qam "Test in jsdom that Done keeps the focus"
```

It passes at once, because the fix is already in `src/view.ts`; written first, it is the test that would
have found the lost focus in a second and a half, before a browser was opened.

## What jsdom can and cannot be asked

jsdom keeps track of the focus exactly as the DOM says: which element has it, which elements can take it,
`tabindex` and all. **It draws nothing.** There is no layout, so nothing is ever hidden or covered; the
planner's stylesheet is not even loaded in a unit test, so there is no outline to measure; and a date
field is one element and one stop, where Chromium makes it four. The questions split cleanly:

| the question | jsdom | a real browser |
|---|---|---|
| where does the focus land after an action? | yes | yes |
| which elements does Tab reach, in what order? | the DOM's order, yes | yes, with the browser's own stops |
| can the focused element be seen? | no | yes |
| is it covered by something else? | no | yes |

The unit test is fast and runs on every save, so it is the one that catches a lost focus first. The
Playwright test is the one that can say the ring is there to see.
