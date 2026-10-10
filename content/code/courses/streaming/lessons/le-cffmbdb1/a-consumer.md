---
title: A consumer
version: 1
---

DRAFT

Save this as `~/work/consumer.py`:

```schooling-example
{
  "file": "consumer.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"consumer.py: read sales as one member of a consumer group.\n\n    python consumer.py NAME [--group G] [--topic T] [--protocol classic|consumer]\n                            [--strategy S] [--manual]\n\"\"\"\nimport argparse\nimport json\n\nfrom confluent_kafka import Consumer\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"name\")\nargs.add_argument(\"--group\", default=\"stock\")\nargs.add_argument(\"--topic\", default=\"sales\")\nargs.add_argument(\"--protocol\", default=\"classic\")\nargs.add_argument(\"--strategy\", default=\"range\")\nargs.add_argument(\"--manual\", action=\"store_true\")\nargs = args.parse_args()\n",
      "note": "What it does."
    },
    {
      "code": "config = {\n    \"bootstrap.servers\": \"localhost:9092\",\n    \"group.id\": args.group,\n    \"auto.offset.reset\": \"earliest\",\n    \"group.protocol\": args.protocol,\n    \"enable.auto.commit\": not args.manual,\n}\nif args.protocol == \"classic\":\n    config[\"partition.assignment.strategy\"] = args.strategy\nconsumer = Consumer(config)\n",
      "note": "The configuration."
    },
    {
      "code": "\n\ndef show(event):\n    def callback(consumer, partitions):\n        print(f\"{args.name}: {event} {[p.partition for p in partitions]}\", flush=True)\n    return callback\n\n\nconsumer.subscribe([args.topic], on_assign=show(\"assigned\"), on_revoke=show(\"revoked\"))",
      "note": "The callbacks."
    },
    {
      "code": "try:\n    while True:\n        msg = consumer.poll(1.0)\n        if msg is None:\n            continue\n        if msg.error():\n            print(f\"{args.name}: {msg.error()}\", flush=True)\n            continue\n        sale = json.loads(msg.value())\n        print(f\"{args.name}: partition {msg.partition()} offset {msg.offset()} {sale['sale']}\",\n              flush=True)\n        if args.manual:\n            consumer.commit(message=msg, asynchronous=False)",
      "note": "The loop."
    },
    {
      "code": "except KeyboardInterrupt:\n    pass\nfinally:\n    consumer.close()",
      "note": "Leaving."
    }
  ]
}
```
