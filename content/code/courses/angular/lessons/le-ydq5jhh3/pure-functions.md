---
title: The arithmetic, tested on its own
version: 1
---

**`planner.ts` holds plain functions, and a plain function is tested by calling it.** `weekOf`
decides which days are "this week", `totals` adds up the minutes, and `parsePlanner` decides what
counts as an answer from the server. Every screen of the planner rests on those three, and none of
them knows Angular exists, so neither does their test:

```typescript
// src/app/planner.spec.ts
import { Session, parsePlanner, totals, weekOf } from './planner';

const session = (id: number, date: string, minutes: number, done: boolean): Session => ({
  id,
  courseId: 'git',
  date,
  minutes,
  done,
});

describe('weekOf', () => {
  it('starts on the Monday and ends on the Sunday', () => {
    expect(weekOf('2026-10-23')).toEqual({ start: '2026-10-19', end: '2026-10-25' });
  });

  it('puts a Sunday in the week that ends on it', () => {
    expect(weekOf('2026-10-25')).toEqual({ start: '2026-10-19', end: '2026-10-25' });
  });

  it('crosses the end of a month', () => {
    expect(weekOf('2026-10-28')).toEqual({ start: '2026-10-26', end: '2026-11-01' });
  });
});

describe('totals', () => {
  const week = { start: '2026-10-19', end: '2026-10-25' };

  it('counts what is planned and what is done, in the week only', () => {
    const sessions = [
      session(1, '2026-10-18', 45, true),
      session(2, '2026-10-19', 30, true),
      session(3, '2026-10-25', 50, false),
      session(4, '2026-10-26', 40, false),
    ];
    expect(totals(sessions, week)).toEqual({ planned: 80, done: 30 });
  });

  it('is zero for no sessions', () => {
    expect(totals([], week)).toEqual({ planned: 0, done: 0 });
  });
});

describe('parsePlanner', () => {
  it('accepts a planner', () => {
    const data = { courses: [], sessions: [session(1, '2026-10-19', 30, true)] };
    expect(parsePlanner(data)).toBe(data);
  });

  it('refuses minutes that are not a number', () => {
    const data = { courses: [], sessions: [{ ...session(5, '2026-10-24', 50, false), minutes: '50' }] };
    expect(() => parsePlanner(data)).toThrow('session 5: minutes is "50"');
  });

  it('refuses an answer with no sessions', () => {
    expect(() => parsePlanner({ courses: [] })).toThrow('no courses or no sessions');
  });
});
```

Each test is picked for a way the function could be wrong, not to touch every line:

- **the week's edges.** A Friday in the middle is the easy case. A Sunday is the one an off-by-one
  puts in the wrong week, because JavaScript's `getDay()` calls Sunday 0, the start, and the
  planner's week ends on it. A week across the end of October checks that `setDate` rolls the month.
- **the totals' edges.** Sessions on the first and the last day of the week count, the days just
  outside do not, and a session is planned whether or not it is done.
- **the refusals, with their words.** `toThrow` with a piece of the message checks that the error
  says which session and which field, which is what lesson 12 made it say so a person could act on
  it.

`session(...)` at the top is a helper that builds a session from the four values a test cares
about. Tests are code, and the same rule about not repeating yourself applies; what a reader should
see in each test is only what makes it different.

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E '✓|Tests '
 ✓ |planner| src/app/planner.spec.ts (8 tests) 8ms
 ✓ |planner| src/app/week-summary/week-summary.spec.ts (1 test) 51ms
 ✓ |planner| src/app/autofocus.spec.ts (1 test) 12ms
 ✓ |planner| src/app/app.spec.ts (2 tests) 99ms
 ✓ |planner| src/app/planner-store.spec.ts (1 test) 8ms
 ✓ |planner| src/app/minutes-pipe.spec.ts (4 tests) 2ms
 ✓ |planner| src/app/week/week.spec.ts (1 test) 95ms
      Tests  18 passed (18)
```

## A test that has never failed has not been tested

Eight passing tests say the code agrees with them today. To know that they would notice a mistake,
make one. Weeks that start on Sunday are a real convention, and a plausible slip:

```
ana@dev:~/planner$ sed -i 's/(date.getDay() + 6) % 7/date.getDay()/' src/app/planner.ts
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E '✓|❯|×|Tests '
❯ Building...
 ✓ |planner| src/app/week-summary/week-summary.spec.ts (1 test) 64ms
 ✓ |planner| src/app/autofocus.spec.ts (1 test) 18ms
 ❯ |planner| src/app/planner.spec.ts (8 tests | 3 failed) 20ms
     × starts on the Monday and ends on the Sunday 10ms
     × puts a Sunday in the week that ends on it 2ms
     × crosses the end of a month 2ms
     ✓ counts what is planned and what is done, in the week only 1ms
     ✓ is zero for no sessions 1ms
     ✓ accepts a planner 1ms
     ✓ refuses minutes that are not a number 2ms
     ✓ refuses an answer with no sessions 1ms
 ✓ |planner| src/app/app.spec.ts (2 tests) 100ms
 ✓ |planner| src/app/minutes-pipe.spec.ts (4 tests) 3ms
 ✓ |planner| src/app/planner-store.spec.ts (1 test) 14ms
 ❯ |planner| src/app/week/week.spec.ts (1 test | 1 failed) 130ms
     × counts the week that holds today 128ms
⎯⎯⎯⎯⎯⎯⎯ Failed Tests 4 ⎯⎯⎯⎯⎯⎯⎯
 ❯ src/app/planner.spec.ts:14:34
 ❯ src/app/planner.spec.ts:18:34
 ❯ src/app/planner.spec.ts:22:34
 ❯ src/app/week/week.spec.ts:16:18
      Tests  4 failed | 14 passed (18)
```

Four tests failed: the three about `weekOf`, which between them name the problem, every week now
starting a day early; and `Week`'s own test from lesson 10, which checks the same rule from much
further away, through a rendered page, and can only say that a date range is not the one it
expected. The screens would have shown it too, but only to somebody who knew which dates to look
for. Put the line back:

```
ana@dev:~/planner$ git checkout -- src/app/planner.ts
```
