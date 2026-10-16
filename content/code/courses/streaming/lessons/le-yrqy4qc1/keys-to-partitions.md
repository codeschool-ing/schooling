---
title: Which partition a key lands in
version: 1
---

**A producer sends a message with a key to the partition its key hashes to, and every message with
that key goes to the same one.** That is the rule lesson 2 asked for: one key, one log, so the
events about one shop stay in the order the shop wrote them. Messages with no key are spread over
the partitions instead, and keep no order with each other.

The common belief is that the broker does this. It does not. **The producer chooses the partition,
in the client library, before the message leaves the program**, and the broker stores what it is
given. That puts the hash function in the client, and different clients ship different ones.

A small producer makes this visible. It sends whatever `KEY=VALUE` pairs it is given and prints the
partition and offset each one was stored at, which the broker reports back once it has the
message. Save this as `~/work/keys.py`:

```schooling-example
{
  "file": "keys.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"keys.py: send KEY=VALUE messages to a topic and say where each one landed.\n\n    python keys.py [--partitioner NAME] TOPIC KEY=VALUE...\n\nA VALUE of - sends a message with no value at all.\n\"\"\"\nimport argparse\n\nfrom confluent_kafka import Producer\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--partitioner\")\nargs.add_argument(\"topic\")\nargs.add_argument(\"pairs\", nargs=\"+\")\nargs = args.parse_args()\n",
      "note": "What it does. It sends whatever pairs you give it, so the same program serves this section and the compaction one."
    },
    {
      "code": "config = {\"bootstrap.servers\": \"localhost:9092\"}\nif args.partitioner:\n    config[\"partitioner\"] = args.partitioner\nproducer = Producer(config)\n",
      "note": "The producer, and the one setting this section is about. **Left out, the client uses its own default partitioner.**"
    },
    {
      "code": "\ndef landed(err, msg):\n    if err:\n        print(f\"{msg.key().decode()}: {err}\")\n    else:\n        print(f\"{msg.key().decode():<12} partition {msg.partition()}  offset {msg.offset()}\")\n",
      "note": "The delivery report. The client calls it once per message, after the broker has answered, with the partition and offset the message was given."
    },
    {
      "code": "\nfor pair in args.pairs:\n    key, value = pair.split(\"=\", 1)\n    producer.produce(args.topic, key=key, value=None if value == \"-\" else value,\n                     on_delivery=landed)\nproducer.flush()",
      "note": "One message per pair. `flush` waits for every report before the program ends."
    }
  ]
}
```

Make a topic of three partitions and send one message per shop:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic shops --partitions 3
Created topic shops.
ubuntu@stream:~/work$ python keys.py shops recife=py olinda=py caruaru=py natal=py joao-pessoa=py
recife       partition 1  offset 0
olinda       partition 1  offset 1
natal        partition 1  offset 2
joao-pessoa  partition 1  offset 3
caruaru      partition 0  offset 0
```

Four of the five shops landed in partition 1, Caruaru in partition 0, and **nothing in partition
2**. That is not a fault: five keys hashed into three buckets is a small sample, and an uneven one
is what a small sample gives. It does mean a topic with three partitions is, for these keys, a topic
with two. The offsets count up inside each partition, which is why Caruaru's message is at offset 0
while Natal's is at 2.

**The same key goes to the same partition for as long as the number of partitions does not change.** The client did the hashing: the Python client is built on librdkafka, a
library in C, and its default partitioner, `consistent_random`, takes a CRC32 of the key.

## Kafka's own tools hash differently

Now send the same five keys with Kafka's console producer, which is written in Java, and read the
topic back with the partition and key of each message printed. `parse.key=true` tells the producer
that each line is a key, a `:`, and a value:

```
ubuntu@stream:~/work$ printf "recife:java\nolinda:java\ncaruaru:java\nnatal:java\njoao-pessoa:java\n" | kafka-console-producer.sh --bootstrap-server localhost:9092 --topic shops --reader-property parse.key=true --reader-property key.separator=:
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic shops --from-beginning --max-messages 10 --formatter-property print.partition=true --formatter-property print.key=true
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
Partition:1	recife	py
Partition:1	olinda	py
Partition:1	natal	py
Partition:1	joao-pessoa	py
Partition:1	caruaru	java
Partition:1	natal	java
Partition:2	recife	java
Partition:0	caruaru	py
Partition:0	olinda	java
Partition:0	joao-pessoa	java
Processed a total of 10 messages
```

Read the consumer's output by key. Recife, which the Python client put in partition 1, went to
partition **2** from Java; Olinda and João Pessoa went to partition 0 instead of 1. Only Caruaru and
Natal happen to agree, and the agreement is luck. **The Java client hashes keys with murmur2**,
which is a different function from CRC32, so the same key gives a different number.

This matters as soon as two programs in two languages write the same topic. A till written in
Python and a back-office service written in Java, both writing Recife's stock changes, would put
them in two partitions, and lesson 2 showed what reading one key's events out of order does.
librdkafka has the fix built in: `murmur2_random`, a copy of the Java partitioner, which is what
`keys.py`'s `--partitioner` option sets:

```
ubuntu@stream:~/work$ python keys.py --partitioner murmur2_random shops recife=m2 olinda=m2 caruaru=m2 natal=m2 joao-pessoa=m2
caruaru      partition 1  offset 6
natal        partition 1  offset 7
recife       partition 2  offset 1
olinda       partition 0  offset 3
joao-pessoa  partition 0  offset 4
```

Recife to 2, Olinda and João Pessoa to 0, Caruaru and Natal to 1: exactly where Java put them.
**When clients in more than one language write the same topic, set `partitioner` to
`murmur2_random` in every librdkafka-based client**, the Python, Go and .NET ones among them. The
`_random` part is about messages with no key, which it spreads at random. The rest of this course
keeps the default where only Python writes, and lesson 4's producer sets `murmur2_random`, so its
sales reach all three partitions.
