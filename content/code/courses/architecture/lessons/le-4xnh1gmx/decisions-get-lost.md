---
title: Decisions get lost
version: 1
---

Every lesson of this course ended in a decision: ask the stock service or listen to it, replicate
synchronously or not, orchestrate the checkout or let it be choreographed. Each came with reasons, and
each of the reasons depended on facts about Quitanda at that moment: its traffic, its team, its money.

A year later the decisions are still in the code and the reasons are not. The person who argued for
them has moved teams; the meeting was not written down; the chat thread is a thousand messages up. What
the new people see is a system that does something odd, and they do one of two things, both bad. They
**leave it alone**, because it might matter, and the system collects decisions nobody can explain. Or
they **change it**, because it looks wrong, and rediscover the reason the hard way.

Michael Nygard proposed a remedy in 2011, in a short post called *Documenting Architecture Decisions*,
and it has become the standard one: an **architecture decision record**, or ADR. One short text file per
significant decision, written when the decision is made, kept in the repository beside the code it
explains, numbered in order, and never rewritten. The collection is the **decision log**.

Not every choice needs one. A decision is **architecturally significant** when it is expensive to change
later or it shapes what many other decisions can be:

| deserves a record | does not |
| --- | --- |
| split the stock module into a service | the name of a function |
| PostgreSQL rather than a document store | which linter to run |
| at-least-once delivery with idempotent consumers | the order of fields in a JSON response |
| an API gateway in front of every service | a dependency's minor version |

Lesson 1 of this course defined architecture as the decisions that are expensive to change. ADRs are
where those decisions are kept.
