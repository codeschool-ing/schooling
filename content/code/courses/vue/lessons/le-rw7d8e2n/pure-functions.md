---
title: Pure functions first
version: 1
---

**The cheapest tests in a Vue project are not about Vue at all.** Lesson 3 put the planner's rules in
`planner.ts` as plain functions, values in and values out, nothing about the page or the clock, and
said that lesson 21 would test them. Each test below gives a function an input and states the answer:

```typescript
// src/planner.test.ts: the planner's rules, checked one function at a time.
import { describe, it, expect } from 'vitest'
import { weekStart, addDays, weekTotal, addSession, toggleDone, type Session } from './planner.js'

const sessions: Session[] = [
  { id: 's1', course: 'statistics', date: '2026-10-19', minutes: 45, done: true },
  { id: 's2', course: 'spanish', date: '2026-10-21', minutes: 30, done: false },
  { id: 's3', course: 'spanish', date: '2026-10-26', minutes: 40, done: false },
]

describe('weekStart', () => {
  it('gives the Monday of the week a date falls in', () => {
    expect(weekStart(new Date(2026, 9, 21))).toBe('2026-10-19')
  })
  it('puts a Sunday in the week that began six days before', () => {
    expect(weekStart(new Date(2026, 9, 25))).toBe('2026-10-19')
  })
})

describe('addDays', () => {
  it('crosses the end of a month', () => {
    expect(addDays('2026-10-30', 3)).toBe('2026-11-02')
  })
})

describe('weekTotal', () => {
  it('adds the minutes planned and done in that week and no other', () => {
    expect(weekTotal(sessions, '2026-10-19')).toEqual({ planned: 75, done: 45 })
  })
})

describe('addSession', () => {
  it('gives the new session the next id, not yet done', () => {
    const after = addSession(sessions, { course: 'guitar', date: '2026-10-22', minutes: 20 })
    expect(after.at(-1)).toEqual({ id: 's4', course: 'guitar', date: '2026-10-22', minutes: 20, done: false })
  })
  it('leaves the list it was given as it was', () => {
    const before = structuredClone(sessions)
    addSession(sessions, { course: 'guitar', date: '2026-10-22', minutes: 20 })
    expect(sessions).toEqual(before)
  })
})

describe('toggleDone', () => {
  it('flips one session and no other', () => {
    const after = toggleDone(sessions, 's2')
    expect(after.map((s) => s.done)).toEqual([true, true, false])
  })
})
```

`describe` groups tests under a name, `it` is one test, and `expect(value)` followed by a *matcher*
states what the value must be: `toBe` for a value compared with `===`, `toEqual` for an object or a
list compared field by field. The `new Date(2026, 9, 21)` is 21 October, because JavaScript counts the
months from zero; a comment beside such a date, like the one in the week page's test later on, saves the
next reader the count.

```
ana@dev:~/vue/planner$ npx vitest run src/planner.test.ts

 RUN  v5.0.5 /home/ana/vue/planner

 ✓ src/planner.test.ts (7 tests) 6ms

 Test Files  1 passed (1)
      Tests  7 passed (7)
   Start at  22:07:11
   Duration  718ms (environment 88%, transform 8%, import 2%, tests 1%, worker 1%)
```

## A test earning its place

A test is worth what it catches. Suppose somebody tidies `weekStart`, finding `(date.getDay() + 6) % 7`
obscure, and writes what looks like the same thing:

```
ana@dev:~/vue/planner$ sed -i 's/(date.getDay() + 6) % 7/date.getDay() - 1/' src/planner.ts
ana@dev:~/vue/planner$ npx vitest run src/planner.test.ts

 RUN  v5.0.5 /home/ana/vue/planner

 ❯ src/planner.test.ts (7 tests | 1 failed) 11ms
   ❯ weekStart (2)
     ✓ gives the Monday of the week a date falls in 2ms
     × puts a Sunday in the week that began six days before 6ms
   ✓ addDays (1)
     ✓ crosses the end of a month 0ms
   ✓ weekTotal (1)
     ✓ adds the minutes planned and done in that week and no other 0ms
   ✓ addSession (2)
     ✓ gives the new session the next id, not yet done 0ms
     ✓ leaves the list it was given as it was 0ms
   ✓ toggleDone (1)
     ✓ flips one session and no other 0ms

⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/planner.test.ts > weekStart > puts a Sunday in the week that began six days before
AssertionError: expected '2026-10-26' to be '2026-10-19' // Object.is equality

Expected: "2026-10-19"
Received: "2026-10-26"

 ❯ src/planner.test.ts:16:46
     14|   })
     15|   it('puts a Sunday in the week that began six days before', () => {
     16|     expect(weekStart(new Date(2026, 9, 25))).toBe('2026-10-19')
       |                                              ^
     17|   })
     18| })

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯


 Test Files  1 failed (1)
      Tests  1 failed | 6 passed (7)
   Start at  22:07:12
   Duration  789ms (environment 91%, transform 5%, import 2%, tests 2%, worker 1%)
```

**The Sunday test fails, and says how**: `getDay()` is 0 on a Sunday, so the tidy version counts back
`-1` days, forwards to the Monday after, and puts every Sunday session into the next week. Every
weekday still works, so the planner would look right five days out of seven, and the test that says
otherwise is the one the second `it` of `weekStart` wrote down, the case somebody thought about once.
Put the line back:

```
ana@dev:~/vue/planner$ sed -i 's/date.getDay() - 1/(date.getDay() + 6) % 7/' src/planner.ts
```

Writing the test for the edge, the Sunday, the end of the month, the list left as it was, is most
of the craft. The ordinary case is there to show the function works at all.
