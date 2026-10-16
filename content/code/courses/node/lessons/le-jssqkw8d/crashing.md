---
title: Errors nobody caught
version: 1
---

**A thrown error that nothing catches ends the process, and so does a rejected promise that nobody
handles.** Lesson 1 showed the first. The second surprises people more, because the code that
created the promise has already moved on:

```javascript
// reject.js
async function loadPrices() {
  throw new Error("the price list is unreachable");
}

loadPrices(); // nobody waits for it, nobody catches it
setTimeout(() => console.log("one second later"), 1000);
```

```
ana@dev:~/server/loop$ node reject.js; echo "exit code $?"
/home/ana/server/loop/reject.js:3
  throw new Error("the price list is unreachable");
        ^

Error: the price list is unreachable
    at loadPrices (/home/ana/server/loop/reject.js:3:9)
    at Object.<anonymous> (/home/ana/server/loop/reject.js:6:1)
    at Module._compile (node:internal/modules/cjs/loader:1706:14)
    at Object..js (node:internal/modules/cjs/loader:1839:10)
    at Module.load (node:internal/modules/cjs/loader:1441:32)
    at Function._load (node:internal/modules/cjs/loader:1263:12)
    at TracingChannel.traceSync (node:diagnostics_channel:328:14)
    at wrapModuleLoad (node:internal/modules/cjs/loader:237:24)
    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:171:5)
    at node:internal/main/run_main_module:36:49

Node.js v22.22.0
exit code 1
```

The timer never printed. Node noticed a rejection with no handler once the microtasks had run, and
**since Node 15 its default is to treat that exactly like an uncaught throw**: print it and exit
with code 1. Older advice that says an unhandled rejection is only a warning describes Node 14 and
before.

The fix is the one javascript lesson 14 gave for the browser, and it matters more here: every
promise is either awaited or given a `.catch`. `loadPrices()` on its own line is the bug, even if
`loadPrices` usually succeeds.

## The last line of defence

Two process events see these errors before Node acts on them:

```javascript
// last-resort.js
process.on("unhandledRejection", (reason) => {
  console.error(`unhandled rejection: ${reason.message}`);
  process.exit(1);
});
process.on("uncaughtException", (err) => {
  console.error(`uncaught exception: ${err.message}`);
  process.exit(1);
});

Promise.reject(new Error("the price list is unreachable"));
setTimeout(() => null.total, 10);
```

```
ana@dev:~/server/loop$ node last-resort.js; echo "exit code $?"
unhandled rejection: the price list is unreachable
exit code 1
```

Only the first error printed, because its handler ended the process before the timer ran. **Both
handlers log and exit, and that is the only safe thing for them to do.** After an uncaught
exception the program is in a state nobody planned for: a request half answered, a file half
written, a lock never released. A handler that logs and carries on keeps a broken process serving
traffic. Logging what happened and exiting, so that whatever restarts the process starts a clean
one, is the pattern; lesson 10 covers what does the restarting.
