---
title: Blocking the loop
version: 1
---

**The one way to make a Node server slow for everybody is to keep the main thread busy.** Lesson 1
said so in a picture. This section does it and measures it.

```javascript
// busy.js: one route that computes for two seconds, and one that does nothing.
const http = require("node:http");
const { monitorEventLoopDelay } = require("node:perf_hooks");

const delay = monitorEventLoopDelay({ resolution: 1 });
delay.enable();

function spin(ms) {
  const end = Date.now() + ms;
  while (Date.now() < end) {} // busy: nothing else can run meanwhile
}

http
  .createServer((req, res) => {
    if (req.url === "/slow") spin(2000);
    if (req.url === "/delay") {
      res.end(`event loop delay: max ${Math.round(delay.max / 1e6)} ms, mean ${Math.round(delay.mean / 1e6)} ms\n`);
      return delay.reset();
    }
    res.end(`${req.url} done\n`);
  })
  .listen(3000, "127.0.0.1", () => console.log("listening on 3000"));
```

`spin` stands in for real work: a sort, a report, a regular expression that backtracks. It is a
loop that checks the clock, so it does nothing useful and keeps the thread for exactly as long as it
is told. Start the server in one terminal, and in the other ask for `/fast` on its own, then
`/slow` in the background followed straight away by `/fast` again:

```
ana@dev:~/server/loop$ curl -s -o /dev/null -w 'fast alone: %{time_total} s\n' http://127.0.0.1:3000/fast
fast alone: 0.003214 s
ana@dev:~/server/loop$ curl -s http://127.0.0.1:3000/delay
event loop delay: max 4 ms, mean 1 ms
ana@dev:~/server/loop$ curl -s -o /dev/null -w 'slow: %{time_total} s\n' http://127.0.0.1:3000/slow &
ana@dev:~/server/loop$ sleep 0.2; curl -s -o /dev/null -w 'fast behind slow: %{time_total} s\n' http://127.0.0.1:3000/fast
slow: 2.000612 s
fast behind slow: 1.800269 s
ana@dev:~/server/loop$ sleep 0.5; curl -s http://127.0.0.1:3000/delay
event loop delay: max 2001 ms, mean 5 ms
```

`-w` makes `curl` print how long the whole request took, and `-o /dev/null` throws the body away.
**`/fast` took a few milliseconds alone, and nearly two seconds behind `/slow`.** Its own code did
not change; it waited for the thread. With a hundred users, every one of them waits, and none of
them asked for anything slow.

## Measuring it from inside

`monitorEventLoopDelay` sets a timer to fire every millisecond and records how late each one was.
An idle loop is never more than a few milliseconds late. **A late timer is the loop's own measure
of how long your code held it**, and `/delay` reports the worst one since the last time it was
asked: the second reading caught the two seconds of `/slow`. A server that logs this number, or
exposes it to its monitoring, finds a blocking route the day it ships instead of the day somebody
complains.

## What to do instead

Three answers, in the order to reach for them:

1. **Do less.** A report computed once and kept, a list paged instead of sorted whole, a regular
   expression without nested repetition.
2. **Split it.** Work done in slices with `setImmediate` between them lets other callbacks run in
   the gaps, as javascript lesson 13 did on a page.
3. **Move it off the main thread.** A worker thread, a child process, or another service. Lesson 10
   does all three.
