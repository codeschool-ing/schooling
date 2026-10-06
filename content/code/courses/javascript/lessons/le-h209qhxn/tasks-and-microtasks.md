---
title: Tasks and microtasks
version: 1
---

Callbacks that wait for an empty stack wait in one of two queues, and **which queue decides when they
run**:

- the **task queue** holds whole pieces of work: a timer's callback, a click's handler, the
  completion of a network request. **One task runs at a time**, and the loop takes the oldest first;
- the **microtask queue** holds small follow-ups that must happen as soon as possible: the callbacks of
  promises (`.then`, and what comes after an `await`), and anything given to `queueMicrotask`. **When
  the stack empties, every microtask runs before the next task**, including microtasks that were queued
  while the queue was being emptied.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"The event loop. The call stack runs one task to completion. When it is empty, every microtask in the microtask queue runs, including any queued while draining. Then the browser may draw the page. Then the loop takes the oldest task from the task queue and runs it, and the cycle repeats.\"><defs><marker id=\"loop-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><defs><marker id=\"loop-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"loop-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"240\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">call stack</text><rect x=\"50\" y=\"70\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">format</text><rect x=\"50\" y=\"110\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">render</text><rect x=\"50\" y=\"150\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main</text><text x=\"120\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one task, run to the end</text><rect x=\"290\" y=\"20\" width=\"410\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"495\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">microtask queue: all of them, every time</text><rect x=\"310\" y=\"62\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">promise .then</text><rect x=\"440\" y=\"62\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">queueMicrotask</text><rect x=\"570\" y=\"62\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">await …</text><rect x=\"290\" y=\"160\" width=\"410\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"495\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">task queue: one at a time</text><rect x=\"310\" y=\"202\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">setTimeout</text><rect x=\"440\" y=\"202\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">click</text><rect x=\"570\" y=\"202\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">fetch done</text><path d=\"M220 60 L286 60\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\" marker-end=\"url(#loop-ah-amber)\"></path><text x=\"253\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1</text><path d=\"M495 120 L495 156\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#loop-ah-paper-dim)\"></path><text x=\"505\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2. maybe draw a frame</text><path d=\"M286 216 L224 216\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.6\" marker-end=\"url(#loop-ah-paper)\"></path><text x=\"253\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text></svg>", "caption": "One task, then every microtask, then perhaps a frame, then the next task."}
```

The order of a whole program follows from that one rule:

```javascript
console.log("A: synchronous");

setTimeout(() => console.log("B: task (setTimeout)"), 0);

Promise.resolve().then(() => console.log("C: microtask (promise)"));

queueMicrotask(() => console.log("D: microtask (queueMicrotask)"));

setTimeout(() => {
  console.log("E: second task");
  Promise.resolve().then(() => console.log("F: microtask queued by a task"));
}, 0);

setTimeout(() => console.log("G: third task"), 0);

console.log("H: synchronous, last line");
```

```
ana@dev:~/js$ node order.js
A: synchronous
H: synchronous, last line
C: microtask (promise)
D: microtask (queueMicrotask)
B: task (setTimeout)
E: second task
F: microtask queued by a task
G: third task
```

1. **A** and **H** are ordinary code, and run first, in order. The program itself is the first task.
2. The stack empties, so **every microtask runs**: **C** and **D**, in the order they were queued.
3. Then the oldest task, **B**.
4. Then the next task, **E**, which queues microtask **F**. **F runs before G**: after every task, the
   microtask queue is emptied again before the loop takes another task.

## The same order in the browser

```html
<!doctype html>
<script src="order.js"></script>
```

```
ana@dev:~/js$ page order.html
A: synchronous
H: synchronous, last line
C: microtask (promise)
D: microtask (queueMicrotask)
B: task (setTimeout)
E: second task
F: microtask queued by a task
G: third task
```

The same file, loaded by a page, printed the same eight lines in the same order. **The two queues and
the rule between them are the same in every engine**; what the host adds is what puts tasks in the
queue, clicks in a browser and file reads in Node.

## A microtask can hold up everything

```javascript
setTimeout(() => console.log("task"), 0);

let n = 0;
function again() {
  n += 1;
  if (n < 5) queueMicrotask(again);
  else console.log("5 microtasks ran first");
}
queueMicrotask(again);
```

```
ana@dev:~/js$ node chained.js
5 microtasks ran first
task
```

Each microtask queued another, and **all five ran before the timer's task**, because the queue had to
be empty first. Five is harmless. A chain that never stops queuing is a page where no click, timer or
frame ever runs again, and nothing reports an error, because nothing is wrong except that it never
ends.
