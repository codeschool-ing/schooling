---
title: Limits, and where the state goes
version: 1
---

A function is cheap and effortless inside a box whose walls the provider sets. **Knowing where the
walls are is most of the design, because a function that hits one fails in production, not in the
test on your laptop.** On Lambda these are the ones that shape designs, with only the numbers AWS
documents plainly:

- Duration: at most 15 minutes per call. A job that takes twenty minutes cannot be one Lambda call,
  however it is configured; it has to be cut into steps or run somewhere else.
- Memory: from 128 MB to 10,240 MB, and the share of processor grows with it. A function that is
  slow because it is short of CPU gets faster with more memory, and the GB-seconds arithmetic
  decides whether it also gets cheaper.
- Payload: the request and the response of a synchronous call are each capped at 6 MB. A function
  that produces a large file puts it in object storage and returns a link to it.
- Local disk: `/tmp` exists, 512 MB by default and configurable up to 10,240 MB, and it lives only as
  long as the execution environment. It is scratch space, not storage.
- Concurrency: the account has a quota per region on how many copies run at once, shared by every
  function in it. One function in a runaway loop can take the capacity the others need, and a
  concurrency limit reserved per function is the guard.

## No state between calls

This lesson's handler already showed it with a counter. **Whatever a function keeps in memory
belongs to one execution environment, and the platform creates and discards those as it chooses.**
**So every piece of state lives outside: in a database, a cache, an object store or a queue.** A
user's session is a row or a signed token, not a variable. A file being processed is in a bucket,
not in `/tmp` waiting for the next call to find it.

## Thousands of functions, one database

The failure this produces is specific and common. **A relational database accepts a limited number
of connections, and each execution environment opens its own.** A server application keeps a pool
of, say, twenty connections and shares them among all its requests. Functions cannot share across
environments, so **a burst that creates 800 environments can open 800 connections**, and the
database refuses the ones past its limit, or slows under the rest, at the moment traffic peaks.

There are three answers:

- a connection proxy between the functions and the database, which holds a small pool of real
  connections and lends them out; AWS sells one as RDS Proxy;
- a limit on the function's concurrency, low enough that it cannot open more connections than the
  database accepts, which means requests past the limit are turned away or queued;
- a database whose interface is HTTP requests rather than long-lived connections, such as DynamoDB,
  which leaves no pool to run out of.

**None of this shows up on a laptop**, where one process makes one connection. It shows up on the
first busy day.
