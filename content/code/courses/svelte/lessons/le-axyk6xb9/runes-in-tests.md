---
title: Testing a class with runes
version: 1
---

**A file that uses runes has to go through the Svelte compiler, and a test is no exception.** The
planner class is in `planner.svelte.ts` for that reason, and a test that wants `$state` of its own is
named the same way, `.svelte.test.ts`. Save this as `src/lib/planner.svelte.test.ts`:

```schooling-example
{"language": "typescript", "file": "src/lib/planner.svelte.test.ts", "parts": [
 {"code": "// planner.svelte.test.ts: the planner's totals, worked out from data the test controls.\nimport { expect, test } from 'vitest';\nimport { Planner, type PlannerSource } from '#lib/planner.svelte.js';\n"},
 {"code": "function source(): PlannerSource {\n\treturn {\n\t\tcourses: [\n\t\t\t{ id: 'algebra', name: 'Linear algebra' },\n\t\t\t{ id: 'guitar', name: 'Guitar' }\n\t\t],\n\t\tsessions: [\n\t\t\t{ id: 1, course: 'algebra', date: '2026-10-13', minutes: 60, done: true },\n\t\t\t{ id: 2, course: 'algebra', date: '2026-10-19', minutes: 90, done: true },\n\t\t\t{ id: 3, course: 'guitar', date: '2026-10-20', minutes: 45, done: false }\n\t\t],\n\t\tweek: '2026-10-19'\n\t};\n}\n", "note": "A fresh copy of the data for each test, so that no test can change what another one sees."},
 {"code": "test('the totals count only the sessions in the week', () => {\n\tconst planner = new Planner(() => source());\n\texpect(planner.total).toBe(135);\n\texpect(planner.doneMinutes).toBe(90);\n\texpect(planner.byCourse).toEqual({ algebra: 90, guitar: 45 });\n});\n", "note": "The planner is given a function that returns plain data, exactly as `PlannerProvider` gives it one. The deriveds work it out when they are read, as they would in a page."},
 {"code": "test('the totals follow the data when it changes', () => {\n\tlet data = $state(source());\n\tconst planner = new Planner(() => data);\n\texpect(planner.total).toBe(135);\n\n\tdata.week = '2026-10-12';\n\texpect(planner.total).toBe(60);\n});", "note": "`$state` in the test makes the data reactive, as `data` is in a component. Changing the week, the way a new address does, changes the total, with no component anywhere."}
]}
```

```
ana@dev:~/planner$ npm run test:unit 2>&1 | tail -6

 Test Files  3 passed (3)
      Tests  20 passed (20)
   Start at  22:34:20
   Duration  837ms (transform 82%, import 12%, tests 4%, worker 2%)
```

The second test is the property lesson 14 rebuilt the planner for: it reads its data rather than copying
it, so when the data changes, the totals follow. Lesson 14 checked that by clicking in a browser, once.
This test checks it every time the tests run, in milliseconds, without a browser.
