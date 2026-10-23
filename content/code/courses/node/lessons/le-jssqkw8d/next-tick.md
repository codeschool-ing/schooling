---
title: process.nextTick, and the queue before the queue
version: 1
---

**`process.nextTick(fn)` runs `fn` as soon as the current piece of JavaScript finishes, before any
promise callback and before the loop moves on.** It is older than promises in Node, and it has its
own queue, which is emptied first:

```javascript
// ticks.js
console.log("1 synchronous");
setTimeout(() => console.log("5 timeout"), 0);
setImmediate(() => console.log("6 immediate"));
Promise.resolve().then(() => console.log("4 promise"));
process.nextTick(() => console.log("3 nextTick"));
console.log("2 synchronous, last line");
```

```
ana@dev:~/server/loop$ node ticks.js
1 synchronous
2 synchronous, last line
3 nextTick
4 promise
6 immediate
5 timeout
```

The order is the queues in the order Node empties them: the file itself, then the `nextTick`
queue, then the microtasks, then the loop's phases — timers, then check. The numbers were written to
match what printed; the lines were written in a different order on purpose.

## What it is for, and what it costs

Node's own libraries use `nextTick` for one job above all: **to make a callback asynchronous every
time, even when the answer is already known.** A function that sometimes calls back at once and
sometimes later is a trap, because the code after the call runs before the callback in one case and
after it in the other. Deferring with `nextTick` makes it always "after", at almost no cost.

The cost is that the `nextTick` queue is drained **completely**, including ticks added while it is
being drained, before anything else happens. A function that schedules itself with `nextTick`
never lets the loop reach the poll phase, so no request is ever read again:

```javascript
// starve.js
let ticks = 0;
function again() {
  ticks++;
  if (ticks < 1_000_000) process.nextTick(again);
}
setTimeout(() => console.log(`the timer ran after ${ticks} ticks`), 0);
again();
```

```
ana@dev:~/server/loop$ node starve.js
the timer ran after 1000000 ticks
```

The timer was due after one millisecond and waited for a million ticks. With no limit in the
`if`, it would wait for ever. **In your own code, prefer `queueMicrotask` or a resolved promise**
when you need "after this, but soon"; they have the same shape of risk with one fewer queue to
reason about, and the Node documentation recommends the same.
