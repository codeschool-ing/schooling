---
title: Timers you forget to stop
version: 1
---

**A timer holds its callback, and everything the callback's closure can reach, until it runs or is
cleared.** An interval never runs out on its own. In Node, timers have one more effect: they keep
the process alive.

```javascript
const reminder = setTimeout(() => console.log("this would print after a minute"), 60_000);
reminder.unref();

const round = (ms) => Math.round(ms / 100) * 100;
const start = performance.now();
process.on("exit", () => console.log("process ended after about", round(performance.now() - start), "ms"));

const poll = setInterval(() => console.log("still polling"), 1000);
setTimeout(() => {
  clearInterval(poll);
  console.log("stopped the poll; nothing is left to wait for");
}, 2500);
```

```
ana@dev:~/js$ node alive.js
still polling
still polling
stopped the poll; nothing is left to wait for
process ended after about 2500 ms
```

Node exits when it has nothing left to wait for. **A pending timer counts as something to wait for**,
so the poll kept the process running until `clearInterval` stopped it, two and a half seconds in.
The reminder was set for a minute, yet the process ended at about 2500 ms, because
`reminder.unref()` told Node not to stay alive for that timer alone: it still fires if the process is
running anyway, and it does not hold the process open. That is what the timer object's methods are
for, and why Node's id is an object.

## The rule

**Every interval, and every timeout that might outlive the thing it belongs to, needs a matching
clear**, written when the timer is written:

- a component or a page section that starts a poll stops it when it is removed. Frameworks give you a
  place for this, a cleanup function or an "on destroy" hook, and it is where the `clearInterval` goes;
- a server that starts a timer per request clears it when the request ends, or a thousand requests
  leave a thousand timers;
- a script that should finish, finishes: if a command-line tool hangs after printing its result,
  a forgotten timer or an open connection is the usual reason.

Lesson 19 measures what forgotten timers and listeners cost in memory. Lesson 16 uses the newer way
to cancel work in progress, `AbortController`, which `fetch` understands.
