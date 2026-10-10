---
title: At most once: commit first, and lose what the crash interrupted
version: 1
---

**At most once means a message is processed once or not at all, and never twice.** The consumer
commits the offsets of what it has read before it processes it, so a crash leaves Kafka believing
the interrupted messages were handled. On the restart they are skipped. Nothing is ever done
twice, and the price is that something may never be done.

It is the right choice more often than its name suggests: a dashboard of sales per minute that
misses five sales in a crash is wrong by five sales for one minute, and a dashboard that counts
them twice is wrong in the same way. Where a duplicate costs more than a gap, such as a metric
that alerts somebody, a sample, or a log of clicks, at most once is cheaper and good enough.

## A consumer that can be crashed

This consumer does the simplest processing there is: it appends each sale's id to a file, one per
line, so that afterwards you can count what was processed. It reads in batches of ten and commits
by hand, before or after the batch depending on the mode, and `--crash-after N` makes it end
abruptly in the middle of a batch. Save it as `~/work/crash_consumer.py`:

```schooling-example
{
  "file": "crash_consumer.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"crash_consumer.py: write each sale's id to a file, commit offsets, and maybe crash.\n\n    python crash_consumer.py most|least [--crash-after N]\n\nmost   commit a batch's offsets, then process it   (at most once)\nleast  process a batch, then commit its offsets    (at least once)\n\"\"\"\nimport argparse\nimport json\nimport os\n\nfrom confluent_kafka import Consumer\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"mode\", choices=[\"most\", \"least\"])\nargs.add_argument(\"--crash-after\", type=int, default=0)\nargs = args.parse_args()\n",
      "note": "Two modes, one for each order of the two steps."
    },
    {
      "code": "consumer = Consumer({\"bootstrap.servers\": \"localhost:9092\",\n                     \"group.id\": f\"crash-{args.mode}\",\n                     \"auto.offset.reset\": \"earliest\",\n                     \"enable.auto.commit\": False})\nconsumer.subscribe([\"sales\"])\n",
      "note": "**`enable.auto.commit` is off**, so nothing is committed unless the program says so. Each mode has its own group, and so its own committed offsets."
    },
    {
      "code": "done = 0\nwith open(f\"processed-{args.mode}.txt\", \"a\") as out:\n    while batch := consumer.consume(num_messages=10, timeout=10):\n        if args.mode == \"most\":\n            consumer.commit(asynchronous=False)",
      "note": "`consume` returns up to ten messages, or an empty list after ten seconds with nothing new, which ends the loop. **In `most` mode the commit comes first**: `commit()` with no arguments commits the position after the batch just read."
    },
    {
      "code": "        for msg in batch:\n            out.write(json.loads(msg.value())[\"sale\"] + \"\\n\")\n            out.flush()\n            done += 1\n            if done == args.crash_after:\n                print(f\"crashed after {done} sales\", flush=True)\n                os._exit(1)",
      "note": "Processing is one line in a file, flushed at once so a crash cannot leave it in a buffer. **`os._exit` ends the process on the spot**: no `finally`, no closing of the consumer, no last commit, the way a power cut or `kill -9` ends it."
    },
    {
      "code": "        if args.mode == \"least\":\n            consumer.commit(asynchronous=False)\nconsumer.close()\nprint(f\"processed {done} sales; nothing more to read\")",
      "note": "In `least` mode the commit comes after the whole batch is processed."
    }
  ]
}
```

The topic for this lesson has **one partition**, so the batches and the offsets are easy to
follow. Make it and put fifty sales in it:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 1
```

If `sales` still exists from an earlier lesson, start from a fresh cluster first with
`./cluster.sh stop`, `./cluster.sh new 1` and `./cluster.sh start`.

## Crashing it

Run it in `most` mode with a crash after 25 sales, then again without one, and count:

```
ubuntu@stream:~/work$ python crash_consumer.py most --crash-after 25
```

@@MOST@@
