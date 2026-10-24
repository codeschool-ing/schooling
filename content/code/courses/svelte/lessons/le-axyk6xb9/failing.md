---
title: A test that fails
version: 1
---

**A test earns its keep on the day it fails.** The check that every session passes through, from forms
and from the API, is the next thing to pin down. Save this as `src/lib/server/check.test.ts`:

```schooling-example
{"language": "typescript", "file": "src/lib/server/check.test.ts", "parts": [
 {"code": "// check.test.ts: what problemWith accepts and refuses.\nimport { expect, test } from 'vitest';\nimport { problemWith } from '#lib/server/check.js';\n\ntest('a session with a date and a sensible length has no problem', () => {\n\texpect(problemWith({ date: '2026-10-21', minutes: 30 })).toBeUndefined();\n});\n"},
 {"code": "test.each([\n\t[{ date: '', minutes: 30 }, 'The session needs a date.'],\n\t[{ date: '2026-02-31', minutes: 30 }, 'The session needs a date.'],\n\t[{ date: '2026-10-21', minutes: 4 }, 'Minutes must be a whole number from 5 to 600.'],\n\t[{ date: '2026-10-21', minutes: 601 }, 'Minutes must be a whole number from 5 to 600.'],\n\t[{ date: '2026-10-21', minutes: 22.5 }, 'Minutes must be a whole number from 5 to 600.'],\n\t[{ date: '2026-10-21', minutes: '30' }, 'Minutes must be a whole number from 5 to 600.']\n])('%j is refused', (session, problem) => {\n\texpect(problemWith(session)).toBe(problem);\n});", "note": "Each refusal the check makes is a row, and the last row is the one lesson 18 was about: minutes that arrive as text."}
]}
```

```
ana@dev:~/planner$ npm run test:unit

> planner@0.0.1 test:unit
> vitest run


 RUN  v5.0.5 /home/ana/planner

 ✓ src/lib/server/check.test.ts (7 tests) 5ms
 ✓ src/lib/week.test.ts (11 tests) 21ms

 Test Files  2 passed (2)
      Tests  18 passed (18)
   Start at  22:34:17
   Duration  193ms (transform 45%, import 23%, tests 22%, worker 10%)
```

Now break something, the way it happens: a small edit for a good reason, with a consequence nobody
thought of. Suppose somebody decides a week should include the following Monday, and changes `<` to
`<=` in `inWeek`:

```
ana@dev:~/planner$ sed -i 's/date < addDays(monday, 7)/date <= addDays(monday, 7)/' src/lib/week.ts
```

```
ana@dev:~/planner$ npm run test:unit 2>&1 | grep -B2 -A12 FAIL
⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/lib/week.test.ts > inWeek includes the Sunday and not the next Monday
AssertionError: expected true to be false // Object.is equality

- Expected
+ Received

- false
+ true

 ❯ src/lib/week.test.ts:25:45
     23| test('inWeek includes the Sunday and not the next Monday', () => {
     24|  expect(inWeek('2026-10-25', '2026-10-19')).toBe(true);
     25|  expect(inWeek('2026-10-26', '2026-10-19')).toBe(false);
```

**One test fails, and its name says what broke**: the Monday after the week now counts in it. The
output shows the line that failed, what it expected and what it got. In the planner itself, every
Monday's sessions would have been counted in two weeks, and the week's total would have been wrong in
a way that looks plausible. Put the line back:

```
ana@dev:~/planner$ sed -i 's/date <= addDays(monday, 7)/date < addDays(monday, 7)/' src/lib/week.ts
```

The test did not know what the change was for. It knew what was true before, and said that it no longer
was, which is all a test can do and almost always enough.
