---
title: Kafka in practice
version: 1
---

Kafka ships with command-line tools for every one of its operations, inside the container at
`/opt/kafka/bin`. Their names are long and they all need the broker's address, so define a short shell
function for the rest of the lesson, in `~/lab/brokers`:

```sh
kafka() { docker compose exec -T kafka /opt/kafka/bin/kafka-$1.sh --bootstrap-server localhost:9092 "${@:2}"; }
```

`kafka topics …` now runs `kafka-topics.sh` in the container, against the broker it runs beside. The
function lasts until the shell is closed; type it again in a new one.

## A topic with three partitions

```
ana@vm:~/lab/brokers$ kafka topics --create --topic orders --partitions 3
Created topic orders.
ana@vm:~/lab/brokers$ kafka topics --describe --topic orders
Topic: orders	TopicId: r7mFHLM1RNGzSBSTEfBxgA	PartitionCount: 3	ReplicationFactor: 1	Configs: segment.bytes=1073741824
	Topic: orders	Partition: 0	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 1	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 2	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr: 
```

Each partition has a **leader**, the broker that takes its writes, and a list of **replicas**. With one
broker there is one of each, broker 1, and `ReplicationFactor: 1` means a disk lost on that broker is the
topic lost; lesson 10 is about doing better.

## Writing with keys

The console producer reads lines from its input. With `parse.key=true` and `:` as the separator, each
line is a key and a value; the key here is the customer who placed the order:

```
ana@vm:~/lab/brokers$ printf "ana:order 1\nbruno:order 2\nana:order 3\ncarla:order 4\nbruno:order 5\n" | kafka console-producer --topic orders --property parse.key=true --property key.separator=:
```

## Reading as a group

The console consumer joins a group with `--group`, starts at the oldest message the first time the
group reads, and with three `print` properties shows each message's partition, offset and key:

```
ana@vm:~/lab/brokers$ kafka console-consumer --topic orders --group email --from-beginning --max-messages 5 --property print.partition=true --property print.offset=true --property print.key=true
Partition:1	Offset:0	ana	order 1
Partition:1	Offset:1	ana	order 3
Partition:2	Offset:0	bruno	order 2
Partition:2	Offset:1	carla	order 4
Partition:2	Offset:2	bruno	order 5
Processed a total of 5 messages
```

Read the output against the model. **Every message keyed `ana` is in partition 1, and in the order they
were written**: order 1 at offset 0, order 3 at offset 1. Bruno and carla hashed to partition 2, where
their three orders sit in the order they were sent. Partition 0 received nothing; with three keys and
three partitions, nothing promises an even spread. And **the consumer did not print the orders in the
order they were produced**: it printed partition 1 and then partition 2, because across partitions there
is no order to keep.

Kafka has stored the group's position:

```
ana@vm:~/lab/brokers$ kafka consumer-groups --describe --group email

Consumer group 'email' has no active members.

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
email           orders          0          0               0               0               -               -               -
email           orders          1          2               2               0               -               -               -
email           orders          2          3               3               0               -               -               -
```

`CURRENT-OFFSET` is where the group will read next in each partition, `LOG-END-OFFSET` is where the next
message will be written, and **`LAG` is the difference**: how many messages the group has not read yet.
All zero, because the group has read everything. Lag is the number to watch on any consumer: steady or
falling, the consumers keep up; growing, they do not, and the oldest unread message gets older by the
minute.
