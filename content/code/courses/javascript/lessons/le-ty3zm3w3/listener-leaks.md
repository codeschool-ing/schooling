---
title: Listeners and timers nobody removed
version: 1
---

A listener is a function stored by the object it listens to. **As long as that object lives, the
listener lives, and so does everything its closure captured.** Adding one per request to an object
that outlives requests is the classic Node leak:

```javascript
const { EventEmitter } = require("node:events");

const catalogue = new EventEmitter();
process.on("warning", (w) => console.log(`${w.name}: ${w.message}`));

function handleRequest(n) {
  const page = { n, rows: new Array(10_000).fill("row") };
  catalogue.on("updated", () => console.log("refresh page", page.n));
}

for (let n = 1; n <= 12; n++) handleRequest(n);
console.log("listeners now:", catalogue.listenerCount("updated"));
```

```
ana@dev:~/js$ node --no-warnings listeners.js
listeners now: 12
MaxListenersExceededWarning: Possible EventEmitter memory leak detected. 11 updated listeners added to [EventEmitter]. MaxListeners is 10. Use emitter.setMaxListeners() to increase limit
```

Each "request" added a listener to `catalogue`, and each listener's closure held its `page`, with its
ten thousand rows. **Twelve requests, twelve listeners, twelve pages kept alive for as long as the
catalogue exists.** Node noticed: past ten listeners for one event, an `EventEmitter` prints
`MaxListenersExceededWarning`, and the message says what it suspects, a memory leak. The program
printed the warning itself through `process.on("warning")`, which is how a server would send it to its
logs.

**Do not silence that warning by raising the limit.** It is almost always right. The fix is to remove
the listener when the request is done, with `off` or `removeListener` and the same function (lesson 12),
or to use `once` when the listener should run one time.

## Timers

```javascript
function startWidget() {
  const big = new Array(1_000_000).fill("data");
  const timer = setInterval(() => big.length, 1000);
  return { timer, ref: new WeakRef(big) };
}

const forgotten = startWidget();
const stopped = startWidget();
clearInterval(stopped.timer);

setTimeout(() => {
  globalThis.gc();
  console.log("widget never stopped, data alive:", forgotten.ref.deref() !== undefined);
  console.log("widget stopped, data alive:      ", stopped.ref.deref() !== undefined);
  process.exit(0);
}, 100);
```

```
ana@dev:~/js$ node --expose-gc timer-leak.js
widget never stopped, data alive: true
widget stopped, data alive:       false
```

Two widgets each started an interval whose callback referred to a million-item array. **The one whose
interval was cleared let its data go; the one nobody stopped kept its array alive**, because the
timer system holds the callback and the callback holds the array. In a page, the same happens with a
`setInterval` started by a component that was removed, and with listeners on `window` or `document`
added by elements that no longer exist. Lesson 15's rule is the fix: every timer has a matching clear,
written at the same time.
