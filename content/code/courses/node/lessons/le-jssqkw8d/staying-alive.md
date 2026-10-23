---
title: When a process decides it is finished
version: 1
---

**A Node process exits when the loop has nothing left to wait for.** Not when the file ends: the
file ends long before most programs are done. What keeps the loop going is anything that could
still produce a callback — a timer, an open server, a socket, a pending file read — and libuv calls
each of those a **handle** or a **request** that is *referenced*.

```javascript
// alive.js
const timer = setInterval(() => console.log("tick"), 1000);
if (process.argv[2] === "unref") timer.unref();

process.on("beforeExit", () => console.log("beforeExit: nothing left to wait for"));
process.on("exit", (code) => console.log(`exit with code ${code}`));
console.log("end of the file");
```

```
ana@dev:~/server/loop$ timeout 3.5 node alive.js; echo "exit code $?"
end of the file
tick
tick
tick
exit code 124
```

The interval keeps the process alive for as long as it exists. `timeout 3.5` stopped it from the
outside after three ticks, and the exit code 124 is `timeout`'s way of saying it had to. Neither
event printed: **a process killed from outside runs none of its own exit code**, which is what
lesson 10's section on shutting down cleanly is about.

## unref

`timer.unref()` tells the loop not to count this timer when deciding whether to stay alive. The
timer still fires if the process happens to be running anyway; it just does not keep it running:

```
ana@dev:~/server/loop$ node alive.js unref
end of the file
beforeExit: nothing left to wait for
exit with code 0
```

With nothing else to wait for, the loop finished at once. **`beforeExit`** fired because the loop
emptied; a handler there may schedule more work, and the process carries on if it does. **`exit`**
fired last, and nothing asynchronous can happen inside it, so it is the place for a last log line
and nothing else. Servers, sockets and child processes all have an `unref()` with the same meaning.
It is how a background timer that flushes statistics avoids keeping a finished program alive.

## The reverse puzzle

A program that should finish and does not has something still referenced: a database connection
nobody closed, a `setInterval` nobody cleared, a server still listening. A test that never ends is
the usual symptom, and lesson 4's test runner will show it to you. Finding the culprit starts with
listing what you opened, because Node's loop will not exit while any of it is still there.
