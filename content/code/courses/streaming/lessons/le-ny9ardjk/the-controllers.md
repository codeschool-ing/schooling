---
title: The controllers, and what a majority is for
version: 1
---

**Somebody has to decide who leads each partition and who is in its ISR, and in Kafka 4 that
somebody is a small group of controllers that agree by voting.** The controllers keep the
cluster's metadata — topics, partitions, leaders, ISRs, configurations — in a log of their own,
`__cluster_metadata`, the directory lesson 1 found on disk. One controller at a time is the
**active** one and writes to that log; the others copy it, and a change counts once a majority of
them has it. The protocol is called KRaft, Kafka's version of Raft.

Older Kafka kept the same metadata in a separate system, ZooKeeper. Kafka 4.0 removed it, so a
Kafka 4 cluster is only Kafka processes.

In this lab each node is a broker and a controller at once, which is what `process.roles=broker,controller`
in its configuration says. A production cluster usually separates the two jobs: three or five
small machines run only the controllers, with `process.roles=controller`, and the brokers that
store data run with `process.roles=broker`. Then a broker failure never touches the voting, and a
busy broker never slows it down.

## Who is voting

```
ubuntu@stream:~/work$ kafka-metadata-quorum.sh --bootstrap-server localhost:9092 describe --status
ClusterId:              YCLAkZhFSxymvym7xHcgzQ
LeaderId:               1
LeaderEpoch:            1
HighWatermark:          426
MaxFollowerLag:         0
MaxFollowerLagTimeMs:   0
CurrentVoters:          [{"id": 1, "endpoints": ["CONTROLLER://localhost:9192"]}, {"id": 2, "endpoints": ["CONTROLLER://localhost:9193"]}, {"id": 3, "endpoints": ["CONTROLLER://localhost:9194"]}]
CurrentObservers:       []
```

`LeaderId` is the active controller, which is a different thing from the leader of a partition:
one node leads the votes, and every node leads some partitions. `CurrentVoters` lists the three
voters with their controller ports, 9192 to 9194. `HighWatermark` is the same idea as a
partition's: the end of what a majority of the voters has written. `MaxFollowerLag` is how far the
slowest voter is behind, in records.

## Losing the majority

Three voters need two to agree. **Lose one and the other two carry on; lose two and the one left
cannot decide anything**, because it cannot tell whether it is the survivor or the one cut off
from the others. It does not guess. Kill nodes 2 and 3 and ask node 1 to do something that
needs a decision, and then ask it who is in charge:

```
ubuntu@stream:~/work$ ./cluster.sh kill 2
node 2: killed
ubuntu@stream:~/work$ ./cluster.sh kill 3
node 3: killed
ubuntu@stream:~/work$ timeout 60 kafka-topics.sh --bootstrap-server localhost:9092 --create --topic returns --partitions 3 2>/dev/null; echo "exit $?"
exit 124
ubuntu@stream:~/work$ timeout 30 kafka-metadata-quorum.sh --bootstrap-server localhost:9092 describe --status 2>/dev/null; echo "exit $?"
exit 124
```

Both commands printed nothing and waited until `timeout` ended them, and `timeout` reports that
with exit status 124.

Node 1 is running and its port answers; what it cannot do is change the cluster. The `create`
never got an answer, and no leadership or ISR can move while the majority is missing.

**The cure is to bring back enough voters to make a majority**, not to make the survivor decide
alone:

```
ubuntu@stream:~/work$ ./cluster.sh start
node 1: already running
node 1: up on localhost:9092
node 2: up on localhost:9093
node 3: up on localhost:9094
ubuntu@stream:~/work$ kafka-metadata-quorum.sh --bootstrap-server localhost:9092 describe --status | grep -E "LeaderId|HighWatermark"
LeaderId:               1
HighWatermark:          499
```

`LeaderId` is node 1 again and the `HighWatermark` has moved on, from 426 before the failure to
499: the controllers can vote again, and the metadata log is being written. The arithmetic is why controllers come in odd numbers: three survive one failure, five survive two,
and four survive only one, like three, while costing a machine more.

## In this lab, and in a real one

Because every node here is also a controller, losing two nodes of three loses both the data
copies and the votes at once. That is why the section on acks raised `min.insync.replicas` to see
a refusal instead of killing a second node. With separate controllers, killing two brokers of
three would leave the voting intact, the ISRs would shrink to one, and producers with `acks=all`
would get `NotEnoughReplicas`, exactly as they did there.
