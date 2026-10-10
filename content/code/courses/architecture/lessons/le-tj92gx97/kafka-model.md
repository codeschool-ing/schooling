---
title: Kafka: topics, partitions, offsets and groups
version: 1
---

Kafka was written at LinkedIn around 2010 to move activity data between systems at a scale a queue
could not, published as open source in 2011, and given to the Apache Software Foundation. Its model has four words, and each one is
a consequence of the log.

| word | what it is |
| --- | --- |
| **topic** | a named log, such as `orders` |
| **partition** | one of the pieces a topic is split into; each partition is a log of its own, on one broker at a time |
| **offset** | the position of a message within its partition, starting at 0 |
| **consumer group** | a set of consumers that share a topic's partitions, with one stored offset per partition for the group |

## Partitions are the unit of everything

A topic with one partition can be read by one consumer of a group at a time, because a partition is
read in order by one reader. **To read faster, a topic needs more partitions**, and a group's consumers
divide them: three partitions, two consumers, one of them gets two. A fourth consumer in a group of
three partitions has nothing to do.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A topic called orders split into three partitions. Messages are drawn with their keys: every message with key ana goes to partition 1, in the order it was written; bruno and carla share partition 2. Partition 0 is empty. Two consumers of one group divide the partitions between them.\"><defs><marker id=\"l6-partitions-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">topic orders</text><rect x=\"30\" y=\"50\" width=\"460\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">partition 0</text><rect x=\"30\" y=\"112\" width=\"460\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">partition 1</text><rect x=\"150\" y=\"120\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">ana: order 1</text><rect x=\"260\" y=\"120\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">ana: order 3</text><rect x=\"30\" y=\"174\" width=\"460\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">partition 2</text><rect x=\"150\" y=\"182\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"200\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">bruno: order 2</text><rect x=\"260\" y=\"182\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">carla: order 4</text><rect x=\"370\" y=\"182\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">bruno: order 5</text><rect x=\"560\" y=\"60\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">consumer 1</text><rect x=\"560\" y=\"160\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">consumer 2</text><path d=\"M492 74 L558 80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-partitions-ah-phosphor)\"></path><path d=\"M492 136 L558 92\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-partitions-ah-phosphor)\"></path><path d=\"M492 198 L558 185\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-partitions-ah-phosphor)\"></path><text x=\"360\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one key, one partition, in order</text></svg>", "caption": "The key decides the partition, so every message for one customer lands in one partition, in order. Across partitions there is no order at all."}
```

**Which partition a message goes to is decided by its key.** The producer hashes the key and the result
picks the partition, so every message with the key `ana` lands in the same partition, in the order it
was written. Messages without a key are spread across partitions. Kafka's ordering promise is exactly
this and no more: **order within a partition, none across partitions**. Lesson 7 takes that promise
apart, because "the events of one order arrive in order" depends entirely on choosing the right key.

## Groups read independently

Each consumer group stores its own offset for each partition, in Kafka itself. The group `email` and the
group `warehouse` read the same topic without knowing about each other, each at its own position, and
neither takes anything away from the other. That is the log's equivalent of RabbitMQ's queue per
service, and it has one property a queue does not: a group created next month can start from the
oldest message still retained and read the whole history.

## What Kafka does not do

Kafka does not route by content: there are no bindings or patterns, only topics, and a consumer that
wants some of a topic's messages reads all of them and skips the rest. It does not delete a message
because it was read. And it does not track each message's delivery: it tracks offsets, so "this message
failed, retry it later" is something the consumer has to arrange, usually with a separate topic for
retries, where RabbitMQ would simply redeliver.
