---
title: A topic is a name for several logs
version: 1
---

**A topic is not a log. It is a name for a set of logs, called partitions, and each partition is
a log exactly like the one lesson 2 built**: records appended at one end, numbered from 0, read
without being removed. The topic `sales` from lesson 1 has three partitions, so it is three logs,
each with its own offset 0, its own offset 1 and so on. "Offset 5 of `sales`" means nothing until
you say which partition.

The usual wrong picture is a single queue of messages with the partitions as some internal detail
of storage. They are not a detail. **The partition is the unit Kafka keeps in order, the unit it
spreads over machines, and the unit a consumer reads.** Almost every behaviour in this lesson and
the next is a property of a partition, and the topic is only the label on the group.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A topic named sales drawn as a box holding three partitions. Each partition is a row of records numbered from offset 0, and the rows have different lengths: partition 0 has seven records, partition 1 has eleven, partition 2 has four. A producer on the left hashes each message's key to choose one partition; new records are appended at the right-hand end of their row.\" data-fig=\"l3-topic\"><defs><marker id=\"l3-topic-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"105\" width=\"80\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">producer</text><text x=\"60\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">hash(key) % 3</text><rect x=\"160\" y=\"30\" width=\"545\" height=\"200\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"175\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">topic sales</text><path d=\"M 100 122 L 228 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l3-topic-ah-8343)\"></path><text x=\"195\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partition 0</text><rect x=\"235\" y=\"75\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"252\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">0</text><rect x=\"273\" y=\"75\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">1</text><rect x=\"311\" y=\"75\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"328\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">2</text><rect x=\"349\" y=\"75\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"366\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">3</text><rect x=\"387\" y=\"75\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"404\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">4</text><rect x=\"425\" y=\"75\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"442\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">5</text><rect x=\"463\" y=\"75\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"480\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">6</text><rect x=\"501\" y=\"75\" width=\"34\" height=\"26\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><path d=\"M 100 122 L 228 143\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l3-topic-ah-8343)\"></path><text x=\"195\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partition 1</text><rect x=\"235\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"252\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">0</text><rect x=\"273\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">1</text><rect x=\"311\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"328\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">2</text><rect x=\"349\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"366\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">3</text><rect x=\"387\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"404\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">4</text><rect x=\"425\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"442\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">5</text><rect x=\"463\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"480\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">6</text><rect x=\"501\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"518\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">7</text><rect x=\"539\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"556\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">8</text><rect x=\"577\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"594\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">9</text><rect x=\"615\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"632\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">10</text><rect x=\"653\" y=\"130\" width=\"34\" height=\"26\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><path d=\"M 100 122 L 228 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l3-topic-ah-8343)\"></path><text x=\"195\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partition 2</text><rect x=\"235\" y=\"185\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"252\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">0</text><rect x=\"273\" y=\"185\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">1</text><rect x=\"311\" y=\"185\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"328\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">2</text><rect x=\"349\" y=\"185\" width=\"34\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"366\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">3</text><rect x=\"387\" y=\"185\" width=\"34\" height=\"26\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"620\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">new records here</text></svg>", "caption": "One topic, three logs. Each partition has its own offsets, and nothing orders one partition against another."}
```

## Making one and looking at it

Start from an empty one-node cluster: stop the one you have, make a new one and start it.

```
ubuntu@stream:~/work$ ./cluster.sh stop
node 1: stopped
ubuntu@stream:~/work$ ./cluster.sh new 1
new: 1 node(s), cluster id mAc1snoQSM-zbCZ_Bkb0QA
ubuntu@stream:~/work$ ./cluster.sh start
node 1: up on localhost:9092
```

`new` deletes everything the cluster held, including lesson 1's five sales, which is what you want
here: every number below starts from zero.

Now create `sales` again, with three partitions, and ask Kafka to describe it:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3
Created topic sales.
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic sales
Topic: sales	TopicId: RSujK3biS5ihRVB5huS3Kw	PartitionCount: 3	ReplicationFactor: 1	Configs: min.insync.replicas=1
	Topic: sales	Partition: 0	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 1	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 2	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr: 
```

The first line of the description is about the topic. It carries an id Kafka gave it, which is how
the cluster knows it (the name can be reused after a delete; the id cannot). Then the number of
partitions, and the **replication factor**, the number of copies of each partition. It is 1 here
because there is one node to keep copies on. Then one line per partition, numbered from 0:

- **`Leader`** is the node that holds the partition and takes its writes and reads. Node 1, for
  all three, because node 1 is all there is.
- **`Replicas`** lists every node with a copy, and **`Isr`** the ones whose copy is up to date.
- **`Elr`** and **`LastKnownElr`** are empty, and stay empty until lesson 5 has three nodes and kills
  some of them.

With one node the last four columns say the same thing three times. **They start to differ in
lesson 5**, where a partition has three copies on three nodes and losing one is something to
watch.

## Why three, and not one

A partition is read in order by one reader at a time within a group, and written by its leader
on one node. That has two consequences, and they pull in opposite directions:

- **Order holds only inside a partition.** Two sales in two partitions have no order between them
  at all, whatever their offsets say. Lesson 2 argued that order per key is enough; the next section
  shows how Kafka sends each key to one partition, which is what makes it enough.
- **Parallelism stops at the number of partitions.** Three partitions can be read by three copies
  of a program at once, each taking one; a fourth copy has nothing to read. Lesson 4 runs exactly
  that. On a cluster of several nodes, the three partitions can also live on three different
  machines, which lesson 5 does.

So the number of partitions is a decision with a cost on both sides, and the last section of this
lesson is about making it.
