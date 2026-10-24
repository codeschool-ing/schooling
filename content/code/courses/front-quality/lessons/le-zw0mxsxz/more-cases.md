---
title: More cases, and the ones at the edges
version: 1
---

**A function with a rule in it deserves a test at each edge of the rule**, and one test of the
middle tells you very little. `weekOf` has seven days to get right, `addSession` has four reasons
to refuse, and both promise to leave the plan they were given alone. Add these to the end of
`src/planner.test.ts`:

```typescript
// src/planner.test.ts, below what is there
describe("weekOf, on every day of one week", () => {
  test.each(["2026-10-19", "2026-10-20", "2026-10-21", "2026-10-22", "2026-10-23", "2026-10-24", "2026-10-25"])(
    "%s is in the week of 19 October",
    (day) => {
      expect(weekOf(day)).toEqual(["2026-10-19", "2026-10-25"]);
    },
  );

  test("the week crosses into another month", () => {
    expect(weekOf("2026-11-01")).toEqual(["2026-10-26", "2026-11-01"]);
  });
});

describe("addSession", () => {
  test("gives the new session the next id, not done", () => {
    const next = addSession(plan, "git", "2026-10-23", 30);
    expect(next.sessions.at(-1)).toEqual({ id: 7, course: "git", date: "2026-10-23", minutes: 30, done: false });
  });

  test("leaves the plan it was given as it was", () => {
    const before = structuredClone(plan);
    addSession(plan, "git", "2026-10-23", 30);
    expect(plan).toEqual(before);
  });

  test.each([0, 601, 2.5, Number.NaN])("refuses %s minutes", (minutes) => {
    expect(() => addSession(plan, "git", "2026-10-23", minutes)).toThrow("minutes must be");
  });

  test("refuses a course that does not exist", () => {
    expect(() => addSession(plan, "rust", "2026-10-23", 30)).toThrow("no course rust");
  });

  test("refuses a date it cannot read", () => {
    expect(() => addSession(plan, "git", "23/10/2026", 30)).toThrow("not a date");
  });
});

describe("markDone", () => {
  test("marks that session and no other", () => {
    const next = markDone(plan, 4);
    expect(next.sessions.filter((s) => s.done).map((s) => s.id)).toEqual([1, 2, 3, 4]);
  });
});
```

`test.each` runs the same test once per value, and `%s` puts the value in the name, so each of the
seven days fails on its own line if it fails. `toThrow` takes a part of the message and passes if
the error contains it, which is enough to tell the four refusals apart. `structuredClone` makes a
deep copy, and `.at(-1)` is the last session.

The values were chosen, not sampled. `0` and `601` sit just outside 1 to 600, and `0` is also what
`Number("")` gives, which is what the form sends when the field is left empty. `2.5` is in range and
not a whole number, and `NaN` is what `Number` makes of text that is not a number at all. **One value just outside each boundary finds an off-by-one; a
value in the middle finds nothing.**

```
ana@dev:~/planner$ npx vitest run src/planner.test.ts

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  20 passed (20)
   Start at  19:52:51
   Duration  179ms (transform 51%, import 25%, tests 17%, worker 7%)
```

Twenty tests, in a fraction of a second, and each name says what the planner promises.
