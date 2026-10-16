---
title: Request and response
version: 1
---

**Synchronous** communication is the style everybody learns first: the caller sends a request and
waits, doing nothing else on that path, until the answer arrives. An HTTP call is synchronous unless
something is done to make it otherwise. So is a call to a database, and so was every function call
inside lesson 1's monolith.

It is the right default for a good reason. The code reads in order, the answer is right there in the
next line, and an error arrives where the call was made, with nothing to correlate later. **When a
caller needs the answer to continue**, a price to show or a yes or no on a payment, synchronous is
simply the shape of the problem.

## What it ties together

The cost is **temporal coupling**: for the call to succeed, both sides have to be up, and responsive,
at the same moment. The caller borrows the callee's availability and its speed for the length of the
call.

| if the service you call is | then you are |
| --- | --- |
| slow | slow, by at least as much |
| down | down, for every request that needed it, unless you have a fallback |
| overloaded | waiting, holding a thread or a connection while you wait |

Lesson 2's shop showed the second row: with the stock service stopped, the catalogue answered `503`.
The third row is the dangerous one, because the caller's waiting threads are a resource too, and
lesson 12 shows a slow dependency using them all up.

## Synchronous does not mean blocking, quite

A program can make a synchronous call without blocking a thread, using an event loop, `async` and
`await`, or futures: the thread does other work while the request is in flight. That changes how many
calls one process can have waiting at once. **It does not change the coupling**: the request still
cannot complete until the other side answers. In this course "synchronous" means the conversation's
shape, a request that needs its answer now, whatever the code that waits for it looks like.
