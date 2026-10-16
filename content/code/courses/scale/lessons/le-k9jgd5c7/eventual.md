---
title: Eventual consistency, and what it promises
version: 1
---

The asynchronous replica of section 04 answered "a million seats left" for the whole partition,
and the right number a few seconds after it ended. That behaviour has a name. **Eventual
consistency** is the promise that if no new writes arrive, every copy will in the end hold the
same value.

It is a weak promise, and it is worth being exact about how weak:

- **It says nothing about how long "in the end" is.** Microseconds on a healthy network, minutes
  behind a busy replica, the whole length of a partition. A replica that is a week behind is still
  eventually consistent.
- **It says nothing about what a read returns meanwhile.** Any value that was ever written, in
  principle, including one older than a value the same client already saw.
- **It assumes the writes stop.** On a system that is written constantly, copies may never all be
  equal at one instant, and the promise is about where they are heading.

What makes it usable is that the window is short most of the time, and that a program can ask for
specific guarantees inside it. Werner Vogels's list of them is the one most systems still use, and
each one is a promise to **one client**, cheaper than consistency for everybody:

| guarantee | what one client is promised | broken when |
|---|---|---|
| **read-your-writes** | after writing, it sees its own write | lesson 2: the ticket bought and not shown |
| **monotonic reads** | it never sees a value older than one it already saw | two reads go to two replicas, the second further behind |
| **monotonic writes** | its writes are applied in the order it made them | a "rename" lands before the "create" it depends on |
| **consistent prefix** | it sees writes in an order that happened, never an answer before its question | a reply in a thread shows up before the message it answers |

Monotonic reads is the one people meet without knowing its name. A user refreshes the show's page,
and the first request goes to a replica that has the sale while the second goes to one that does
not: the seat count goes **up** by one between two refreshes. The usual fix is to keep each user on
the same replica for a session, which a load balancer can do with the sticky sessions of lesson 1,
for once used for a good reason.

**Eventual consistency is fine for a value that only moves forward and that nobody acts on
immediately**: a like count, a view count, the list of shows. It is not fine for a value that a
decision depends on, such as whether the last seat is free. The next two sections are about the
case that makes it hard: two sides that both accepted writes.
