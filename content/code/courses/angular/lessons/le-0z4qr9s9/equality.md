---
title: The change that is not a change
version: 1
---

**A signal decides whether it changed by comparing the new value with the old using `Object.is`, so
an object or an array changed in place is, to the signal, not changed at all.** This is the bug every
team meets in its first month with signals, and it produces no error: the page simply stays as it
was. A program shows it in six lines of output:

```typescript
// try/equality.mts
import { computed, signal } from '@angular/core';

interface Session {
  minutes: number;
}

const sessions = signal<Session[]>([{ minutes: 30 }, { minutes: 60 }]);
const total = computed(() => sessions().reduce((sum, s) => sum + s.minutes, 0));
console.log('total:', total());

sessions().push({ minutes: 25 });
console.log('after push:', total(), 'with', sessions().length, 'sessions');

sessions.set(sessions());
console.log('after set to the same array:', total());

sessions.update((list) => [...list]);
console.log('after a new array:', total());

sessions.update((list) => [...list, { minutes: 50 }]);
console.log('after adding the right way:', total());
```

```
ana@dev:~/planner$ node try/equality.mts
total: 90
after push: 90 with 3 sessions
after set to the same array: 90
after a new array: 115
after adding the right way: 165
```

Read the middle lines slowly. `push` put a third session into the array, and `total` still said 90:
the signal held the same array object, nobody called `set` or `update`, so nothing told `total` it was
stale. `set` with that same array did not help either, because `Object.is` found the old value and
the new one to be the same object. Only a **new array** counted as a change, and the first one,
made by copying, brought the 25 into the total at last.

**The rule: never change what a signal holds; give it a new value.** For an array, `[...list, item]`
to add, `list.filter(…)` to remove, `list.map(…)` to change one item, each returning a new array. For
an object, `{ ...session, done: true }`. The same discipline is what lesson 7's OnPush and lesson 22's
stores ask for, so it pays three times.

## When equal should mean something else

The comparison can be replaced. A signal created with an `equal` function uses it instead of
`Object.is`:

```typescript
const week = signal({ start: '2026-10-19', end: '2026-10-25' }, {
  equal: (a, b) => a.start === b.start && a.end === b.end,
});
```

Setting `week` to a new object with the same two dates is then not a change, and nothing that
reads it is disturbed. It is rarely needed; reach for it when a value is rebuilt often and is usually
the same.
