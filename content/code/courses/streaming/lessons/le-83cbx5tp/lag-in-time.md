---
title: Lag in messages, and lag in seconds
version: 1
---

**A lag of a thousand messages says nothing on its own.** On a topic that receives a thousand
sales a second it is one second of delay, and nobody will notice. On a topic that receives one sale
a minute it is almost seventeen hours, and the website has been wrong since yesterday. The number
`kafka-consumer-groups.sh` prints is a count, and the question people ask about a stream is a
duration: *how old is the newest thing the consumer has dealt with?*

There are two ways to turn one into the other, and they answer slightly different questions.

**Divide by the rate.** If the lag is 400 messages and the consumer handles ten a second, it needs
forty seconds to catch up, provided nothing else arrives. That is the time to drain, and it is the
right number for deciding whether to add consumers. It goes wrong when the rate changes, which on a
shop's tills it does every hour.

**Look at the message itself.** Every Kafka record carries a timestamp, set by the producer when it
was created unless the topic says otherwise (lesson 9 takes the two kinds apart). The first message
the group has not handled is waiting at its committed offset; read it, subtract its timestamp from
the clock, and you have how long it has been waiting. **That is the lag in time, and it is what a
customer experiences**: the stock on the website is that many seconds old.

## Measuring it

Kafka's own tool does not print the second kind, so here is a small program that does. It asks the
cluster for the group's committed offsets, reads the one message waiting at each, and compares its
timestamp with the clock. Save it as `~/work/lag_seconds.py`:

```schooling-example
{
  "file": "lag_seconds.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"lag_seconds.py: how far behind a consumer group is, in messages and in seconds.\n\n    python lag_seconds.py GROUP\n\"\"\"\nimport sys\nimport time\n\nfrom confluent_kafka import Consumer, TopicPartition\n\ngroup = sys.argv[1]\nconf = {\"bootstrap.servers\": \"localhost:9092\", \"enable.auto.commit\": False}\n",
      "note": "The group to measure is the argument. Nothing here joins that group."
    },
    {
      "code": "asker = Consumer({**conf, \"group.id\": group})\nreader = Consumer({**conf, \"group.id\": \"lag-seconds\"})\n",
      "note": "Two consumers with two jobs. **`asker` carries the group's id only to ask for its offsets**: it never subscribes, so the group does not rebalance because somebody looked at it. `reader` fetches one message per partition under a group of its own."
    },
    {
      "code": "topic = asker.list_topics(\"sales\").topics[\"sales\"]\nparts = [TopicPartition(\"sales\", p) for p in sorted(topic.partitions)]\nnow = time.time()\nfor tp in asker.committed(parts, timeout=10):\n    low, high = asker.get_watermark_offsets(tp, timeout=10)\n    at = tp.offset if tp.offset >= 0 else low\n    if at >= high:\n        print(f\"partition {tp.partition}: 0 messages behind\")\n        continue\n",
      "note": "The partitions of `sales`, and for each one the group's committed offset and the partition's end, which is the same pair the group tool subtracts."
    },
    {
      "code": "    reader.assign([TopicPartition(\"sales\", tp.partition, at)])\n    msg = reader.poll(10)\n    written = msg.timestamp()[1] / 1000\n    print(f\"partition {tp.partition}: {high - at} messages behind,\",\n          f\"the oldest written {now - written:.0f} s ago\")\nasker.close()\nreader.close()",
      "note": "The message waiting at the committed offset. `timestamp()` gives its kind and its milliseconds since 1970; the difference from now is how long it has waited."
    }
  ]
}
```

Run it in the first shell while the tills from the last section are still selling:

```
ubuntu@stream:~/work$ python lag_seconds.py stock
```

Put it beside the group tool's output just before it and the two agree on the count, give or take
the sales that arrived in between. What the second number adds is that **the two partitions are
behind by very different counts and by the same time**. The consumer takes messages from both as
they come, so the oldest waiting message in each was written at about the same moment; partition 1
simply receives more shops. A dashboard that summed the counts would say partition 1 is the problem.
The time says the whole consumer is.

Once the consumer has caught up, the same program has nothing waiting to read:

```
ubuntu@stream:~/work$ python lag_seconds.py stock
```

## Which one to put on a screen

| number | answers | use it for |
|---|---|---|
| lag in messages | how much work is queued | sizing: how many consumers, how long to drain |
| lag in time | how stale the output is | promises: "stock is never more than a minute old" |
| how the lag changes | whether it is getting worse | alerts, in the last section of this lesson |

Lag in time has one trap of its own. **It trusts the timestamp in the record**, and a producer with
a wrong clock, or a till that sends a burst of sales it stored while it was offline, makes it lie in
either direction. Lesson 9 is about exactly that; for the lag of your own consumer, where the
producer is a program you run, the record timestamp is good enough.
