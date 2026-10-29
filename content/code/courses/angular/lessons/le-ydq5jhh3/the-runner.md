---
title: What `ng test` runs
version: 1
---

**Lesson 2 ran `ng test` once and read a failure; since then the planner has gathered spec files
without anybody choosing what they test.** Most are the ones the CLI wrote beside each generated
file, and some lessons ran them when a change broke one. This lesson writes tests on purpose, at
each of the levels an Angular application has. First, where things stand:

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | tail -14
 RUN  v4.1.12 /home/ana/planner

 ✓ |planner| src/app/minutes-pipe.spec.ts (4 tests) 5ms
 ✓ |planner| src/app/week-summary/week-summary.spec.ts (1 test) 66ms
 ✓ |planner| src/app/app.spec.ts (2 tests) 78ms
 ✓ |planner| src/app/planner-store.spec.ts (1 test) 5ms
 ✓ |planner| src/app/autofocus.spec.ts (1 test) 13ms
 ✓ |planner| src/app/week/week.spec.ts (1 test) 84ms

 Test Files  6 passed (6)
      Tests  10 passed (10)
   Start at  19:32:45
   Duration  1.35s (transform 232ms, setup 1.05s, import 309ms, tests 251ms, environment 3.64s)
```

Ten tests in six files, and most of them say little. `planner-store.spec.ts` checks that the store
"should be created"; `week-summary.spec.ts` checks the same of a component. Those are the CLI's
placeholders: they pass as long as the class can be made, and they would still pass if every
number the planner shows were wrong. The arithmetic in `planner.ts`, which every screen depends on,
has no test at all.

Without `--watch=false`, `ng test` keeps running and runs the affected specs again on every save,
which is how it is used while writing code. The transcripts here use `--watch=false` because they
end.

Three names, so they do not get mixed up:

| name | what it is |
| --- | --- |
| **Vitest** | the runner: it finds the tests, runs them, and gives `describe`, `it`, `expect` and `vi` |
| **jsdom** | a DOM written in JavaScript, so a component can render without a browser |
| **TestBed** | Angular's: it builds an injector and components inside a test, as `bootstrapApplication` does for the application |

jsdom is why the tests start in about a second: no browser opens. It is also their limit. jsdom has
elements, events and `localStorage`, but no layout: nothing has a size or a position, and nothing
is drawn. A test that needs a real browser can have one, through the `browsers` option of the test
builder and a Vitest browser provider; the planner's tests do not need one, and the `look` of lesson 2
already opens a real browser for what only a browser can tell.

The shape every test here takes is the one lesson 19 used for the `minutes` pipe. `describe` names a
group, `it` names one test, and the name is a sentence about what should be true, because that
sentence is what the report prints when it is not:

```
ana@dev:~/planner$ cat src/app/minutes-pipe.spec.ts
// src/app/minutes-pipe.spec.ts
import { MinutesPipe } from './minutes-pipe';

describe('MinutesPipe', () => {
  const pipe = new MinutesPipe();

  it('writes less than an hour in minutes', () => {
    expect(pipe.transform(50)).toBe('50 minutes');
    expect(pipe.transform(1)).toBe('1 minute');
  });

  it('writes whole hours without minutes', () => {
    expect(pipe.transform(60)).toBe('1 hour');
    expect(pipe.transform(120)).toBe('2 hours');
  });

  it('writes hours and minutes together', () => {
    expect(pipe.transform(165)).toBe('2 hours 45 minutes');
    expect(pipe.transform(61)).toBe('1 hour 1 minute');
  });

  it('writes nothing as 0 minutes', () => {
    expect(pipe.transform(0)).toBe('0 minutes');
  });
});
```

No `TestBed` anywhere: a pipe is a class, so the test makes one with `new` and calls it. **That is
the cheapest test there is, and the one to reach for first**: nothing to configure, nothing to wait
for, and a failure that can only mean the function is wrong. The next section gives the planner's
arithmetic the same kind of test.
