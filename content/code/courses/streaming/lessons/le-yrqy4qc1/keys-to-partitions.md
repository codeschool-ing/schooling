---
title: Which partition a key lands in
version: 1
---

DRAFT

Save this as `~/work/keys.py`:

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
