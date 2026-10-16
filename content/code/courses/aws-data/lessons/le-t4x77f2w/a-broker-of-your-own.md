---
title: A Kafka broker of your own
version: 1
---

**moto has no Kafka in it, so this section uses the real one.** Apache Kafka is open source, it runs
on Java, and one broker on a laptop is a complete Kafka: topics, partitions, offsets and consumer
groups behave exactly as they do on MSK, with one machine instead of three. What one broker cannot
show is replication, which is the next section's subject, and it says where.

Java first, then the release, which is about 130 MB, into `~/aws`:

```sh
sudo apt-get install -y openjdk-21-jre-headless
cd ~/aws
curl -sS -O https://archive.apache.org/dist/kafka/4.4.0/kafka_2.13-4.4.0.tgz
```

```
ana@laptop:~/aws$ java -version
openjdk version "21.0.12.1" 2026-08-18
OpenJDK Runtime Environment (build 21.0.12.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 21.0.12.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
ana@laptop:~/aws$ du -h kafka_2.13-4.4.0.tgz
130M	kafka_2.13-4.4.0.tgz
ana@laptop:~/aws$ tar -xzf kafka_2.13-4.4.0.tgz && ls kafka_2.13-4.4.0
LICENSE
NOTICE
bin
config
libs
licenses
site-docs
```

**`archive.apache.org` keeps every Kafka release for good**, which is why the lesson uses it rather
than the download mirrors, which keep only the latest few. `2.13` is the version of Scala the release
was built with and changes nothing for you; `4.4.0` is Kafka's version.

## Format once, start in a third terminal

A broker's log directory has to be formatted before the first start, with an id for the cluster.
In KRaft mode, the only mode Kafka 4 has, the broker keeps its own metadata and needs nothing else running beside it. From here on your terminal works inside the release, so `cd kafka_2.13-4.4.0` first:

```
ana@laptop:~/aws/kafka_2.13-4.4.0$ KAFKA_CLUSTER_ID="$(bin/kafka-storage.sh random-uuid)" && bin/kafka-storage.sh format --standalone -t $KAFKA_CLUSTER_ID -c config/server.properties
Bootstrap metadata: BootstrapMetadata(records=[ApiMessageAndVersion(FeatureLevelRecord(name='metadata.version', featureLevel=33) at version 0), ApiMessageAndVersion(FeatureLevelRecord(name='eligible.leader.replicas.version', featureLevel=1) at version 0), ApiMessageAndVersion(FeatureLevelRecord(name='group.version', featureLevel=1) at version 0), ApiMessageAndVersion(FeatureLevelRecord(name='share.version', featureLevel=2) at version 0), ApiMessageAndVersion(FeatureLevelRecord(name='streams.version', featureLevel=1) at version 0), ApiMessageAndVersion(FeatureLevelRecord(name='transaction.version', featureLevel=2) at version 0)], metadataVersionLevel=33, source=format command)
Formatting dynamic metadata voter directory /tmp/kraft-combined-logs with metadata.version 4.4-IV2.
```

**The log directory is `/tmp/kraft-combined-logs`**, as the shipped `config/server.properties` says,
so a reboot of the machine empties it and the format has to be done again. Then open a third
terminal, beside moto's and yours, and start the broker in the foreground there:

```sh
cd ~/aws/kafka_2.13-4.4.0
bin/kafka-server-start.sh config/server.properties
```

It prints its log and stays running, listening on `localhost:9092`. `Ctrl+C` stops it. Every command
below runs in your usual terminal, from `~/aws/kafka_2.13-4.4.0`.

## A topic, and records with keys

Three partitions, and one copy of each, because there is one broker:

```
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --topic orders --partitions 3 --replication-factor 1
Created topic orders.
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic orders
Topic: orders	TopicId: dlW2N4ajSJu4zfoc7UnRyg	PartitionCount: 3	ReplicationFactor: 1	Configs: min.insync.replicas=1,segment.bytes=1073741824
	Topic: orders	Partition: 0	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 1	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr: 
	Topic: orders	Partition: 2	Leader: 1	Replicas: 1	Isr: 1	Elr: 	LastKnownElr: 
```

The same four events as lesson 20's producer began with, sent with the console producer, which
reads one record per line and splits each line at the `:` into a key and a value. Then a console
consumer in the group `fraud` reads them, printing each record's partition and offset:

```
ana@laptop:~/aws/kafka_2.13-4.4.0$ printf 'c-17:o-101 placed\nc-02:o-102 placed\nc-17:o-101 packed\nc-05:o-103 placed\n' | bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic orders --reader-property parse.key=true --reader-property key.separator=:
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic orders --group fraud --from-beginning --max-messages 4 --formatter-property print.partition=true --formatter-property print.offset=true --formatter-property print.key=true
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
Partition:0	Offset:0	c-02	o-102 placed
Partition:1	Offset:0	c-17	o-101 placed
Partition:1	Offset:1	c-17	o-101 packed
Partition:2	Offset:0	c-05	o-103 placed
Processed a total of 4 messages
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group fraud

Consumer group 'fraud' has no active members.

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
fraud           orders          0          1               1               0               -               -               -
fraud           orders          1          2               2               0               -               -               -
fraud           orders          2          1               1               0               -               -               -
```

