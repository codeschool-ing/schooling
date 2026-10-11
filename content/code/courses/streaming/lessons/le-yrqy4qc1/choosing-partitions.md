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
ubuntu@stream:~/work$ python keys.py --partitioner murmur2_random shops recife=4p olinda=4p caruaru=4p natal=4p joao-pessoa=4p
recife       partition 0  offset 5
caruaru      partition 0  offset 6
olinda       partition 1  offset 8
natal        partition 2  offset 2
joao-pessoa  partition 2  offset 3
```

With three partitions, `murmur2_random` sent Recife to 2, Olinda and João Pessoa to 0, and
Caruaru and Natal to 1. With four, Recife and Caruaru went to 0, Olinda to 1, and Natal and João
Pessoa to 2. **All five shops moved.** Each shop's old messages stay where they were, so Recife's
history is now split between partition 2, up to the change, and partition 0, after it. A consumer
reading both partitions sees no order between the two halves, which is the reordering lesson 2
warned about, created by a configuration change. Only a key whose hash happens to give the same
remainder stays put, and with five keys none did.

## Never fewer

Removing partitions is not possible at all:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --alter --topic shops --partitions 2
Error while executing topic command : The topic shops currently has 4 partition(s); 2 would not be an increase.
[2026-10-10 17:01:51,108] ERROR org.apache.kafka.common.errors.InvalidPartitionsException: The topic shops currently has 4 partition(s); 2 would not be an increase.
 (org.apache.kafka.tools.TopicCommand)
```

`2 would not be an increase`. A partition holds messages and offsets that consumers have
recorded positions in, and merging two of them would give both a new order and break every
recorded offset, so Kafka does not offer it.

So **choose the number on the day you create the topic**, with room to grow, because the ways to
change it later are a migration: a new topic with the new number, every reader moved to it, and
the old one kept until nobody needs it. Lesson 16 does that kind of move for another reason,
reprocessing.
