---
title: The loop's phases
version: 1
---

**Node's loop is a circuit of queues, and it goes round them in the same order every time.** Each
stop on the circuit is a **phase**, and each phase has its own queue of callbacks:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The event loop as a circuit of four phases in order: timers, poll, check and close, and back to timers. Between every callback in any phase, the nextTick queue and then the promise microtasks are emptied. The loop sleeps in the poll phase when nothing is due.\"><rect x=\"40\" y=\"60\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">timers</text><text x=\"105\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">setTimeout</text><text x=\"105\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">setInterval</text><rect x=\"210\" y=\"60\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">poll</text><text x=\"275\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sockets, files, connections</text><rect x=\"380\" y=\"60\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">check</text><text x=\"445\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">setImmediate</text><rect x=\"550\" y=\"60\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">close</text><text x=\"615\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">'close' events</text><line x1=\"172\" y1=\"92\" x2=\"208\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"208.0,92.0 200.6,95.1 200.6,88.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"342\" y1=\"92\" x2=\"378\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"378.0,92.0 370.6,95.1 370.6,88.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"512\" y1=\"92\" x2=\"548\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"548.0,92.0 540.6,95.1 540.6,88.9\" fill=\"var(--paper-dim)\"></polygon><path d=\"M615 124 L615 160 L105 160 L105 128\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><line x1=\"105\" y1=\"140\" x2=\"105\" y2=\"127\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"105.0,127.0 108.1,134.4 101.9,134.4\" fill=\"var(--paper-dim)\"></polygon><text x=\"360\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">and round again</text><text x=\"275\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">sleeps here when nothing is due</text><rect x=\"40\" y=\"200\" width=\"640\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">between every single callback, in every phase</text><rect x=\"120\" y=\"236\" width=\"220\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"230\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1. the nextTick queue</text><rect x=\"380\" y=\"236\" width=\"220\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"490\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2. promise microtasks</text><line x1=\"342\" y1=\"251\" x2=\"378\" y2=\"251\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"378.0,251.0 370.6,254.1 370.6,247.9\" fill=\"var(--paper-dim)\"></polygon></svg>", "caption": "Each phase empties its own queue. The two small queues are emptied after every callback, in any phase."}
```

The four you will meet:

| phase | whose callbacks run there |
|---|---|
| **timers** | `setTimeout` and `setInterval`, once their time has passed |
| **poll** | input and output: data that arrived on a socket, a file read that finished, a new connection. If nothing else is waiting, **the loop sleeps here** until something arrives or the next timer is due |
| **check** | `setImmediate`, which exists to run "straight after this round's input and output" |
| **close** | `'close'` events, such as a socket that was destroyed |

Two more phases, *pending* and *idle/prepare*, are libuv's own bookkeeping and almost never matter
to a program. And between **every single callback**, in any phase, Node empties two queues before
moving on: the `process.nextTick` queue and then the promise microtasks. The next section is about
those two.

## A timer against an immediate

`setTimeout(fn, 0)` and `setImmediate(fn)` both say "soon", and the phases decide which is sooner.
Inside a callback from input and output the answer is fixed. The loop is in the poll phase, the
check phase comes next, and the timers phase only comes round after it:

```javascript
// inside-io.js
const fs = require("node:fs");

fs.readFile(__filename, () => {
  setTimeout(() => console.log("timeout"), 0);
  setImmediate(() => console.log("immediate"));
});
```

```
ana@dev:~/server/loop$ for i in $(seq 20); do node inside-io.js | paste -sd' '; done | sort | uniq -c
     20 immediate timeout
```

Twenty runs, one order. **From the top of a file there is no such guarantee**, and the
documentation says so. A timer of 0 is really 1 millisecond, and whether that millisecond has
passed when the loop first reaches the timers phase depends on how long the process took to start.
On this computer, twenty runs of the two lines alone came out the same way, and the same two lines
followed by five milliseconds of busy work came out the other way, every time:

```javascript
// race.js
setTimeout(() => console.log("timeout"), 0);
setImmediate(() => console.log("immediate"));
if (process.argv[2] === "slow") {
  const end = Date.now() + 5;
  while (Date.now() < end) {} // five milliseconds of work before the loop starts
}
```

```
ana@dev:~/server/loop$ for i in $(seq 20); do node race.js | paste -sd' '; done | sort | uniq -c
     20 immediate timeout
ana@dev:~/server/loop$ for i in $(seq 20); do node race.js slow | paste -sd' '; done | sort | uniq -c
     20 timeout immediate
```

The twenty identical lines in the first run are not a promise. **Code that needs one of two
callbacks to run first must say so** — call the second from the first — rather than lean on an
order that held on one machine.
