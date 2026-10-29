---
title: The planner's first tests
version: 1
---

**A pipeline is as good as the checks in it, and so far the planner has one: the type check.** Types
catch a session's minutes being a string. They do not catch a week that counts eight days, which is
the kind of mistake a planner actually ships. That needs a test: code that calls `weekTotal` with
sessions whose answer you worked out by hand, and fails if the answer is different.

Testing is front-quality's subject, lessons 1 to 4. This section adds the smallest useful set, because a
pipeline with no tests in it would teach the wrong lesson about what CI is for.

## Vitest

**Vitest** is a test runner built on Vite, so it reads the project's TypeScript with no configuration of
its own. Install it pinned, like everything else, and give the project a `test` script with `npm pkg`,
which edits `package.json` without opening it:

```
ana@dev:~/planner$ npm install --save-dev --save-exact vitest@5.0.5

added 20 packages, and audited 39 packages in 3s

13 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner$ npm pkg set scripts.test="vitest run"
ana@dev:~/planner$ grep -A1 "\"vitest\"\|\"test\"" package.json
    "test": "vitest run"
  },
--
    "vitest": "5.0.5"
  }
```

**Vitest 5.0.5** is in `package.json` now, and `npm test` runs it once and exits, which is what a
pipeline needs; plain `vitest` would sit and wait for changes.

## The tests

`planner.ts` has no DOM in it, which is why lesson 1 kept it that way: every function can be called and
checked without a browser. One file beside it holds the tests:

```schooling-example
{"language": "typescript", "file": "src/planner.test.ts", "parts": [
 {"code": "// src/planner.test.ts\nimport { describe, expect, test } from \"vitest\";\nimport { addSession, markDone, mondayOf, weekTotal, type Session } from \"./planner\";", "note": "Vitest finds any file ending in `.test.ts`. `test` names one case, `expect` states what must be true, and `describe` groups cases under the function they are about."},
 {"code": "\nconst sessions: Session[] = [\n  { id: 1, course: \"git\", date: \"2026-10-11\", minutes: 30, done: true },\n  { id: 2, course: \"git\", date: \"2026-10-12\", minutes: 60, done: true },\n  { id: 3, course: \"git\", date: \"2026-10-18\", minutes: 25, done: false },\n  { id: 4, course: \"git\", date: \"2026-10-19\", minutes: 45, done: false },\n];", "note": "Four sessions chosen for their edges: a Sunday before the week, its Monday, its Sunday, and the next Monday. A week is right when the middle two count and the outer two do not."},
 {"code": "\ndescribe(\"mondayOf\", () => {\n  test(\"a Monday is its own week's start\", () => {\n    expect(mondayOf(\"2026-10-12\")).toBe(\"2026-10-12\");\n  });\n  test(\"a Sunday belongs to the week before\", () => {\n    expect(mondayOf(\"2026-10-18\")).toBe(\"2026-10-12\");\n  });\n});", "note": "Sunday is the case that breaks a week starting on Monday, because `getUTCDay()` calls it day 0."},
 {"code": "\ndescribe(\"weekTotal\", () => {\n  test(\"counts Monday to Sunday, and nothing either side\", () => {\n    expect(weekTotal(sessions, \"2026-10-12\")).toEqual({ planned: 85, done: 60 });\n  });\n});", "note": "Worked out by hand: 60 + 25 planned, of which 60 done. `toEqual` compares the object's contents, not its identity."},
 {"code": "\ndescribe(\"addSession and markDone\", () => {\n  test(\"a new session takes the next id and starts not done\", () => {\n    const after = addSession(sessions, \"html-css\", \"2026-10-20\", 40);\n    expect(after.at(-1)).toEqual({ id: 5, course: \"html-css\", date: \"2026-10-20\", minutes: 40, done: false });\n    expect(sessions).toHaveLength(4);\n  });\n  test(\"marking one done leaves the others alone\", () => {\n    const after = markDone(sessions, 3);\n    expect(after.filter((s) => s.done).map((s) => s.id)).toEqual([1, 2, 3]);\n  });\n});", "note": "The last line of the first case checks that the original list did not change: the functions return new lists, and a test is how that promise stays kept."}
]}
```

```
ana@dev:~/planner$ npm test

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner

 ✓ src/planner.test.ts (5 tests) 9ms

 Test Files  1 passed (1)
      Tests  5 passed (5)
   Start at  19:52:08
   Duration  289ms (transform 69%, import 17%, tests 9%, worker 6%)
```

Five tests pass, in well under a second. **Now break the week on purpose**: one
character, `<` to `<=`, makes the end of the week inclusive, so the next Monday counts too:

```
ana@dev:~/planner$ sed -i 's/s.date < end/s.date <= end/' src/planner.ts
ana@dev:~/planner$ npm test

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner

 ❯ src/planner.test.ts (5 tests | 1 failed) 19ms
   ✓ mondayOf (2)
     ✓ a Monday is its own week's start 3ms
     ✓ a Sunday belongs to the week before 0ms
   ❯ weekTotal (1)
     × counts Monday to Sunday, and nothing either side 11ms
   ✓ addSession and markDone (2)
     ✓ a new session takes the next id and starts not done 1ms
     ✓ marking one done leaves the others alone 1ms

⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/planner.test.ts > weekTotal > counts Monday to Sunday, and nothing either side
AssertionError: expected { planned: 130, done: 60 } to deeply equal { planned: 85, done: 60 }

- Expected
+ Received

  {
    "done": 60,
-   "planned": 85,
+   "planned": 130,
  }

 ❯ src/planner.test.ts:23:47
     21| describe("weekTotal", () => {
     22|   test("counts Monday to Sunday, and nothing either side", () => {
     23|     expect(weekTotal(sessions, "2026-10-12")).toEqual({ planned: 85, d…
       |                                               ^
     24|   });
     25| });

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯


 Test Files  1 failed (1)
      Tests  1 failed | 4 passed (5)
   Start at  19:52:09
   Duration  283ms (transform 55%, tests 20%, import 18%, worker 6%)
```

The test that worked the answer out by hand caught it, and said what it expected and what it got:
130 minutes planned, because the Monday after now counts. Nothing else would have: the types are
fine, the build is fine, and the page would show a slightly wrong number every week. Put the line back
and commit the tests:

```
ana@dev:~/planner$ git checkout src/planner.ts
Updated 1 path from the index
ana@dev:~/planner$ git add package.json package-lock.json src/planner.test.ts
ana@dev:~/planner$ git commit -qm "Test the planner with Vitest"
```
