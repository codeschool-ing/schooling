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

@@fig:l3-topic@@

## Making one and looking at it

Start from an empty one-node cluster: stop the one you have, make a new one and start it.

```
ubuntu@stream:~/work$ ./cluster.sh stop
```

`new` deletes everything the cluster held, including lesson 1's five sales, which is what you want
here: every number below starts from zero.

Now create `sales` again, with three partitions, and ask Kafka to describe it:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3
```

The first line of the description is about the topic: an id Kafka gave it, which is how the
cluster really knows it (the name can be reused after a delete; the id cannot), the number of
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
