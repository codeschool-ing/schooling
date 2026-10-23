---
title: What you already know about the loop
version: 1
---

javascript lesson 13 built the event loop from three parts, and all three are true in Node:

1. **one call stack**, and a callback runs only when it is empty;
2. **a task queue**, where whole pieces of work wait — a timer's callback, a finished network
   request — and run one at a time;
3. **a microtask queue**, for promise callbacks and `queueMicrotask`, which is emptied completely
   after every task, before the next one starts.

That lesson also showed the order a program prints in, in Node and in a browser, and the two
agreed. **That model is still right, and this lesson only adds detail to the second part.** In the
browser the task queue is described as one queue. In Node it is several, visited in a fixed order,
and that order is what decides between two callbacks that are both ready.

What does not change is the most important consequence lesson 13 drew: **while your code runs,
nothing else does.** On a page that froze a button. On a server it holds up every other request
in the process, and the section on blocking the loop measures by how much.

The other things this lesson assumes from `javascript`:

| from | what |
|---|---|
| lesson 14 | callbacks, promises, `async`/`await`, and running things in parallel with `Promise.all` |
| lesson 15 | timers, and why `setTimeout(fn, 0)` does not mean "now" |
| lesson 17 | `throw`, `try`/`catch`, and errors that happen later |

If any of those is hazy, it is worth an hour there before going on. Everything in lessons 5 to 10
of this course is written with them.
