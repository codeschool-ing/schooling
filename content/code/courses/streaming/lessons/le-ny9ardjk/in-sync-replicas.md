---
title: In-sync replicas: the copies that count
version: 1
---

**The in-sync replicas, the ISR, are the replicas that have kept up with the leader recently
enough to be trusted with its data.** A replica that falls behind is taken out of the list, and
while it is out, nothing waits for it: the high watermark moves with the replicas still in the
list, and a write that needs all copies needs only theirs. It comes back into the list when it has
caught up.

"Recently enough" is one setting, read from the broker:

```
ubuntu@stream:~/work$ kafka-configs.sh --bootstrap-server localhost:9092 --describe --all --broker 1 | grep replica.lag.time.max.ms
  replica.lag.time.max.ms=30000 sensitive=false synonyms={DEFAULT_CONFIG:replica.lag.time.max.ms=30000}
```

**Thirty seconds, and it is measured in time, not in messages.** A follower is out of the ISR when
it has not been fully caught up with the leader at any moment in the last thirty seconds. Older
versions of Kafka also counted how many messages a follower was behind, which removed healthy
followers whenever a burst of writes arrived; a time limit only removes a follower that is truly
stuck.

## A node that stops without dying

A crash is the easy case: the process is gone and the connections drop. The harder one is a node
that is alive and not working, held up by a long garbage-collection pause, a disk that has gone
slow, or a virtual machine its host has frozen. `kill -STOP` produces exactly that: the process
keeps its memory, its ports and its files, and stops running. Freeze node 3, and wait more than
thirty seconds:

```
ubuntu@stream:~/work$ kill -STOP $(pgrep -f "^[^ ]*java .*node3/")
ubuntu@stream:~/work$ sleep 40; kafka-topics.sh --bootstrap-server localhost:9092,localhost:9093 --describe --topic sales
Topic: sales	TopicId: hBMADyrPSHqe-J4ZJkPq1A	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: sales	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 1	Leader: 2	Replicas: 2,3,1	Isr: 2,1	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 2	Leader: 1	Replicas: 3,1,2	Isr: 1,2	Elr: 	LastKnownElr: 
```

The pattern in `pgrep` matches the Java process whose command line names node 3's directory, the
same pattern `cluster.sh` uses; a looser one, such as `node3` on its own, could match your own
shell.

Node 3 has left every ISR. Partition 2, whose leader it was, now has node 1 as leader, because a
frozen leader answers nobody and the controllers stopped hearing from it. Every partition still has a
leader and two copies in sync, which is enough to take writes under `min.insync.replicas=2`, as the next section explains.

Now let it go:

```
ubuntu@stream:~/work$ kill -CONT $(pgrep -f "^[^ ]*java .*node3/")
ubuntu@stream:~/work$ sleep 10; kafka-topics.sh --bootstrap-server localhost:9092,localhost:9093 --describe --topic sales
Topic: sales	TopicId: hBMADyrPSHqe-J4ZJkPq1A	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: sales	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 1	Leader: 2	Replicas: 2,3,1	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: sales	Partition: 2	Leader: 1	Replicas: 3,1,2	Isr: 1,2,3	Elr: 	LastKnownElr: 
```

Ten seconds after it resumed, node 3 had fetched what it missed and was back in every ISR. It did
**not** get back the leadership of partition 2: a returning replica comes back as a follower, and
the section on a node dying shows how leadership returns to the preferred one.

## Why the list matters

The ISR is the answer to two questions every write and every failure asks:

- **Who has to have a record before it counts as committed?** Every member of the ISR. Not every
  replica, or a dead node would stop all writes; not just the leader, or a committed record could
  be lost with it.
- **Who may become leader when the leader goes?** A member of the ISR, because only they are
  known to have every committed record. Choosing anybody else is
  the unclean election a later section of this lesson is about.

A shrinking ISR is also the first sign of trouble an operator sees. A partition whose ISR is
smaller than its replica list is **under-replicated**, and lesson 16 puts that on the list of
things to alert on.
