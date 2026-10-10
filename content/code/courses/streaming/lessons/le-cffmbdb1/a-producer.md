---
title: A producer, and hearing back from it
version: 1
---

DRAFT

Save this as `~/work/producer.py`:

```schooling-example
{
  "file": "producer.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"producer.py: send sales to Kafka, and hear back about every one of them.\n\n    python producer.py [--count N] [--linger-ms MS] [--rate R]\n                       [--topic T] [--timeout-ms MS]\n\"\"\"\nimport argparse\nimport json\nimport time\nfrom collections import Counter\n\nfrom confluent_kafka import Producer\n\nSHOPS = [\"recife\", \"olinda\", \"caruaru\", \"natal\", \"joao-pessoa\"]\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--count\", type=int, default=10)\nargs.add_argument(\"--linger-ms\", type=int, default=5)\nargs.add_argument(\"--rate\", type=float, default=0)\nargs.add_argument(\"--topic\", default=\"sales\")\nargs.add_argument(\"--timeout-ms\", type=int, default=300000)\nargs = args.parse_args()\n",
      "note": "What it does and how to call it."
    },
    {
      "code": "producer = Producer({\n    \"bootstrap.servers\": \"localhost:9092\",\n    \"partitioner\": \"murmur2_random\",\n    \"linger.ms\": args.linger_ms,\n    \"batch.size\": 16384,\n    \"message.timeout.ms\": args.timeout_ms,\n})\n",
      "note": "The configuration."
    },
    {
      "code": "delivered, failed = Counter(), Counter()\n\n\ndef report(err, msg):\n    if err is None:\n        delivered[msg.partition()] += 1\n    else:\n        failed[err.str()] += 1\n",
      "note": "The delivery report."
    },
    {
      "code": "\nfor n in range(1, args.count + 1):\n    shop = SHOPS[n % len(SHOPS)]\n    sale = {\"sale\": f\"{shop[:3]}-{n:06d}\", \"shop\": shop, \"book\": \"bk-01\", \"qty\": 1, \"cents\": 3990}\n    producer.produce(args.topic, key=shop, value=json.dumps(sale), on_delivery=report)\n    producer.poll(0)\n    if args.rate:\n        time.sleep(1 / args.rate)\n",
      "note": "The loop."
    },
    {
      "code": "left = producer.flush(30)\nprint(\"delivered per partition:\", dict(sorted(delivered.items())))\nfor reason, n in failed.items():\n    print(f\"failed: {n} x {reason}\")\nif left:\n    print(f\"still waiting after 30 s: {left}\")",
      "note": "Flush and the summary."
    }
  ]
}
```
