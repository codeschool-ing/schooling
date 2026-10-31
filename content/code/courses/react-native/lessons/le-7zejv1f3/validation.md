---
title: Validation, with a sentence for each refusal
version: 1
---

**Validation is a function from a draft to its errors**, and it belongs in a file of its own, where it
can be tested without a screen. The planner's says what is wrong with each field in words a person can
act on. Save this as `src/validate.ts`:

```typescript
// src/validate.ts: what the form refuses, and the sentence it gives for each refusal.
export type Draft = { date: string; minutes: string };
export type Errors = Partial<Record<keyof Draft, string>>;

export function validate({ date, minutes }: Draft): Errors {
  const errors: Errors = {};
  const d = new Date(`${date}T12:00:00Z`);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || Number.isNaN(d.getTime()) || d.toISOString().slice(0, 10) !== date) {
    errors.date = "Write the date as YYYY-MM-DD, for example 2026-10-23.";
  }
  const n = Number(minutes);
  if (minutes.trim() === "" || !Number.isInteger(n)) errors.minutes = "Write the minutes as a whole number.";
  else if (n < 5 || n > 240) errors.minutes = "A session is between 5 and 240 minutes.";
  return errors;
}
```

`Errors` holds at most one sentence per field. An empty object means the draft is good.

**The date is checked by round trip, not only by pattern.** `2026-02-30` matches `\d{4}-\d{2}-\d{2}`,
and JavaScript's `Date` quietly turns it into the 2nd of March. Parsing the date and writing it back
catches that: what comes back is not what went in.

**The minutes have two sentences**, because "not a whole number" and "not between 5 and 240" are two
different mistakes with two different fixes. A message that said only *invalid* would leave the person
guessing which.

## Tested, each refusal

`test.each` runs one test per row of a table, which suits a validator exactly. Save this as
`__tests__/validate.test.ts`:

```typescript
// __tests__/validate.test.ts: each refusal, and its sentence.
import { validate } from "../src/validate";

test("a good draft has no errors", () => {
  expect(validate({ date: "2026-10-23", minutes: "25" })).toEqual({});
});

test.each([
  ["23/10/2026", "25", "date"],
  ["2026-02-30", "25", "date"],
  ["2026-10-23", "", "minutes"],
  ["2026-10-23", "2.5", "minutes"],
  ["2026-10-23", "300", "minutes"],
])("date %s and minutes %s are refused for %s", (date, minutes, field) => {
  expect(Object.keys(validate({ date, minutes }))).toEqual([field]);
});
```

```
ana@dev:~/planner$ npx jest validate --forceExit
PASS __tests__/validate.test.ts
  ✓ a good draft has no errors (5 ms)
  ✓ date 23/10/2026 and minutes 25 are refused for date (2 ms)
  ✓ date 2026-02-30 and minutes 25 are refused for date (8 ms)
  ✓ date 2026-10-23 and minutes  are refused for minutes (1 ms)
  ✓ date 2026-10-23 and minutes 2.5 are refused for minutes (1 ms)
  ✓ date 2026-10-23 and minutes 300 are refused for minutes (1 ms)

Test Suites: 1 passed, 1 total
Tests:       6 passed, 6 total
Snapshots:   0 total
Time:        0.547 s, estimated 1 s
Ran all test suites matching validate.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
```

`--forceExit` ends Jest when the tests are done, which the last line reports; from this lesson on the
planner's tests are run with it, because the query client's timers otherwise keep a run open. Each row
checks that a draft is refused **for the right field and only that one**: a bad date must not
also report the minutes, or the person reads two errors for one mistake.

## When to show the errors

The planner validates when the person presses *Save*, not on every keystroke. Shouting *Write the date
as YYYY-MM-DD* after the first digit of a date is hostile. After a failed save, the errors stay until the
next save, so correcting a field does not make its message vanish half-way through. Validating as the
person leaves each field is a reasonable middle course, and the function above serves it unchanged.
