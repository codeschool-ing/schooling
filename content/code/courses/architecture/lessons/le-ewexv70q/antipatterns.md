---
title: Performance antipatterns
version: 1
---

A **pattern** is a solution that keeps working. An **antipattern** is a habit that keeps looking like a
solution and keeps causing the same problem. Microsoft's Azure Architecture Center keeps a catalogue of
the ones that make cloud systems slow, the **performance antipatterns**, and most of the entries are not
about clouds at all. They are about code that asks for too much, too often, from something far away.

Three of them account for most of what goes wrong in a shop like Quitanda's, and this lesson builds each
one and fixes it:

| antipattern | what the code does | why it hurts |
| --- | --- | --- |
| **chatty I/O** | many small requests where one would do | each request pays a round trip |
| **extraneous fetching** | fetches more data than it uses | every byte crosses the network and fills memory |
| **busy database** | makes the database do work that could be done once, or elsewhere | the database is the hardest part to scale |

What they share is that **they are invisible on a laptop**. With the database on the same machine, a
round trip is a tenth of a millisecond, and a thousand of them take a tenth of a second, which nobody
notices. In production the database is in another availability zone, a millisecond or two away, and the
same thousand round trips take two seconds. The code did not change; the distance did.

So the lab adds the distance back. Every byte between the shop and its database passes through a small
proxy that holds it for a millisecond each way, which turns a local round trip into about two
milliseconds, roughly the cost of crossing between zones in one region.
