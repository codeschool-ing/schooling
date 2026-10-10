---
title: Choosing a model before choosing a lock
version: 1
---

**Most concurrency bugs are designed in on the day somebody adds threads to code that was never
meant to have them.** The locks in this lesson are repairs. The cheaper decision comes first: which
model of concurrency the program should use at all, and how little state it can share inside that
model. Two questions decide most of it.

## What is the time spent on?

Section 02 measured the answer that matters. **Waiting** overlaps under any model, so pick the one
that makes sharing least dangerous. **Computing** only gets faster with more cores, and on the
ordinary Python build that means processes.

| the work is mostly... | in Python | why |
|---|---|---|
| waiting on many sockets, thousands of connections | `asyncio` | one thread; a switch can only happen at an `await`, so most races cannot be written |
| waiting, through a library that blocks and has no async version | a `ThreadPoolExecutor` | threads release the GIL while they wait |
| computing, and the pieces are independent | a `ProcessPoolExecutor` | true parallelism; nothing shared, so nothing to race on |
| a stream of events to transform and pace | lesson 16's reactive streams | backpressure is part of the model |
| long-lived state that many callers change | lesson 17's actors | one owner per piece of state, and messages instead of locks |

`asyncio` is not free of races, and it is worth being exact about why. A coroutine that reads a
value, awaits a database call, and writes back a new value has the same gap as `race.py`, with the
`await` in place of `sleep(0)`. What it removes is the gap *you did not write*: between two lines
with no `await`, nothing else runs.

## How much has to be shared?

Every row of the table gets safer as the shared state shrinks. The order to try things in, which
is also the order of this lesson read backwards:

1. Share nothing: give each task its own data, as the process pool did.
2. Share only immutable values, and publish new ones by swapping a reference.
3. Confine each mutable thing to one owner, and send it messages.
4. Lock, around your own data, briefly, in one agreed order.

**A lock is the last resort and not the first**, because it is the only one of the four whose
correctness depends on every caller, now and in the future, behaving. The first three put the
safety in the structure, where a reader can see it.

## What each language hands you

| | first tool | when computing in parallel | sharing safely |
|---|---|---|---|
| Python | `asyncio`, or threads for blocking libraries | `multiprocessing`; the free-threaded build from 3.13 | `queue.Queue`, frozen dataclasses, `threading.Lock` |
| JavaScript / TypeScript | the event loop, `async`/`await` | worker threads, with messages | nothing is shared by default; `SharedArrayBuffer` and `Atomics` when you opt in |
| Java | threads; virtual threads since Java 21 make one per request cheap | the same threads, on every core | `java.util.concurrent`: `ConcurrentHashMap`, `AtomicReference`, locks |
| Go | goroutines | the same goroutines, on every core | channels first, `sync.Mutex` when a channel is awkward |

Go's proverb puts point 3 in a sentence: *do not communicate by sharing memory; share memory by
communicating.* JavaScript made the same choice for you by giving each worker its own heap. Java
and Python on threads give you shared memory by default and leave the discipline to you, which is
why most of this lesson's examples could only have been written in those two.

## Where the patterns stand now

The title of this lesson promised that patterns break down, and the breakage has a pattern of its
own. Each one assumed that between two of its lines the world stood still.

| pattern | what threads break | the fix in this lesson |
|---|---|---|
| any object with a counter or a total | read-modify-write loses updates | a lock inside the object |
| singleton, created lazily | check-then-act builds several | create it before the threads, or lock and check twice |
| observer | the list changes during a walk | copy under the lock, call outside it |
| value object | nothing; it was already safe | none needed, and that is the point |

None of these fixes is a new pattern. They are the same designs with one more question asked of
them: *who else can be here at the same time?* Lesson 19 turns that kind of question into a habit
for choosing any pattern at all.
