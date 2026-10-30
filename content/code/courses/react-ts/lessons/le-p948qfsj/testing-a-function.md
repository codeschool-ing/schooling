---
title: The simplest test, a function
version: 1
---

**The cheapest code to test is code with no React in it.** `src/week.ts` is lesson 3's date arithmetic:
pure functions, a string in and a string out. Its tests, `src/week.test.ts`:

```ts
import { describe, expect, it } from 'vitest'
import type { Session } from './types'
import { addDays, inWeek, minutes, mondayOf } from './week'

describe('week', () => {
  it('finds the Monday of any day of the week', () => {
    expect(mondayOf('2026-10-19')).toBe('2026-10-19')
    expect(mondayOf('2026-10-21')).toBe('2026-10-19')
    expect(mondayOf('2026-10-25')).toBe('2026-10-19')
  })

  it('moves across the end of a month', () => {
    expect(addDays('2026-10-26', 7)).toBe('2026-11-02')
  })

  it('counts Sunday in the week and the next Monday out of it', () => {
    expect(inWeek('2026-10-25', '2026-10-19')).toBe(true)
    expect(inWeek('2026-10-26', '2026-10-19')).toBe(false)
  })

  it('adds up the minutes of some sessions', () => {
    const sessions = [{ minutes: 50 }, { minutes: 40 }] as Session[]
    expect(minutes(sessions)).toBe(90)
    expect(minutes([])).toBe(0)
  })
})
```

- **`describe`** groups tests under a name; **`it`** is one test, named by what it checks, in a
  sentence that reads as a fact about the code.
- **`expect(value).toBe(expected)`** compares with `Object.is`, the same comparison as lesson 4's state
  and lesson 21's `memo`.
- **The cases are the edges**: the Monday itself, the Sunday at the other end of the week, a week that
  crosses into November. Those are where date code goes wrong, and lesson 3 chose noon UTC precisely to
  keep them right.
- `as Session[]` lets the last test pass objects with only `minutes`, the one field `minutes()` reads.

Vitest finds every file ending in `.test.ts` or `.test.tsx`:

```
ana@dev:~/planner$ npm test

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner

 ✓ src/week.test.ts (4 tests) 5ms

 Test Files  1 passed (1)
      Tests  4 passed (4)
   Start at  23:15:57
   Duration  1.29s (environment 58%, transform 27%, setup 14%, import 1%)
```

Four tests in one file, all passing. The `Duration` line says where the time went; most of it is
starting the environment, not running the tests.
