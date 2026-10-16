---
title: A node dies while the tills are selling
version: 1
---

**When a leader dies, the controllers notice that it has stopped sending heartbeats, pick a new
leader from the partition's ISR, and tell every node; producers and consumers find the new leader
by asking for fresh metadata and carry on.** The whole exchange takes seconds. The producer's job
during those seconds is to keep the sales it could not deliver and send them again, which it does
by itself, inside `message.timeout.ms`.

Find the leader of the partition the key `recife` goes to. Every `acks.py` run so far has printed
it: partition 1. The `describe` says who leads it:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092,localhost:9093 --describe --topic sales
Topic: sales	TopicId: hBMADyrPSHqe-J4ZJkPq1A	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: sales	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 1	Leader: 2	Replicas: 2,3,1	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 2	Leader: 1	Replicas: 3,1,2	Isr: 1,2,3	Elr: 	LastKnownElr: 
```

In this run, partition 1 is led by node 2. Kafka chose the leaders when the topic was made, so
yours may be another node: use the one your `describe` names.

## Kill the leader, mid-stream

In the second shell, start a producer that sends a hundred sales at five a second, twenty seconds
in all:

```
ubuntu@stream:~/work$ python acks.py --acks all --count 100 --rate 5
```

A few seconds in, in the first shell, kill the leader of partition 1 with `-9`, which ends the
process with no chance to say goodbye, as a power cut would. Use the number your `describe`
printed:

```
ubuntu@stream:~/work$ ./cluster.sh kill 2    # the leader of partition 1
node 2: killed
```

When the producer finishes, the second shell shows:

```
ubuntu@stream:~/work$ python acks.py --acks all --count 100 --rate 5
%6|1791683985.882|FAIL|rdkafka#producer-1| [thrd:localhost:9093/2]: localhost:9093/2: Disconnected: connection closed by peer: receive 0 after POLLIN (after 5938ms in state UP)
%3|1791683985.948|FAIL|rdkafka#producer-1| [thrd:localhost:9093/2]: localhost:9093/2: Connect to ipv4#127.0.0.1:9093 failed: Connection refused (after 0ms in state CONNECT)
%3|1791683986.294|FAIL|rdkafka#producer-1| [thrd:localhost:9093/2]: localhost:9093/2: Connect to ipv4#127.0.0.1:9093 failed: Connection refused (after 0ms in state CONNECT, 1 identical error(s) suppressed)
acks=all: 100 delivered
partition 1: offsets 290 to 389
```

**A hundred delivered, none failed**, at offsets 290 to 389: a hundred consecutive offsets for a
hundred sales. The three `FAIL` lines are the client noticing that its connection to node 2 was
closed and that nothing answers on 9093 any more; while it looked for the new leader, it kept the
sales in memory and sent them when it found it.

The `describe`, with two addresses given:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092,localhost:9093 --describe --topic sales
[2026-10-10 23:00:01,556] WARN [AdminClient clientId=adminclient-1] Connection to node -2 (localhost/127.0.0.1:9093) could not be established. Node may not be available. (org.apache.kafka.clients.NetworkClient)
Topic: sales	TopicId: hBMADyrPSHqe-J4ZJkPq1A	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: sales	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 1	Leader: 3	Replicas: 2,3,1	Isr: 1,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 2	Leader: 1	Replicas: 3,1,2	Isr: 1,3	Elr: 	LastKnownElr: 
```

The `WARN` line is the tool trying 9093 first and finding it dead; the second address answered.
Node 2 has gone from every ISR, and partition 1 is now led by node 3, which was in its ISR.

## The node comes back

Start it again. It has a log that stops where it died, so it starts as a follower, fetches what it
missed, and rejoins the ISR:

```
ubuntu@stream:~/work$ ./cluster.sh start 2
node 2: up on localhost:9093
ubuntu@stream:~/work$ sleep 10; kafka-topics.sh --bootstrap-server localhost:9092,localhost:9093 --describe --topic sales
Topic: sales	TopicId: hBMADyrPSHqe-J4ZJkPq1A	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: sales	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 1	Leader: 3	Replicas: 2,3,1	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 2	Leader: 1	Replicas: 3,1,2	Isr: 1,2,3	Elr: 	LastKnownElr: 
```

Every ISR is whole again, and the leaders are not where they started. **A returning node does not
take its leadership back.** That leaves the load uneven: one node leads two partitions, and takes
twice the writes and twice the reads of another.

The first node in each `Replicas` list is the partition's **preferred leader**, and Kafka moves
leadership back to it in two ways. The broker does it on its own: with
`auto.leader.rebalance.enable=true`, the default, it checks every
`leader.imbalance.check.interval.seconds`, 300 by default, and moves leaders back when a node's
share is off by more than ten per cent. Or you ask for it at once:

```
ubuntu@stream:~/work$ kafka-leader-election.sh --bootstrap-server localhost:9092 --election-type preferred --all-topic-partitions
Successfully completed leader election (PREFERRED) for partitions sales-2, sales-1
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092,localhost:9093 --describe --topic sales
Topic: sales	TopicId: hBMADyrPSHqe-J4ZJkPq1A	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: sales	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 1	Leader: 2	Replicas: 2,3,1	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 2	Leader: 3	Replicas: 3,1,2	Isr: 1,2,3	Elr: 	LastKnownElr: 
```

Partitions 1 and 2 had leaders other than their preferred ones: partition 2 since node 3 was frozen
two sections ago, partition 1 since node 2 was killed. Both moved back, and each node leads one
partition again.

## What it cost

Nothing that was acknowledged. A hundred sales sent, a hundred delivered, at a hundred consecutive
offsets, so none was written twice either. What the failure cost was **time**: for a few seconds
the partition had no leader, and the sales sent in those seconds waited in the producer's memory. A
consumer of the partition would have seen the same pause. That is what replication costs when it
works. It is measured in seconds because the controllers wait a few seconds of silence before they
declare a node dead: long enough not to fail over on every slow heartbeat, short enough that a till
never notices.
