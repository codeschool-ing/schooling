---
title: Where Kafka Streams keeps its state
version: 1
---

The counts live inside the application, and the application is a process that can die. **Kafka
Streams keeps each count twice: in a local store on the machine, for speed, and in a Kafka topic,
for safety.** A copy that starts on a machine with no local store rebuilds it by reading that
topic. The topics are created by the library, named after the application, and they are the first
thing to look at:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --list
__consumer_offsets
sales
sales-per-book
sales-per-shop
sales-per-shop-KSTREAM-AGGREGATE-STATE-STORE-0000000001-changelog
sales-per-shop-KSTREAM-AGGREGATE-STATE-STORE-0000000006-changelog
sales-per-shop-KSTREAM-AGGREGATE-STATE-STORE-0000000006-repartition
```

Two of them are the output topics the program named. The other three nobody named:

| topic | what it is for |
|---|---|
| `…-STATE-STORE-0000000001-changelog` | every change of the count per shop, so the store can be rebuilt |
| `…-STATE-STORE-0000000006-changelog` | the same for the count per book |
| `…-STATE-STORE-0000000006-repartition` | the sales again, keyed by book instead of by shop |

The **changelog** topics are the backup. They are compacted, which lesson 3 described: Kafka keeps
the last record per key, so a changelog holds one count per shop however long the application
runs.

The **repartition** topic is the price of `groupBy`. A count per book needs every sale of `bk-03` in
one place, and the sales arrive keyed by shop, spread over three partitions. So the library writes
each sale back to Kafka with the book as its key, which sends all of a book's sales to one partition
of the new topic (lesson 3), and the counting reads from there. **Choosing a new key costs one more
write and one more read of every record**, which is why `groupByKey` is preferred whenever the key
is already right. The numbers in the names are the positions of the steps in the topology, and they
are why a change to the topology can rename a store and orphan its old topic.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"The topology of SalesPerShop, in two parts. Part 0 reads the sales topic, keyed by shop. Its count per shop needs no new key, so it is counted at once into a local store, whose changes go to a changelog topic and to the output topic sales-per-shop. For the count per book, part 0 writes each sale again to a repartition topic, keyed by book. Part 1 reads that topic and counts per book into a second store, with its own changelog, and writes to sales-per-book. Each part runs as three tasks, one per partition.\" data-fig=\"l13-topology\"><defs><marker id=\"l13-topology-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-topology-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l13-topology-ah-2105\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sales</text><text x=\"65.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">keyed by shop</text><rect x=\"150\" y=\"20\" width=\"250\" height=\"140\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"275\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">part 0: tasks 0_0, 0_1, 0_2</text><rect x=\"170\" y=\"50\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"230\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">groupByKey, count</text><rect x=\"170\" y=\"106\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"230\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">groupBy book</text><path d=\"M 112 82 L 166 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-topology-ah-8343)\"></path><path d=\"M 112 92 L 166 118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-topology-ah-8343)\"></path><rect x=\"300\" y=\"50\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"345\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">store: per shop</text><path d=\"M 292 67 L 297 67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"450\" y=\"50\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sales-per-shop</text><path d=\"M 392 67 L 446 67\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-topology-ah-2105)\"></path><rect x=\"590\" y=\"10\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">…-changelog</text><path d=\"M 370 50 Q 420 20 586 27\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-topology-ah-83)\"></path><rect x=\"175\" y=\"190\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">…-repartition</text><text x=\"250.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">keyed by book</text><path d=\"M 230 142 L 240 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-topology-ah-8343)\"></path><rect x=\"400\" y=\"180\" width=\"250\" height=\"80\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"525\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">part 1: tasks 1_0, 1_1, 1_2</text><rect x=\"415\" y=\"192\" width=\"70\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">count</text><rect x=\"495\" y=\"192\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">store: per book</text><path d=\"M 327 207 L 411 207\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-topology-ah-8343)\"></path><rect x=\"590\" y=\"120\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sales-per-book</text><path d=\"M 587 200 L 640 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-topology-ah-2105)\"></path><path d=\"M 587 215 L 662 215 L 662 250\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"668\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">changelog</text></svg>", "caption": "A new key costs a trip through Kafka: the repartition topic is where the sales are re-sorted by book."}
```

The local copy is on disk, in the directory the program named, with one subdirectory per task:

```
ubuntu@stream:~/work$ ls ~/streams-state/a/sales-per-shop
0_0
0_1
0_2
1_0
1_1
1_2
kafka-streams-process-metadata
```

`0_0` to `0_2` are the tasks of the first part of the topology, reading `sales`, and `1_0` to `1_2`
those of the second, reading the repartition topic. The stores inside are RocksDB, an embedded
database whose jar also came with Kafka.

## A second copy

**Scaling a Kafka Streams application means starting another copy of it.** Start copy `a` again in
the second shell, then copy `b` in a third shell, opened the same way:

```
ubuntu@stream:~/work$ java -cp "$HOME/kafka/libs/*:." SalesPerShop b
state: CREATED -> REBALANCING
state: REBALANCING -> RUNNING
tasks here: [0_1, 1_0, 1_2]
state: RUNNING -> PENDING_SHUTDOWN
state: PENDING_SHUTDOWN -> NOT_RUNNING
```

The two copies are members of one consumer group, `sales-per-shop`, the application id, and the
group gave the six tasks to two members:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group sales-per-shop --members

GROUP           CONSUMER-ID                                                                                                      HOST            CLIENT-ID                                                                   #PARTITIONS     
sales-per-shop  sales-per-shop-dabbbf81-17e6-434a-9c35-4fad4428eacd-StreamThread-1-consumer-89e5e53c-7058-41b1-94be-043b5b58b876 /127.0.0.1      sales-per-shop-dabbbf81-17e6-434a-9c35-4fad4428eacd-StreamThread-1-consumer 3               
sales-per-shop  sales-per-shop-a7b61109-432f-48c5-9455-da5f975f2de0-StreamThread-1-consumer-37731bed-72e3-471a-9493-dccc05f6d825 /127.0.0.1      sales-per-shop-a7b61109-432f-48c5-9455-da5f975f2de0-StreamThread-1-consumer 3               
```

Each member holds three partitions, and the program's own lines say which tasks:

```
ubuntu@stream:~/work$ java -cp "$HOME/kafka/libs/*:." SalesPerShop a
state: CREATED -> REBALANCING
state: REBALANCING -> RUNNING
tasks here: [0_0, 0_2, 1_1]
state: RUNNING -> PENDING_SHUTDOWN
state: PENDING_SHUTDOWN -> NOT_RUNNING
```

Copy `a` holds `0_0`, `0_2` and `1_1`, and copy `b` the other three; your split may differ, since
the group decides it. Nothing was copied between them by hand: a task that moves to another copy
takes its count from the changelog topic. Stop both copies with Ctrl+C when you are done. While
copy `a` was running alone, it was a Java process of about 170 MB beside the Kafka node:

```
ubuntu@stream:~/work$ ps -o pid,rss,comm -u ubuntu --sort=-rss | head -4
  PID   RSS COMMAND
31511 478416 java
30894 429560 java
23783 410488 java
```
