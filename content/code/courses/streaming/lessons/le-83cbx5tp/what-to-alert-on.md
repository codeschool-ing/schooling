---
title: What deserves an alarm
version: 1
---

**An alert is a promise to wake somebody, so it should fire only when somebody has to act.** A
stream produces hundreds of numbers, and most of them are for looking at after something has gone
wrong. The few worth an alarm are the ones that say a promise is about to be broken: the output is
going stale, data is about to be lost, or the cluster has less margin than it was built with.

## Lag: alarm on the trend and the age, not the size

The tempting rule is *lag above 1000*. It fires at every peak, when the tills ring up a Saturday
morning and the consumer catches up ten minutes later on its own, and people learn to ignore it.
The lag section showed the shape that matters: lag that grows while the producer is busy and shrinks
when it is quiet is a consumer doing its job.

Two rules work better:

- **Lag in time above what the output promises.** If the website's stock may be a minute old, alert
  at a few minutes of lag in time, the number `lag_seconds.py` printed. It means the promise is
  already broken, whatever the count.
- **Lag that keeps growing.** If the lag has grown at every sample for the last fifteen minutes, the
  consumer is slower than the producer, and waiting will not fix it. This catches the slow decline
  before the age rule does.

And one that is easy to forget: **a consumer group with no members**. A crashed consumer has no lag
to grow until sales arrive, and in the small hours none do; its absence is the signal.

## Replication: under-replicated and offline partitions

On a cluster of three nodes, with a topic whose partitions have three copies:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3 --replication-factor 3
Created topic sales.
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --describe --under-replicated-partitions
```

`--under-replicated-partitions` lists the partitions with fewer copies in sync than they should
have, and **printing nothing is the healthy answer**. Now one node dies, as it did on purpose in
lesson 5, and a few seconds later:

```
ubuntu@stream:~/work$ ./cluster.sh kill 3
node 3: killed
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --describe --under-replicated-partitions
	Topic: sales	Partition: 0	Leader: 1	Replicas: 3,1,2	Isr: 1,2	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 1	Leader: 1	Replicas: 1,2,3	Isr: 1,2	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 2	Leader: 2	Replicas: 2,3,1	Isr: 2,1	Elr: 	LastKnownElr: 
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --describe --unavailable-partitions
```

Every partition lost one copy, and every one is still served: `--unavailable-partitions` lists those
with no leader at all, and it printed nothing. **Under-replicated is a warning: the cluster is
working with less margin than it was built with**, and one more failure on the same partitions loses
data or availability. An **offline** partition, one with no leader, is the emergency: nobody can write
to it or read from it. That one was not provoked here, because on this cluster losing the two nodes it
would take also loses the majority of controllers, and the tools stop answering altogether. When the
node returns, the list empties again:

```
ubuntu@stream:~/work$ ./cluster.sh start 3
node 3: up on localhost:9094
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --describe --under-replicated-partitions
```

## Disk: the one that does not recover by itself

A broker whose disk fills stops accepting writes for the partitions on it. Unlike lag, nothing
drains it on its own; retention deletes old segments on its schedule, not on the disk's. Watch the
free space of the volume that holds the data, and alert well before it runs out:

```
ubuntu@stream:~/work$ df -h ~/kafka-data
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   15G   25G  37% /
ubuntu@stream:~/work$ du -sh ~/kafka-data/node*/log
92K	/home/ubuntu/kafka-data/node1/log
88K	/home/ubuntu/kafka-data/node2/log
84K	/home/ubuntu/kafka-data/node3/log
```

On this lab the data is tiny and the disk is shared with everything else in the machine. On a real
broker the log directory has a volume of its own, and its size is retention arithmetic, which is
lesson 17's subject.

## A short list

| alert on | because |
|---|---|
| lag in time above the output's promise | the promise is broken now |
| lag growing for a sustained period | the consumer cannot keep up, and will not on its own |
| a group with no members | a stopped consumer has no lag until data arrives |
| under-replicated partitions, for more than a few minutes | the cluster is one failure from losing data |
| any offline partition | writes and reads to it are failing now |
| free disk on a log volume | a full disk stops writes and does not recover by itself |
| messages arriving in a dead-letter topic | somebody has to read them |

Everything else, the request rates, the rebalance counts, the bytes in and out, goes on a dashboard
for the day something on this list fires. Where these numbers come from on a real cluster is the
brokers' and clients' metrics, collected by whatever monitoring system the company runs; the
commands here are the same questions asked by hand.
