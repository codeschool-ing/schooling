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
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"Two copies of the shop's database, São Paulo on the left and Lisbon on the right, each showing one monitor in stock. The link between them is cut. A customer in each city tries to buy the monitor. Below, the two outcomes the theorem allows: keep consistency, and at least one copy refuses the sale; keep availability, and both copies sell the same unit.\"><defs><marker id=\"cap1-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"200\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"52.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">copy in São Paulo</text><text x=\"130.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">monitors in stock: 1</text><rect x=\"470\" y=\"30\" width=\"200\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"52.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">copy in Lisbon</text><text x=\"570.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">monitors in stock: 1</text><line x1=\"230\" y1=\"60\" x2=\"330\" y2=\"60\" stroke=\"var(--wire)\" stroke-width=\"2\"></line><line x1=\"370\" y1=\"60\" x2=\"470\" y2=\"60\" stroke=\"var(--wire)\" stroke-width=\"2\"></line><text x=\"350\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" fill=\"var(--amber)\">×</text><text x=\"350\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">link cut</text><rect x=\"55\" y=\"120\" width=\"150\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">customer buys</text><rect x=\"495\" y=\"120\" width=\"150\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">customer buys</text><line x1=\"130\" y1=\"120\" x2=\"130\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#cap1-ah-paper-dim)\"></line><line x1=\"570\" y1=\"120\" x2=\"570\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#cap1-ah-paper-dim)\"></line><rect x=\"30\" y=\"190\" width=\"300\" height=\"90\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"180.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">keep consistency</text><text x=\"180.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a copy that cannot confirm refuses:</text><text x=\"180.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">an error page, and no unit sold twice</text><rect x=\"370\" y=\"190\" width=\"300\" height=\"90\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"520.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">keep availability</text><text x=\"520.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">both copies sell:</text><text x=\"520.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">two confirmations for one unit</text></svg>", "caption": "A partition leaves each copy two moves. Neither copy can learn about the other's sale until the link comes back."}
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
