---
title: Stand-ins for what a test cannot control
version: 1
---

**A test controls its inputs, and two of the planner's inputs are not arguments: what the page does
with a new plan, and what time it is.** Vitest replaces both with stand-ins the test owns, and that
is all a mock is.

## A function that records its calls

`render` does not keep a new plan; it hands it to `update` and lets the caller decide. In the second
component test, `update` was `vi.fn()`, a function that does nothing except remember how it was
called. `update.mock.calls[0][0]` is the first argument of the first call: the plan `render` handed
over when Done was clicked.

Notice what that test asserted. Not that `markDone` was called, which is how `view.ts` happens to do
it today, but **what came out**: a plan in which session 4 is done. The mock is a way to read the
output of a function whose output is a call, and the advice of lesson 1 still holds through it.

## A clock the test sets

`today()` reads the computer's clock, so a test of it would have a different answer every day. Vitest
can stop the clock and set it. Save this as `src/today.test.ts`:

```typescript
// src/today.test.ts
import { afterEach, expect, test, vi } from "vitest";
import { today } from "./planner";

afterEach(() => {
  vi.useRealTimers();
});

test("today is the date on the student's own calendar", () => {
  vi.useFakeTimers();
  vi.setSystemTime(new Date("2026-10-22T22:30:00-03:00"));
  expect(today()).toBe("2026-10-22");
});

test("late in the evening it is still today, though UTC is already tomorrow", () => {
  vi.useFakeTimers();
  vi.setSystemTime(new Date("2026-10-22T23:59:00-03:00"));
  expect(new Date().toISOString().slice(0, 10)).toBe("2026-10-23");
  expect(today()).toBe("2026-10-22");
});
```

`vi.useFakeTimers()` replaces `Date` and the timers with ones Vitest drives, and `setSystemTime`
says what `new Date()` returns from then on. `afterEach` puts the real clock back, so no other test
inherits a stopped one. The second test pins down why `today()` exists at all: the obvious one-liner,
`toISOString().slice(0, 10)`, gives the UTC date, which in São Paulo turns into tomorrow at nine every
evening.

```
ana@dev:~/planner$ npx vitest run src/today.test.ts

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  2 passed (2)
   Start at  19:31:33
   Duration  201ms (transform 73%, import 15%, tests 8%, worker 4%)
```

This file depends on the time zone on purpose, like the code it tests: `today()` is meant to follow
the machine's own calendar. It was recorded with `TZ=America/Sao_Paulo`, which the dates in it say
out loud with `-03:00`. **A test that is about a time zone should name it**, in the data, so that
somebody reading the failure on another machine knows why.

## When not to mock

Each stand-in is a place where the test stops being about the real thing. Mocking `weekTotal` inside a
test of `view.ts` would make the test faster by nothing and blind to the defect the first test found.
Replace what the test cannot control, the clock, the network, a random number, and leave the rest
real.
