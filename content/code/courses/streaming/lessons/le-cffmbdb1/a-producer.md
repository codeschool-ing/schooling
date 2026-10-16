---
title: A producer, and hearing back from it
version: 1
---

**Calling `produce` does not send a message. It puts the message in a buffer and returns at once**;
a thread inside the client library collects messages into batches, one per partition, and sends the
batches when they are full or have waited long enough. Whether a message reached the broker is
known only later, when the client calls a function you gave it, the **delivery report**. A program
that never looks at delivery reports does not know whether anything it produced was stored.

That is the common wrong picture: that `produce` returning means the message is in Kafka. Lesson 1's
`tills.py` got away with it because it called `flush` at the end, which waits for every message to
be acknowledged, and nothing went wrong. This producer says what happened to each message. Save it
as `~/work/producer.py`:

```schooling-example
{
  "file": "producer.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"producer.py: send sales to Kafka, and hear back about every one of them.\n\n    python producer.py [--count N] [--linger-ms MS] [--rate R]\n                       [--topic T] [--timeout-ms MS]\n\"\"\"\nimport argparse\nimport json\nimport time\nfrom collections import Counter\n\nfrom confluent_kafka import Producer\n\nSHOPS = [\"recife\", \"olinda\", \"caruaru\", \"natal\", \"joao-pessoa\"]\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--count\", type=int, default=10)\nargs.add_argument(\"--linger-ms\", type=int, default=5)\nargs.add_argument(\"--rate\", type=float, default=0)\nargs.add_argument(\"--topic\", default=\"sales\")\nargs.add_argument(\"--timeout-ms\", type=int, default=300000)\nargs = args.parse_args()\n",
      "note": "What it sends and how to call it. Ten sales by default, each keyed by its shop; `--rate` slows it down, which the batching experiment needs."
    },
    {
      "code": "producer = Producer({\n    \"bootstrap.servers\": \"localhost:9092\",\n    \"partitioner\": \"murmur2_random\",\n    \"linger.ms\": args.linger_ms,\n    \"batch.size\": 16384,\n    \"message.timeout.ms\": args.timeout_ms,\n})\n",
      "note": "The configuration. **`murmur2_random`** is lesson 3's partitioner, so the five shops reach all three partitions. `linger.ms` and `batch.size` shape the batches; `message.timeout.ms` is how long the client keeps trying before it gives up on a message."
    },
    {
      "code": "delivered, failed = Counter(), Counter()\n\n\ndef report(err, msg):\n    if err is None:\n        delivered[msg.partition()] += 1\n    else:\n        failed[err.str()] += 1\n",
      "note": "**The delivery report.** The client calls it once for every message, from inside `poll` or `flush`, with an error or with the partition the message was stored in."
    },
    {
      "code": "\nfor n in range(1, args.count + 1):\n    shop = SHOPS[n % len(SHOPS)]\n    sale = {\"sale\": f\"{shop[:3]}-{n:06d}\", \"shop\": shop, \"book\": \"bk-01\", \"qty\": 1, \"cents\": 3990}\n    producer.produce(args.topic, key=shop, value=json.dumps(sale), on_delivery=report)\n    producer.poll(0)\n    if args.rate:\n        time.sleep(1 / args.rate)\n",
      "note": "The loop. `produce` only buffers the message; `poll(0)` gives the client a chance to run the reports of messages already answered, without waiting."
    },
    {
      "code": "left = producer.flush(30)\nprint(\"delivered per partition:\", dict(sorted(delivered.items())))\nfor reason, n in failed.items():\n    print(f\"failed: {n} x {reason}\")\nif left:\n    print(f\"still waiting after 30 s: {left}\")",
      "note": "`flush` waits, here for up to 30 seconds, until every message has a report, and returns how many still have none. Then the summary: what was delivered, per partition, and what failed, and why."
    }
  ]
}
```

Make a fresh `sales` topic and send the default ten sales. If you still have lesson 3's cluster,
`./cluster.sh stop`, `./cluster.sh new 1` and `./cluster.sh start` first, as lesson 3 did:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3
Created topic sales.
ubuntu@stream:~/work$ python producer.py
delivered per partition: {0: 4, 1: 4, 2: 2}
```

Ten delivery reports, all without error, counted by partition. With `murmur2_random`, Olinda and
João Pessoa go to partition 0, Caruaru and Natal to 1, Recife to 2, as lesson 3 found, and the ten
sales cycle through the five shops: four, four and two.

## Batching, and what linger.ms is for

**`linger.ms` is how long the client waits for more messages before it sends a batch that is not
full.** At 0 it sends as soon as it can; at 100 it holds a batch for up to a tenth of a second, so
that more messages can join it. `batch.size` caps a batch at 16 384 bytes. Send two hundred sales
at two hundred a second, once with each setting, to two topics of one partition:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic linger0 --partitions 1
Created topic linger0.
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic linger100 --partitions 1
Created topic linger100.
ubuntu@stream:~/work$ python producer.py --topic linger0 --count 200 --rate 200 --linger-ms 0
delivered per partition: {0: 200}
ubuntu@stream:~/work$ python producer.py --topic linger100 --count 200 --rate 200 --linger-ms 100
delivered per partition: {0: 200}
```

Then count the batches on disk with lesson 3's `kafka-dump-log.sh`, which prints one `baseOffset`
line per batch:

```
ubuntu@stream:~/work$ kafka-dump-log.sh --files ~/kafka-data/node1/log/linger0-0/00000000000000000000.log | grep -c baseOffset
197
ubuntu@stream:~/work$ kafka-dump-log.sh --files ~/kafka-data/node1/log/linger100-0/00000000000000000000.log | grep -c baseOffset
11
```

The same two hundred messages took **197 batches** with no linger and **11** with 100 ms. A message
arrived every 5 ms, so with no waiting nearly every message travelled alone; with a tenth of a second
of waiting, about eighteen shared each trip. That is the trade: each message waits up to 100 ms
longer, and the broker handles eighteen times fewer requests, each carrying more. Under heavy load
batches fill by size before the linger runs out, so the setting matters most at moderate rates like
this one. The program's default of 5 ms is also librdkafka's.

## When the broker is not there

Stop the cluster and send five sales, giving up on each after five seconds instead of the default
five minutes (`message.timeout.ms`, 300 000):

```
ubuntu@stream:~/work$ ./cluster.sh stop
node 1: stopped
ubuntu@stream:~/work$ python producer.py --count 5 --timeout-ms 5000 2>/dev/null
delivered per partition: {}
failed: 5 x Local: Message timed out
ubuntu@stream:~/work$ ./cluster.sh start
node 1: up on localhost:9092
```

`produce` accepted all five without complaint, because accepting into the buffer is all it does.
Five seconds later the client gave up on each of them and **said so in the delivery report**:
`Local: Message timed out`, where `Local` means the error was raised by the client, not sent by a
broker. Without the callback those five sales would have disappeared, and the program would have
exited normally. While it waits, librdkafka also writes a line to stderr for every failed attempt to
connect; `2>/dev/null` throws those away, which is why the command has it.

The timeout is a decision. Five minutes rides out a broker restart; five seconds turns a short
outage into lost sales. Either way the delivery report is where the program finds out, and what it
does then, whether it writes the sale to a file, retries later or stops the till, is the program's
choice. Lesson 7 comes back to what happens when the message did arrive and only the answer was lost.
