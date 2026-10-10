---
title: How many partitions
version: 1
---

**The number of partitions is the most consequential setting of a topic, and the one hardest to
change later.** It is the ceiling on how many copies of a consumer can read the topic at once, it
is how the topic spreads over brokers, and it is part of the hash that sends each key to a
partition. Two of those are easy to reason about. The third is the trap.

## What more partitions buy and cost

| more partitions | buys | costs |
|---|---|---|
| reading | more consumers in one group working at once (lesson 4) | nothing, until there are more than the consumers you run |
| writing | writes spread over more brokers | more, smaller batches; each partition batches on its own |
| the cluster | load spread over more machines | more files open, more replicas to keep in step, a longer recovery when a broker dies (lesson 5) |
| order | nothing; order per key holds at any number | nothing |

A useful way to choose: estimate the most consumers you will ever want reading the topic in one
group, and how much one consumer can handle, and pick a number at or above that. A topic that
gets a few thousand messages a second does not need a hundred partitions, and a dozen costs little.
The tills of five shops would be served by three for years.

## Adding partitions moves keys

The number of partitions is in the hash: a key goes to `hash(key) % partitions`. Change the
number and the answer changes for some keys. Kafka lets you add partitions to a topic, and it does
not move a single existing message, so after the change **a key's old messages are in one
partition and its new ones in another**:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --alter --topic shops --partitions 4
```

MOVED-PROSE

## Never fewer

Removing partitions is not possible at all:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --alter --topic shops --partitions 2
```

FEWER-PROSE

So **choose the number on the day you create the topic**, with room to grow, because the ways to
change it later are a migration: a new topic with the new number, every reader moved to it, and
the old one kept until nobody needs it. Lesson 16 does that kind of move for another reason,
reprocessing.
