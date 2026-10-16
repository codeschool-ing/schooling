---
title: Three nodes, and a topic with three copies
version: 1
---

**Replication means each partition is stored on several nodes at once, so losing one node loses no
data and stops nothing.** The number of copies is the topic's **replication factor**, chosen when
the topic is made. Every lesson so far ran one node and a replication factor of 1, which is a
single copy on a single disk: one node down and the topic is gone until it comes back.

This lesson runs three. `cluster.sh` from lesson 1 already knows how: stop the one-node cluster,
make a new one with three nodes, and start it. `new` deletes the old cluster's data, which in this
course is always made again by the lesson that needs it:

```
ubuntu@stream:~/work$ ./cluster.sh stop
node 1: stopped
ubuntu@stream:~/work$ ./cluster.sh new 3
new: 3 node(s), cluster id YCLAkZhFSxymvym7xHcgzQ
ubuntu@stream:~/work$ ./cluster.sh start
node 1: up on localhost:9092
node 2: up on localhost:9093
node 3: up on localhost:9094
```

The three nodes listen on 9092, 9093 and 9094, each with its own directory under `~/kafka-data`.
They are three Java processes on one machine, with just under 400 MB of memory each, which is the
1.2 GB lesson 1 measured.

## A topic with three copies

`--replication-factor 3` asks for a copy of every partition on three nodes; with three nodes, that
is all of them. `min.insync.replicas` is the subject of the section on acks, and is set here so the
topic is made the way a production topic would be:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3 --replication-factor 3 --config min.insync.replicas=2
Created topic sales.
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092,localhost:9093 --describe --topic sales
Topic: sales	TopicId: hBMADyrPSHqe-J4ZJkPq1A	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: sales	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 1	Leader: 2	Replicas: 2,3,1	Isr: 2,3,1	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 2	Leader: 3	Replicas: 3,1,2	Isr: 3,1,2	Elr: 	LastKnownElr: 
```

The `describe` gives the topic's tools an address list rather than one address. Any node can answer
for the whole cluster, and with two addresses a tool still finds the cluster when the node it would
ask first is the one that is down, which happens on purpose in section 06.

Each partition's line has three columns this lesson is about:

| column | what it says |
|---|---|
| `Leader` | the node that takes the partition's writes and serves its reads |
| `Replicas` | the nodes that hold a copy, **the first one being the preferred leader** |
| `Isr` | the replicas that are in sync with the leader at this moment |

`Elr` and `LastKnownElr` are newer, and empty while everything is healthy; the section on unclean
elections fills them. Kafka spreads the leaders across the nodes, one partition each here, so the
writes for different partitions go to different machines. **Leadership is per partition, not per
node**: no node is "the leader of the cluster" in this sense, and every node is the leader of
something.

On disk, every node now has a directory for every partition:

```
ubuntu@stream:~/work$ ls -d ~/kafka-data/node*/log/sales-*
/home/ubuntu/kafka-data/node1/log/sales-0
/home/ubuntu/kafka-data/node1/log/sales-1
/home/ubuntu/kafka-data/node1/log/sales-2
/home/ubuntu/kafka-data/node2/log/sales-0
/home/ubuntu/kafka-data/node2/log/sales-1
/home/ubuntu/kafka-data/node2/log/sales-2
/home/ubuntu/kafka-data/node3/log/sales-0
/home/ubuntu/kafka-data/node3/log/sales-1
/home/ubuntu/kafka-data/node3/log/sales-2
```

Nine directories, three partitions times three copies. Which of them is the leader's is not visible
on disk; a copy is a copy, and any of them can become the leader.
