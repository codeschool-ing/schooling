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
```

KEYS-DEFAULT

## Kafka's own tools hash differently

Now send the same five keys with Kafka's console producer, which is written in Java, and read the
topic back with the partition and key of each message printed. `parse.key=true` tells the producer
that each line is a key, a `:`, and a value:

```
ubuntu@stream:~/work$ printf "recife:java\nolinda:java\ncaruaru:java\nnatal:java\njoao-pessoa:java\n" | kafka-console-producer.sh --bootstrap-server localhost:9092 --topic shops --reader-property parse.key=true --reader-property key.separator=:
```

KEYS-JAVA

The `murmur2_random` partitioner is librdkafka's copy of the Java one, and it is the line in
`keys.py` that the `--partitioner` option sets:

```
ubuntu@stream:~/work$ python keys.py --partitioner murmur2_random shops recife=m2 olinda=m2 caruaru=m2 natal=m2 joao-pessoa=m2
```

KEYS-MURMUR
