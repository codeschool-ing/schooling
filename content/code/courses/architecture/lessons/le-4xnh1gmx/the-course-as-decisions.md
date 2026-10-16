---
title: The course, as a decision log
version: 1
---

Here is this course written as the records Quitanda's team would have kept, in the order the lessons
reached them. Every row is a decision with a context that could change, and every one of them could be
superseded one day by a better-informed version of the same team:

| lesson | the decision |
| --- | --- |
| 1, 2 | a modular monolith first; split a module out only when a force from lesson 2 demands it |
| 4 | configuration in the environment, logs to standard output, one codebase per deployable |
| 5 | synchronous calls with timeouts where the caller needs the answer now; messages where it does not |
| 6, 7 | at-least-once delivery, idempotent consumers, and an outbox where a change and its event go together |
| 8, 9 | consistency for stock taken at checkout and for money; availability, labelled approximate, for what a page shows |
| 10 | one PostgreSQL with a standby; sharding only when a measurement says one machine is not enough |
| 11, 12 | timeouts, retries with a budget, a breaker and a bulkhead per dependency; rate limits at the door |
| 13 | event sourcing for payments and the stock ledger, and nowhere else |
| 14 | the checkout as an orchestrated saga, with reservations as its lock |
| 15 | new services carved out with a strangler facade, never by a rewrite |
| 16 | no `SELECT *` in application code; caches and read models for questions every visitor asks |
| 17 | search from a copy fed by events, rebuilt from the database whenever needed |
| 18 | Server-Sent Events for order status, with a backplane from the second instance |
| 19 | one gateway as the shop's door; a registry when the platform brings one |

None of them is the right answer in general, and that is the course's one lasting claim: **architecture
is choosing which costs to pay, for reasons that can be written down**, and changing the choice when the
reasons change. A team that keeps the reasons can make that change on purpose.

When you are done, the lab has nothing to stop. Remove its directory if you like:

```sh
rm -rf ~/lab/adr
```
