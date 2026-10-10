---
title: What CAP says, and the version people repeat
version: 1
---

The version everybody has heard is a menu: **consistency, availability, partition tolerance, pick
two.** It is short, it sounds like engineering, and it describes no system anybody can build. Two
of its three choices are not choices at all.

## The three words, as the proof uses them

Eric Brewer put the idea forward in 2000, and Seth Gilbert and Nancy Lynch proved it in 2002. The
proof needs each word to mean one precise thing, and none of the three means what it means in
ordinary speech:

| | in the theorem | not to be confused with |
|---|---|---|
| **C**onsistency | every read returns the most recent acknowledged write, as if there were one copy of the data | the C in ACID, which is about a transaction keeping the rules of the schema |
| **A**vailability | every request that reaches a node that has not failed gets an answer that is not an error | "the site is up most of the time" |
| **P**artition | the network between the copies loses messages, for as long as it likes | a node crashing, which is a different and easier problem |

The consistency in the theorem has a name of its own, **linearisability**, and it is a strong
promise: once any client has been told a write succeeded, no client anywhere may read the value from
before it.

## Why "pick two" is wrong

A database with one copy of its data has no partition to tolerate, and it is consistent and
available until the machine dies. The theorem is about the moment you keep **more than one copy**,
on more than one machine, joined by a network. And a network between machines is not something that
may or may not partition. Cables are cut, switches reboot, a cloud zone loses its uplink, a long garbage
collection pause makes a node silent until the others decide it is gone. Partitions
happen to a system whether its designers chose them or not.

So P is not on the menu. **The real statement is conditional: when the network between the copies
is broken, each copy that is cut off must either refuse to answer or answer without knowing the
latest write.** Refuse, and you kept consistency and gave up availability. Answer, and you kept
availability and gave up consistency. There is no third option, because the copy cannot learn
what it cannot hear.

## One partition, both answers

Take the shop from `sql-databases`, now running in two places so that customers on both sides of the
Atlantic get a fast page: one copy of the database in São Paulo and one in Lisbon. The 27-inch
monitor has **one unit left**. The link between the two cities fails, and in the same minute a
customer in each city puts that monitor in the basket and pays.

```schooling-figure
{"svg": "PLACEHOLDER-CAP", "caption": "PLACEHOLDER"}
```

Each copy has exactly the two moves the theorem allows:

- **Keep consistency.** A copy that cannot confirm with the other side refuses the sale, or refuses
  every write until the link returns. Nobody is sold a monitor that does not exist; customers in
  one city, or both, get an error page.
- **Keep availability.** Both copies sell. Both customers get a confirmation. When the link comes
  back, the two copies hold two sales of one unit, and somebody has to write an apology and a
  refund.

Neither is a bug. Which one is right depends on what is being sold, and for a monitor with one unit
in a warehouse, most shops would rather show an error than sell air. For a "recently viewed" list on
the same site, the second is obviously better: nobody is harmed by a list that is a minute out of
date.

## What the theorem does not say

It says nothing about the time when the network works, which is nearly all of the time. It does
not say a system is "a CP database" or "an AP database" for good: the products in this course let
you choose per operation, and lesson 17 makes Cassandra do both on the same table. And it does not
measure how much of either you get: a system that refuses writes for two seconds during a failover
and one that refuses them for two hours are both "not available" in the proof's sense.

The next section is about the first of those gaps, because it is the one you pay for every day.
