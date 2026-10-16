---
title: A Kafka cluster that loses nodes
version: 1
---

**This is one of the three heavy lessons lesson 1 warned about**: three Kafka nodes run at once, each on
the Java virtual machine. Stop the replication lab first (`docker compose down -v` in
`~/lab/replication`); `docker ps` should list nothing before you start.

Lesson 6 ran Kafka on one node, with `ReplicationFactor: 1`. Here it runs on three, and each partition
gets three copies. It lives in `~/lab/kafka-cluster`:

```sh
mkdir -p ~/lab/kafka-cluster && cd ~/lab/kafka-cluster
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "x-kafka: &kafka\n  image: apache/kafka:4.0.0\n  environment: &env\n    CLUSTER_ID: q1Sh-9_ISia_zwGINzRvyQ\n    KAFKA_PROCESS_ROLES: broker,controller\n    KAFKA_LISTENERS: PLAINTEXT://:9092,CONTROLLER://:9093\n    KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT\n    KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER\n    KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT", "note": "Three Kafka nodes, each both a broker and a controller, as in lesson 6 but three times. Everything they share is written once, under `x-kafka`, and each node adds its id and its own address. `CLUSTER_ID` must be the same on all three: it is how a node knows it is joining this cluster and not starting another."}, {"code": "    KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka-1:9093,2@kafka-2:9093,3@kafka-3:9093", "note": "The controllers that vote on the cluster's metadata: who leads each partition, which replicas are in sync. Three voters, so two of them are a majority."}, {"code": "    KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 3\n    KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 3\n    KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 2\n    KAFKA_HEAP_OPTS: \"-Xms384m -Xmx384m\"\nservices:\n  kafka-1:\n    <<: *kafka\n    hostname: kafka-1\n    environment:\n      <<: *env\n      KAFKA_NODE_ID: 1\n      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka-1:9092\n  kafka-2:\n    <<: *kafka\n    hostname: kafka-2\n    environment:\n      <<: *env\n      KAFKA_NODE_ID: 2\n      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka-2:9092\n  kafka-3:\n    <<: *kafka\n    hostname: kafka-3\n    environment:\n      <<: *env\n      KAFKA_NODE_ID: 3\n      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka-3:9092", "note": "Kafka's own internal topics get three copies too; the defaults assume a single node."}]}
```

Start it, and give the three nodes half a minute to find each other. Then the same shell function as
lesson 6, pointed at node 1:

```sh
docker compose up -d
kafka() { docker compose exec -T kafka-1 /opt/kafka/bin/kafka-$1.sh --bootstrap-server kafka-1:9092 "${@:2}"; }
```

The controllers first. They hold an election among themselves, and one of them leads the metadata:

```
ana@vm:~/lab/kafka-cluster$ kafka metadata-quorum describe --status
ClusterId:              q1Sh-9_ISia_zwGINzRvyQ
LeaderId:               2
LeaderEpoch:            1
HighWatermark:          66
MaxFollowerLag:         0
MaxFollowerLagTimeMs:   24
CurrentVoters:          [{"id": 1, "directoryId": null, "endpoints": ["CONTROLLER://kafka-1:9093"]}, {"id": 2, "directoryId": null, "endpoints": ["CONTROLLER://kafka-2:9093"]}, {"id": 3, "directoryId": null, "endpoints": ["CONTROLLER://kafka-3:9093"]}]
CurrentObservers:       []
```

## A topic with three copies of everything

Create `orders` with three partitions and three replicas each, and require **two in-sync replicas** for a
write to count:

```
ana@vm:~/lab/kafka-cluster$ kafka topics --create --topic orders --partitions 3 --replication-factor 3 --config min.insync.replicas=2
Created topic orders.
ana@vm:~/lab/kafka-cluster$ kafka topics --describe --topic orders
Topic: orders	TopicId: w_H_w3F-S5qbT7PtD_vEyw	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: orders	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 1	Leader: 2	Replicas: 2,3,1	Isr: 2,3,1	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 2	Leader: 3	Replicas: 3,1,2	Isr: 3,1,2	Elr: 	LastKnownElr: 
```

Each partition has a different leader, so the writes are spread over the three nodes, and each has all
three nodes as replicas. `Isr` is the list of **in-sync replicas**: the copies that are up to date with
the leader. A producer that asks for `acks=all` is told its message was written only when every replica
in that list has it, and `min.insync.replicas=2` refuses the write if the list is shorter than two.

## Stopping one node

Stop node 2 and look again, then write three orders:

```
ana@vm:~/lab/kafka-cluster$ docker compose stop kafka-2
 Container kafka-cluster-kafka-2-1 Stopping 
 Container kafka-cluster-kafka-2-1 Stopped 
ana@vm:~/lab/kafka-cluster$ kafka topics --describe --topic orders
Topic: orders	TopicId: w_H_w3F-S5qbT7PtD_vEyw	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: orders	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,3	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 1	Leader: 3	Replicas: 2,3,1	Isr: 3,1	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 2	Leader: 3	Replicas: 3,1,2	Isr: 3,1	Elr: 	LastKnownElr: 
ana@vm:~/lab/kafka-cluster$ printf "o-1\no-2\no-3\n" | kafka console-producer --topic orders --producer-property acks=all
```

