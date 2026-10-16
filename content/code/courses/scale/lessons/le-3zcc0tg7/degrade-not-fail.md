---
title: Less, rather than nothing
version: 1
---

The box office depends on six other things: the primary, the replica, Redis, payments, the
Collector and nginx. Each will be unavailable at some point, and with lesson 10's box office, losing
some of them still means losing everything: a replica that stops makes every read a `500`, and a
primary that stops makes reads fail along with sales. **Graceful degradation** is the practice of
deciding, for each dependency, what the system does without it, so that a failure takes away the
part that needs it and nothing else.

The deciding is the work. It starts by sorting what the system does by how much it matters:

| | what it is | without its dependency |
|---|---|---|
| **core** | selling a ticket | refuse clearly, and never charge for nothing |
| **important** | showing a show and its seats left | answer from somewhere else, and say how fresh it is |
| **useful** | limiting each buyer's rate | let it go for a while, and log it |
| **optional** | traces, metrics | lose them silently; the SDK and Prometheus already do |

Then each dependency gets a decision, written in the code rather than discovered during the
outage:

- **the replica** goes: read from the primary instead, which has the same data and is only busier;
- **the primary** goes: answer reads with the last value seen, marked as old; **pause sales**,
  because a sale needs the one place that knows which seats are left;
- **Redis** goes: sell without the per-buyer limit, lesson 9's fail-open;
- **payments** goes: the breaker answers at once and every read carries on, as lesson 9 showed.

Two rules make a degraded answer honest. **Say that it is degraded**: a seat count from memory
carries its age, and a paused sale says *paused*, not *error*. And **degrade the expensive things
first**: when the box office is short of capacity, it is the recommendations on a show page that
should go, not the purchase button. A system that answers everything slowly in an overload has
chosen not to choose.
