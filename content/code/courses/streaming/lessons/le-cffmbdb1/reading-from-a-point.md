---
title: Reading from a point
version: 1
---

DRAFT

Save this as `~/work/rewind.py`:

```schooling-example
{
  "file": "rewind.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"rewind.py: read a topic from a moment in time, outside any consumer group.\n\n    python rewind.py TOPIC 'YYYY-MM-DD HH:MM:SS' [--max N]\n\"\"\"\nimport argparse\nimport json\nfrom datetime import datetime\n\nfrom confluent_kafka import Consumer, TopicPartition\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"topic\")\nargs.add_argument(\"since\")\nargs.add_argument(\"--max\", type=int, default=5)\nargs = args.parse_args()\n",
      "note": "What it does."
    },
    {
      "code": "since = int(datetime.strptime(args.since, \"%Y-%m-%d %H:%M:%S\").timestamp() * 1000)\nconsumer = Consumer({\"bootstrap.servers\": \"localhost:9092\", \"group.id\": \"rewind\",\n                     \"enable.auto.commit\": False})\n",
      "note": "The moment, in milliseconds."
    },
    {
      "code": "partitions = consumer.list_topics(args.topic, timeout=10).topics[args.topic].partitions\nasked = [TopicPartition(args.topic, p, since) for p in sorted(partitions)]\nfound = consumer.offsets_for_times(asked, timeout=10)\nfor tp in found:\n    print(f\"partition {tp.partition}: offset {tp.offset}\")\n",
      "note": "Asking for offsets."
    },
    {
      "code": "consumer.assign(found)\nfor _ in range(args.max):\n    msg = consumer.poll(5)\n    if msg is None:\n        break\n    sale = json.loads(msg.value())\n    print(f\"partition {msg.partition()} offset {msg.offset()} {sale['sale']}\")\nconsumer.close()",
      "note": "Reading."
    }
  ]
}
```
