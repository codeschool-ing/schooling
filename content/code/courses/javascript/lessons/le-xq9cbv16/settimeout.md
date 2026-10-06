---
title: setTimeout: a delay that is a minimum
version: 1
---

**`setTimeout(fn, ms)` puts `fn` in the task queue once at least `ms` milliseconds have passed**, and
returns an id you can use to cancel it. Any arguments after the delay are passed to `fn`:

```javascript
const round = (ms) => Math.round(ms / 100) * 100;
const start = performance.now();

const id = setTimeout((title, copies) => {
  console.log(`reminder after about ${round(performance.now() - start)} ms: return ${title} (${copies})`);
}, 300, "Iracema", 2);
console.log("timer id:", typeof id);

const cancelled = setTimeout(() => console.log("never printed"), 200);
clearTimeout(cancelled);

const busyUntil = performance.now() + 500;
while (performance.now() < busyUntil) {}
console.log("busy loop finished after about", round(performance.now() - start), "ms");
```

```
ana@dev:~/js$ node timeout.js
timer id: object
busy loop finished after about 500 ms
reminder after about 500 ms: return Iracema (2)
```

The reminder was set for 300 ms and **ran at about 500 ms**. The timer did fire at 300, and its
callback joined the queue then. But the program was still in its busy loop, and lesson 13's rule
holds: nothing runs until the stack is empty. **The delay says when the callback may run, never
that it will.** The program rounds every time to the nearest 100 ms, because the exact figure moves
by a few milliseconds from run to run.

## The rest of the interface

- **`clearTimeout(id)` cancels a timer that has not run yet**, so `never printed` never printed. A
  cleared timer that already ran is harmless;
- extra arguments, `"Iracema"` and `2` here, are passed to the callback. An arrow that closes over
  the values (lesson 6) does the same and is more common;
- in Node the id is an **object** with methods of its own, used in the last section of this lesson;
  in a browser it is a number. Treat it as an opaque value you pass back to `clearTimeout`.

## When the delay matters

A timer is the right tool for "do this later": hide a notice after five seconds, retry a request after
a pause (lesson 16). **It is the wrong tool for measuring time**, as the reminder shows. To know how
long something took, read the clock before and after, which is what every program in this lesson does
with `performance.now()`.
