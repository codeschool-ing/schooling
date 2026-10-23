---
title: gather, and the other ways to run coroutines together
version: 1
---

`asyncio.gather` is the tool `three.py` and `loop.py` used: it takes coroutines, runs them on the
loop together, and returns their results in order once all are done. It is the one most code needs,
and it has relatives worth knowing by name.

| tool | what it does | use it when |
|---|---|---|
| `await gather(a, b, c)` | runs all, returns all results in order | you need every answer |
| `asyncio.TaskGroup` | the same, inside `async with`, and cancels the rest if one fails | one failure should stop the others |
| `asyncio.create_task(coro)` | starts one now; `await task` later collects it | work starts before you know what else you need |
| `await asyncio.wait_for(coro, 2)` | gives up after a timeout, raising `TimeoutError` | a partner might never answer |

## When one of them fails

By default `gather` lets an exception from any coroutine propagate to whoever awaited it, **and the
others keep running**, their results lost. `gather(..., return_exceptions=True)` puts the exception
in the results list instead, beside the answers that did come back. A `TaskGroup` cancels the others
at the first failure, which is the right default for work where one missing answer makes the rest
useless.

## A timeout on everything you wait for

A partner that sometimes takes thirty seconds will, one day, take thirty seconds for every request
at once, and every coroutine waiting on it piles up. **Every call to something outside the process
needs a timeout**: `httpx2.AsyncClient(timeout=5)` gives every request one, and `wait_for` bounds any
coroutine. `load.py`, in the next section, sets a generous 120 seconds on purpose, because it is a
measuring tool that must not give up before the slowest case it measures.