**`c-17` went to partition 1, `c-02` to 0 and `c-05` to 2**, by murmur2 rather than MD5, and the
two events of `c-17` sit at offsets 0 and 1 of the same partition, in the order they were sent. The
first line of the consumer's output is Kafka advertising a newer protocol for rebalancing groups; it
is a notice, not an error. The last command asks the broker what it knows about the group: for each
partition, the offset the group committed, the end of the log, and the difference, the **lag**. All
three are 0, because `fraud` has read everything. The group "has no active members" because the
console consumer exited; its offsets stay on the broker.

## Lag, and reading it again

Three more events, and the group described again before anybody reads them:

```
ana@laptop:~/aws/kafka_2.13-4.4.0$ printf 'c-17:o-101 delivered\nc-02:o-102 packed\nc-05:o-103 cancelled\n' | bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic orders --reader-property parse.key=true --reader-property key.separator=:
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group fraud

Consumer group 'fraud' has no active members.

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
fraud           orders          0          1               2               1               -               -               -
fraud           orders          1          2               3               1               -               -               -
fraud           orders          2          1               2               1               -               -               -
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic orders --group fraud --max-messages 3 --formatter-property print.partition=true --formatter-property print.offset=true --formatter-property print.key=true
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
Partition:0	Offset:1	c-02	o-102 packed
Partition:1	Offset:2	c-17	o-101 delivered
Partition:2	Offset:1	c-05	o-103 cancelled
Processed a total of 3 messages
```

**The lag is 1 on every partition**, one unread record each, and the consumer started next, in the
same group, read exactly those three and nothing it had read before: it carried on from the committed
offsets. Lag is the number an operator watches. A group whose lag grows is a group falling behind,
and on a topic with a retention of a day, a lag older than a day is records lost, which is lesson 20's
retention warning in Kafka's terms.

**Replay is one command**, run while the group has no active members:

```
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group fraud --topic orders --reset-offsets --to-earliest --execute

GROUP           TOPIC           PARTITION  NEW-OFFSET
fraud           orders          0          0
fraud           orders          1          0
fraud           orders          2          0
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic orders --group fraud --max-messages 7 --formatter-property print.partition=true --formatter-property print.offset=true --formatter-property print.key=true
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
Partition:0	Offset:0	c-02	o-102 placed
Partition:0	Offset:1	c-02	o-102 packed
Partition:1	Offset:0	c-17	o-101 placed
Partition:1	Offset:1	c-17	o-101 packed
Partition:1	Offset:2	c-17	o-101 delivered
Partition:2	Offset:0	c-05	o-103 placed
Partition:2	Offset:1	c-05	o-103 cancelled
Processed a total of 7 messages
```

All seven records came back, in order within each partition. This is the Kafka form of
`TRIM_HORIZON`, done to a whole group at once, and it is how a team reprocesses after fixing a bug.
`--to-datetime` resets to a time instead, which is `AT_TIMESTAMP`.

## Retention and the log on disk

```
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name orders --alter --add-config retention.ms=604800000,retention.bytes=10737418240
Completed updating config for topic orders.
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name orders --describe
Dynamic configs for topic orders are:
  retention.bytes=10737418240 sensitive=false synonyms={DYNAMIC_TOPIC_CONFIG:retention.bytes=10737418240, DEFAULT_CONFIG:log.retention.bytes=-1}
  retention.ms=604800000 sensitive=false synonyms={DYNAMIC_TOPIC_CONFIG:retention.ms=604800000}
ana@laptop:~/aws/kafka_2.13-4.4.0$ ls /tmp/kraft-combined-logs/orders-1/
00000000000000000000.index
00000000000000000000.log
00000000000000000000.timeindex
leader-epoch-checkpoint
partition.metadata
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic orders
orders:0:2
orders:1:3
orders:2:2
```

**Seven days or 10 GB per partition, whichever comes first.** `604800000` is seven days in
milliseconds and `10737418240` is 10 GiB. The directory listing is partition 1's log on disk:
a **segment**, `00000000000000000000.log`, named after the first offset it holds, with two indexes
beside it, one by offset and one by time. Retention deletes whole segments, never single records, so
a partition can hold slightly more than its limit until its oldest segment is entirely past it. And
`kafka-get-offsets.sh` prints the end of each partition's log, `orders:1:3` meaning that partition 1
holds offsets 0 to 2.

When you are done, `Ctrl+C` in the broker's terminal stops it.
