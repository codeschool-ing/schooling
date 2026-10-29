---
title: Rendering a component in a test
version: 1
---

**`render` from `svelte/server` runs a component the way the server does and returns its HTML**, which a
test can read. It needs nothing installed beyond Svelte, and it suits a component whose job is to show
something. Save this as `src/lib/WeekTotal.test.ts`:

```schooling-example
{"language": "typescript", "file": "src/lib/WeekTotal.test.ts", "parts": [
 {"code": "// WeekTotal.test.ts: what the component renders, on the server, for a few totals.\nimport { expect, test } from 'vitest';\nimport { render } from 'svelte/server';\nimport WeekTotal from '#lib/WeekTotal.svelte';\n"},
 {"code": "test('ninety minutes is an hour and a half', () => {\n\tconst { body } = render(WeekTotal, { props: { minutes: 90 } });\n\texpect(body).toContain('90 minutes this week (1 h 30 min)');\n});\n\ntest('the label replaces \"this week\"', () => {\n\tconst { body } = render(WeekTotal, { props: { minutes: 45, label: 'for Guitar this week' } });\n\texpect(body).toContain('45 minutes for Guitar this week (0 h 45 min)');\n});", "note": "`body` is the HTML the component produced. The props go in as they would from a parent."}
]}
```

```
ana@dev:~/planner$ npm run test:unit 2>&1 | tail -6

 Test Files  4 passed (4)
      Tests  22 passed (22)
   Start at  22:34:23
   Duration  1.26s (transform 74%, import 21%, tests 3%, worker 2%)
```

What this cannot test is anything that happens after the HTML exists: a click, a form sent, a
transition, a focus that moves. Vitest can run tests in a real browser too, with a package for that and
some setup, and for components that are mostly about interaction that is the next step. For the
planner, the interactions that matter are whole journeys, a person adding a session and seeing the week
change, and those are what the next section tests, in the whole application at once.
