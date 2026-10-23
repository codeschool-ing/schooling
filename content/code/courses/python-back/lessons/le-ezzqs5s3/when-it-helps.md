---
title: When async actually helps
version: 1
---

The measurements in this lesson come down to a short table:

| the route spends its time | `def` | `async def` | what to do |
|---|---|---|---|
| waiting on the network, few at a time | fine | fine | either |
| waiting on the network, many at once | limited by the thread pool | **scales** | `async def`, with async libraries |
| waiting through a library with no async version | **fine** | blocks everything | `def`, or `asyncio.to_thread` |
| computing | one at a time | one at a time | more processes, or a background worker |

Three questions decide it for a real application, in order.

**Does it wait on the network, a lot, at the same time?** A chat server, a gateway in front of other
services, an API that calls three partners per request: yes, and `async def` with async libraries
pays for itself. A site that reads a nearby database for every page: rarely enough to matter, and
lesson 1's warning applies: the time goes to the query.

**Does every library on the path have an async version?** One synchronous call inside an `async def`
undoes the rest, as 10.2 seconds showed. For a database, that means an async driver, and lesson 10
stays synchronous on purpose: SQLAlchemy's async mode exists, and it is a second set of rules to learn
after the first.

**Is the team ready to keep the two straight?** Async code is not harder to write. It is harder to
review, because the mistake looks exactly like correct code.

FastAPI's choice is that you pick per route, which is the right granularity: `def` by default,
`async def` where the waiting is, and every await truly awaited.
