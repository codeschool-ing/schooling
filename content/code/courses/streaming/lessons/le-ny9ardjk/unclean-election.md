---
title: Unclean leader election: available, or correct
version: 1
---

**When every replica in a partition's ISR is gone and only an out-of-date one is left, Kafka has
two choices.** It can wait for an in-sync replica to come back, and the partition is unavailable
until then. Or it can make the out-of-date one leader, and lose every record it did not have.
Making it leader is an **unclean leader election**. It is off by default,
`unclean.leader.election.enable=false`, and this section provokes the situation to show what the
default protects.

## Setting up the loss

The situation needs a partition whose last in-sync replica dies after the others. A topic with two
replicas placed on nodes 2 and 3 by hand makes it easy to follow; `--replica-assignment 2:3` means
one partition, with replicas on node 2 and node 3, node 2 first. Ten sales go in with both replicas
in sync. Then node 3 dies, and ten more sales go in with node 2 alone, which
`min.insync.replicas=1` on this topic allows:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic till-log --replica-assignment 2:3 --config min.insync.replicas=1
Created topic till-log.
ubuntu@stream:~/work$ python acks.py --topic till-log
acks=all: 10 delivered
partition 0: offsets 0 to 9
ubuntu@stream:~/work$ ./cluster.sh kill 3
node 3: killed
ubuntu@stream:~/work$ sleep 15; kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic till-log
Topic: till-log	TopicId: utv0ygFwQ-OUoRoOKuvJXA	PartitionCount: 1	ReplicationFactor: 2	Configs: min.insync.replicas=1
	Topic: till-log	Partition: 0	Leader: 2	Replicas: 2,3	Isr: 2	Elr: 	LastKnownElr: 
ubuntu@stream:~/work$ python acks.py --topic till-log
acks=all: 10 delivered
partition 0: offsets 10 to 19
```

Offsets 0 to 9 went to both replicas. After node 3 died, the ISR shrank to node 2 alone, and
offsets 10 to 19 were acknowledged by it, so they are on node 2 and nowhere else. Now node 2 dies
too, and node 3, which stopped at offset 10, comes back:

```
ubuntu@stream:~/work$ ./cluster.sh kill 2
node 2: killed
ubuntu@stream:~/work$ ./cluster.sh start 3
node 3: up on localhost:9094
ubuntu@stream:~/work$ sleep 15; kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic till-log
Topic: till-log	TopicId: utv0ygFwQ-OUoRoOKuvJXA	PartitionCount: 1	ReplicationFactor: 2	Configs: min.insync.replicas=1
	Topic: till-log	Partition: 0	Leader: none	Replicas: 2,3	Isr: 	Elr: 2	LastKnownElr: 2
ubuntu@stream:~/work$ python acks.py --topic till-log --count 1
acks=all: 1 _MSG_TIMED_OUT
```

**`Leader: none`**: the partition is offline. Node 3 is alive and holds a copy, and Kafka will not
use it, because it is not in the ISR and does not have the last ten sales. Producers wait and time
out; consumers get nothing.

## Elr: the replicas that may still lead cleanly

The two columns that were empty until now have filled in. **`Elr` is the list of Eligible Leader
Replicas**, from KIP-966, which Kafka 4 brought in: replicas that left the ISR while it was already
at or below `min.insync.replicas`, and so are known to hold every committed record. Node 2 is in
it, because it was the last in-sync replica when the ISR lost it. When node 2 comes back, Kafka can
make it leader cleanly and lose nothing. `LastKnownElr` keeps the last such list when even the Elr
is empty, so an operator can see which node to bring back first.

So the clean way out is to restart node 2. The unclean way is to tell Kafka to use what it has:

```
ubuntu@stream:~/work$ kafka-leader-election.sh --bootstrap-server localhost:9092 --election-type unclean --topic till-log --partition 0
Successfully completed leader election (UNCLEAN) for partitions till-log-0
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic till-log
Topic: till-log	TopicId: utv0ygFwQ-OUoRoOKuvJXA	PartitionCount: 1	ReplicationFactor: 2	Configs: min.insync.replicas=1
	Topic: till-log	Partition: 0	Leader: 3	Replicas: 2,3	Isr: 3	Elr: 	LastKnownElr: 
ubuntu@stream:~/work$ kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic till-log
till-log:0:10
```

The partition is back, led by node 3, and its log ends at offset 10. **The ten sales written while
node 3 was down are gone**: they were acknowledged to the producer, with `acks=all`, and they no
longer exist. When node 2 comes back, it does not bring them back. It finds that the leader's log
diverges from its own at offset 10, and it **truncates** its log to match:

```
ubuntu@stream:~/work$ ./cluster.sh start 2
node 2: up on localhost:9093
ubuntu@stream:~/work$ sleep 10; kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic till-log
Topic: till-log	TopicId: utv0ygFwQ-OUoRoOKuvJXA	PartitionCount: 1	ReplicationFactor: 2	Configs: min.insync.replicas=1
	Topic: till-log	Partition: 0	Leader: 3	Replicas: 2,3	Isr: 2,3	Elr: 	LastKnownElr: 
ubuntu@stream:~/work$ kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic till-log
till-log:0:10
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic till-log --from-beginning --timeout-ms 5000 2>/dev/null | wc -l
10
```

Both replicas are in sync again, the end offset is still 10, and a consumer reading from the
beginning gets ten sales.

## Which to choose

| | unclean election off (the default) | unclean election on |
|---|---|---|
| the last in-sync replica dies | the partition stops until it returns | an out-of-date replica takes over at once |
| what is lost | time | every record the new leader did not have |
| who finds out | everybody, at once | nobody, until the numbers do not add up |

For sales, payments, stock and anything somebody will reconcile later, the default is the only
sensible choice: an outage is visible and ends, a hole in the data is silent and permanent. Turning
it on is defensible for data that is only worth anything fresh, such as positions of vehicles or
metrics, where an hour of nothing is worse than a few lost points. Either way it is a decision per
topic, `unclean.leader.election.enable` set with `kafka-configs.sh`, and the leader-election tool
above is the same decision made once, by hand, by somebody who has decided the missing records are
worth less than the outage.
