---
title: Reading from a chosen point
version: 1
---

**A group's position is a value Kafka stores, so it can be set.** To read again from the beginning,
from an offset, or from a moment in time, you move the group's committed offsets, and the next
member to start reads from there. Lesson 2 called this **replay**; this section shows the two tools
for it, and lesson 16 uses them on a consumer that got something wrong.

## Moving a group with kafka-consumer-groups.sh

The group tool resets offsets, and it insists on two things: the group must have no running members,
and it changes nothing unless told to. `--dry-run` shows what would happen:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group stock --topic sales --reset-offsets --to-earliest --dry-run

GROUP           TOPIC           PARTITION  NEW-OFFSET
stock           sales           2          0
stock           sales           1          0
stock           sales           0          0
```

`--execute` does it. The target can be `--to-earliest`, `--to-latest`, `--to-offset`,
`--shift-by` a number, or `--to-datetime` a moment, and `--topic sales:1` limits it to one
partition. Move group `stock` back to offset 3 on partition 1 only:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group stock --topic sales:1 --reset-offsets --to-offset 3 --execute

GROUP           TOPIC           PARTITION  NEW-OFFSET
stock           sales           1          3
```

Then start `c1` again and stop it once it has read:

```
ubuntu@stream:~/work$ python consumer.py c1
c1: assigned [0, 1, 2]
c1: partition 2 offset 2 rec-000005
c1: partition 2 offset 3 rec-000010
c1: partition 1 offset 3 nat-000008
c1: partition 1 offset 4 car-000002
c1: partition 1 offset 5 nat-000003
c1: partition 1 offset 6 car-000007
c1: partition 1 offset 7 nat-000008
c1: partition 0 offset 4 oli-000001
c1: partition 0 offset 5 joa-000004
c1: partition 0 offset 6 oli-000006
c1: partition 0 offset 7 joa-000009
c1: revoked [0, 1, 2]
```

Partition 1 started at 3, so `nat-000008`, which `c1` read in the first section, came round again
before the new sales. Partitions 0 and 2 were not touched and resumed at 4 and 2, reading only the
ten sales sent while `c1` was away. **A reset moves the place, and the log supplies the messages**:
nothing was re-sent, and no other group noticed.

## Reading from a moment, without a group

A program can also choose its own starting point, with no group position involved. `offsets_for_times`
asks the broker, for each partition, for the first offset whose timestamp is at or after a given
moment, using the `.timeindex` from lesson 3. Save this as `~/work/rewind.py`:

```schooling-example
{
  "file": "rewind.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"rewind.py: read a topic from a moment in time, outside any consumer group.\n\n    python rewind.py TOPIC 'YYYY-MM-DD HH:MM:SS' [--max N]\n\"\"\"\nimport argparse\nimport json\nfrom datetime import datetime\n\nfrom confluent_kafka import Consumer, TopicPartition\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"topic\")\nargs.add_argument(\"since\")\nargs.add_argument(\"--max\", type=int, default=5)\nargs = args.parse_args()\n",
      "note": "What it does and how to call it: a topic, a local date and time, and how many messages to print."
    },
    {
      "code": "since = int(datetime.strptime(args.since, \"%Y-%m-%d %H:%M:%S\").timestamp() * 1000)\nconsumer = Consumer({\"bootstrap.servers\": \"localhost:9092\", \"group.id\": \"rewind\",\n                     \"enable.auto.commit\": False})\n",
      "note": "The moment becomes milliseconds since 1970, the unit of a record's timestamp. The group id is required by the client and is never joined, since this consumer does not subscribe."
    },
    {
      "code": "partitions = consumer.list_topics(args.topic, timeout=10).topics[args.topic].partitions\nasked = [TopicPartition(args.topic, p, since) for p in sorted(partitions)]\nfound = consumer.offsets_for_times(asked, timeout=10)\nfor tp in found:\n    print(f\"partition {tp.partition}: offset {tp.offset}\")\n",
      "note": "**One question per partition**: a `TopicPartition` whose offset field holds the timestamp goes in, and the same partition with the first offset at or after that moment comes out."
    },
    {
      "code": "consumer.assign(found)\nfor _ in range(args.max):\n    msg = consumer.poll(5)\n    if msg is None:\n        break\n    sale = json.loads(msg.value())\n    print(f\"partition {msg.partition()} offset {msg.offset()} {sale['sale']}\")\nconsumer.close()",
      "note": "`assign` takes those partitions at those offsets, and the loop reads from there."
    }
  ]
}
```

Note the time, send five more sales, and rewind to that time:

```
ubuntu@stream:~/work$ date "+%F %T"
2026-10-10 22:45:14
ubuntu@stream:~/work$ python producer.py --count 5
delivered per partition: {0: 2, 1: 2, 2: 1}
ubuntu@stream:~/work$ python rewind.py sales '2026-10-10 22:45:14'
partition 0: offset 8
partition 1: offset 8
partition 2: offset 4
partition 2 offset 4 rec-000005
partition 1 offset 8 car-000002
partition 1 offset 9 nat-000003
partition 0 offset 8 oli-000001
partition 0 offset 9 joa-000004
```

The broker answered offsets 8, 8 and 4: exactly the log-end offsets before the five new sales, so
the program read those five and nothing older. Your time will be different; use the one your
`date` printed. The timestamp the broker looks up is the record's, set by the producer when it
sent the message, and not the sale's own `at`; lesson 9 is about the difference, and about
producers that set it to something else.

`rewind.py` uses `assign` instead of `subscribe`. **An assigned consumer is not a member of any
group**: it reads the partitions it names, no rebalance gives them to anyone else, and it commits
nothing, because `enable.auto.commit` is off. It is the tool for looking, while a reset group is the
tool for reprocessing.
