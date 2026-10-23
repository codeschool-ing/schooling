---
title: The first test, and it is red
version: 1
---

**A unit test calls a function with values it chose and compares what came back with what it
expected.** `planner.ts` is made of exactly that kind of function, so its first tests need nothing
but the data. Save this as `src/planner.test.ts`:

```typescript
// src/planner.test.ts
import { describe, expect, test } from "vitest";
import { addSession, markDone, weekOf, weekTotal, type Plan } from "./planner";
import data from "../public/courses.json";

const plan: Plan = data;

describe("weekOf", () => {
  test("a Wednesday's week runs from the Monday before to the Sunday after", () => {
    expect(weekOf("2026-10-21")).toEqual(["2026-10-19", "2026-10-25"]);
  });
});

describe("weekTotal", () => {
  test("adds every session of the week, done or not", () => {
    expect(weekTotal(plan, "2026-10-21")).toBe(160);
  });

  test("can be limited to one course", () => {
    expect(weekTotal(plan, "2026-10-21", "javascript")).toBe(90);
  });
});
```

`describe` groups tests under a name, `test` is one test, and `expect(value)` starts an assertion.
`toBe` compares with `===`, which is right for a number; `toEqual` compares contents, which is what
an array needs, since two arrays with the same items are still two different arrays. The data is
the planner's own file, imported directly, so the test and the app read the same six sessions.

The numbers were worked out by hand, from the file, before the test ran: Monday 19 to Sunday 25
October holds 45, 60, 30 and 25 minutes, which is 160, and the JavaScript sessions in it are 60 and
30. **Work the expected value out yourself.** A number copied from what the code printed is a test
that the code agrees with itself.

```
ana@dev:~/planner$ npm test

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner

 ❯ src/planner.test.ts (3 tests | 2 failed) 11ms
   ❯ weekOf (1)
     × a Wednesday's week runs from the Monday before to the Sunday after 8ms
   ❯ weekTotal (2)
     × adds every session of the week, done or not 1ms

⎯⎯⎯⎯⎯⎯⎯ Failed Tests 2 ⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/planner.test.ts > weekOf > a Wednesday's week runs from the Monday before to the Sunday after
AssertionError: expected [ '2026-10-20', '2026-10-26' ] to deeply equal [ '2026-10-19', '2026-10-25' ]

- Expected
+ Received

  [
-   "2026-10-19",
-   "2026-10-25",
+   "2026-10-20",
+   "2026-10-26",
  ]

 ❯ src/planner.test.ts:10:34
      8| describe("weekOf", () => {
      9|   test("a Wednesday's week runs from the Monday before to the Sunday a…
     10|     expect(weekOf("2026-10-21")).toEqual(["2026-10-19", "2026-10-25"]);
       |                                  ^
     11|   });
     12| });

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/2]⎯

 FAIL  src/planner.test.ts > weekTotal > adds every session of the week, done or not
AssertionError: expected 155 to be 160 // Object.is equality

- Expected
+ Received

- 160
+ 155

 ❯ src/planner.test.ts:16:43
     14| describe("weekTotal", () => {
     15|   test("adds every session of the week, done or not", () => {
     16|     expect(weekTotal(plan, "2026-10-21")).toBe(160);
       |                                           ^
     17|   });
     18|

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[2/2]⎯


 Test Files  1 failed (1)
      Tests  2 failed | 1 passed (3)
   Start at  19:31:26
   Duration  213ms (transform 68%, import 15%, tests 13%, worker 4%)
```

**Two of three fail**, and the report says how. `weekOf` gave Tuesday 20 to Monday 26 instead of
Monday 19 to Sunday 25: the whole week is one day late. The total is 155 instead of 160, which is
the same mistake seen from outside, since a week one day late loses Monday's 45 minutes and gains
next Monday's 40. Only the JavaScript total passes, and by luck: its sessions are on a Tuesday and a
Thursday, safely inside either week.

That is a defect that has been in the planner since lesson 1, and every total the page showed was
wrong. Nothing on the screen said so. The next section finds out why.
