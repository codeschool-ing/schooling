---
title: Exactly once inside Kafka: read, write and commit in one transaction
version: 1
---

**A program whose input and output are both Kafka topics can be exactly-once, because the offset
it commits can be written inside the same transaction as its output.** The consumer's commit is a
write to `__consumer_offsets`, an ordinary topic, and `send_offsets_to_transaction` adds it to the
producer's transaction. Then the output and the record of having produced it are committed
together, or aborted together, and a crash at any point leaves one of two states: the batch done
and remembered, or neither.

This is the pattern Kafka Streams runs under `processing.guarantee=exactly_once_v2`, and Flink's
Kafka sink in its exactly-once mode; lesson 13 meets both. Here it is by hand, in Python.

## A copy that survives a crash

The job is small on purpose: read `sales`, and copy every sale of 100.00 or more to a topic
`big-sales`. Each batch of up to ten sales is one transaction. Save it as `~/work/eos_copy.py`:

```schooling-example
{
  "file": "eos_copy.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"eos_copy.py: copy the sales of 100.00 or more from `sales` to `big-sales`, exactly once.\n\n    python eos_copy.py [--crash-after N]\n\"\"\"\nimport argparse\nimport json\nimport os\n\nfrom confluent_kafka import Consumer, Producer\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--crash-after\", type=int, default=0)\nargs = args.parse_args()\n",
      "note": "`--crash-after N` ends the process abruptly after reading N sales, in the middle of a transaction."
    },
    {
      "code": "consumer = Consumer({\"bootstrap.servers\": \"localhost:9092\",\n                     \"group.id\": \"eos-copy\",\n                     \"auto.offset.reset\": \"earliest\",\n                     \"enable.auto.commit\": False,\n                     \"isolation.level\": \"read_committed\"})",
      "note": "**The consumer never commits on its own**: auto commit is off and the program never calls `commit`. It reads with `read_committed`, so it would not copy anything a previous run aborted, if its input were itself written in transactions."
    },
    {
      "code": "producer = Producer({\"bootstrap.servers\": \"localhost:9092\",\n                     \"transactional.id\": \"eos-copy\"})\nproducer.init_transactions()\nconsumer.subscribe([\"sales\"])\n",
      "note": "The `transactional.id` is fixed, so a restarted copy is recognised as the same producer. **`init_transactions` aborts whatever the crashed run left open.**"
    },
    {
      "code": "read = copied = 0\nwhile batch := consumer.consume(num_messages=10, timeout=10):\n    producer.begin_transaction()\n    for msg in batch:\n        read += 1\n        if json.loads(msg.value())[\"cents\"] >= 10000:\n            producer.produce(\"big-sales\", key=msg.key(), value=msg.value())\n            copied += 1",
      "note": "One transaction per batch. The copies go out as ordinary `produce` calls; they reach the log at once, and become visible to a `read_committed` reader only at the commit."
    },
    {
      "code": "        if read == args.crash_after:\n            producer.flush()\n            print(f\"crashed after reading {read} sales, {copied} of them copied\", flush=True)\n            os._exit(1)",
      "note": "The crash flushes first, so the copies of the interrupted batch are really in the log and the abort has something to hide."
    },
    {
      "code": "    producer.send_offsets_to_transaction(consumer.position(consumer.assignment()),\n                                         consumer.consumer_group_metadata())\n    producer.commit_transaction()\nconsumer.close()\nprint(f\"read {read} sales, copied {copied}\")",
      "note": "**The consumer's position goes into the producer's transaction**, under the consumer's group. Committing the transaction commits the copies and the offsets in one step."
    }
  ]
}
```

The `sales` topic from the earlier sections still holds its fifty sales, and the five from
`idempotent.py`. Make the output topic, crash the copy after 25 sales, and run it again:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic big-sales --partitions 1
```

@@EOS@@