Node 2 was the leader of partition 1, and partition 1 now has a new leader, node 3. Node 2 left every `Isr`,
which is down to two everywhere. And the three writes went through, because two copies of each still
exist. **One node lost, nothing lost, nothing refused.**

## Stopping a second

```
ana@vm:~/lab/kafka-cluster$ docker compose stop kafka-3
 Container kafka-cluster-kafka-3-1 Stopping 
 Container kafka-cluster-kafka-3-1 Stopped 
ana@vm:~/lab/kafka-cluster$ kafka topics --describe --topic orders
Topic: orders	TopicId: w_H_w3F-S5qbT7PtD_vEyw	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: orders	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 1	Leader: 1	Replicas: 2,3,1	Isr: 1	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 2	Leader: 1	Replicas: 3,1,2	Isr: 1	Elr: 	LastKnownElr: 
ana@vm:~/lab/kafka-cluster$ printf "o-4\n" | kafka console-producer --topic orders --producer-property acks=all
[2026-10-10 06:16:57,313] WARN [Producer clientId=console-producer] Got error produce response with correlation id 5 on topic-partition orders-1, retrying (2 attempts left). Error: NOT_ENOUGH_REPLICAS (org.apache.kafka.clients.producer.internals.Sender)
[2026-10-10 06:16:57,410] WARN [Producer clientId=console-producer] Got error produce response with correlation id 6 on topic-partition orders-1, retrying (1 attempts left). Error: NOT_ENOUGH_REPLICAS (org.apache.kafka.clients.producer.internals.Sender)
[2026-10-10 06:16:57,618] WARN [Producer clientId=console-producer] Got error produce response with correlation id 7 on topic-partition orders-1, retrying (0 attempts left). Error: NOT_ENOUGH_REPLICAS (org.apache.kafka.clients.producer.internals.Sender)
[2026-10-10 06:16:58,097] ERROR Error when sending message to topic orders with key: null, value: 3 bytes with error: (org.apache.kafka.clients.producer.internals.ErrorLoggingCallback)
org.apache.kafka.common.errors.NotEnoughReplicasException: Messages are rejected since there are fewer in-sync replicas than required.
```

Now each partition has one in-sync replica, below the minimum of two, and the producer is refused with
`NOT_ENOUGH_REPLICAS`, retries, and gives up. **Kafka is choosing consistency**, in lesson 8's sense:
it would rather refuse a write than accept one that exists on a single disk. The same producer with
`acks=1`, which asks only the leader, is accepted without a word:

```
ana@vm:~/lab/kafka-cluster$ printf "o-5\n" | kafka console-producer --topic orders --producer-property acks=1
```

That message exists on node 1 alone, and if node 1's disk failed now it would be gone after the producer
had been told it was written. `acks=all` with `min.insync.replicas=2` and three replicas is the common
production setting for exactly this reason: it survives one failure without refusing anything, and it
refuses rather than lie after two.

Kafka's partitions do not use a majority vote for their data, by the way. They use the in-sync list, so
a partition with three replicas could keep writing with two, or with one if you allowed it. The
majority from the previous section is what the **controllers** use, among themselves, to agree on who
leads each partition.

## Bringing them back

Start the two nodes again. They rejoin, catch up from the leaders, and return to every `Isr`. Then read
the topic from the beginning:

```
ana@vm:~/lab/kafka-cluster$ docker compose start kafka-2 kafka-3
 Container kafka-cluster-kafka-2-1 Starting 
 Container kafka-cluster-kafka-3-1 Starting 
 Container kafka-cluster-kafka-2-1 Started 
 Container kafka-cluster-kafka-3-1 Started 
ana@vm:~/lab/kafka-cluster$ sleep 15; kafka topics --describe --topic orders
Topic: orders	TopicId: w_H_w3F-S5qbT7PtD_vEyw	PartitionCount: 3	ReplicationFactor: 3	Configs: min.insync.replicas=2
	Topic: orders	Partition: 0	Leader: 1	Replicas: 1,2,3	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 1	Leader: 1	Replicas: 2,3,1	Isr: 1,2,3	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 2	Leader: 1	Replicas: 3,1,2	Isr: 1,2,3	Elr: 	LastKnownElr: 
ana@vm:~/lab/kafka-cluster$ kafka console-consumer --topic orders --from-beginning --timeout-ms 20000 2>/dev/null | sort
o-1
o-2
o-3
o-5
```

`o-1` to `o-3` and `o-5` are there; `o-4`, the refused write, is not, and its producer was told so.
Nothing that was confirmed was lost. Stop the cluster before the next section:

```sh
docker compose down -v
```
