---
title: Producing and reading with a schema
version: 1
---

**With a registry, the producer does not send JSON and the consumer does not parse it: each side
hands its dictionaries to a serialiser, which turns them into the five-byte header and an Avro
body, and back.** The Kafka part of the program does not change at all. `produce` still takes
bytes; they just come from a different function.

## The till, in Avro

This is lesson 1's till with the JSON taken out. The shops, the books and the clock are the same,
and the same seed gives the same sales. Save it as `~/work/avro_tills.py`:

```schooling-example
{
  "file": "avro_tills.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"avro_tills.py: Ponto Final's sales into Kafka as Avro, under a registered schema.\n\n    python avro_tills.py [--count N] [--schema FILE] [--topic T] [--seed S]\n\"\"\"\nimport argparse\nimport random\nfrom datetime import datetime, timedelta, timezone\n\nfrom confluent_kafka import Producer\nfrom confluent_kafka.schema_registry import SchemaRegistryClient\nfrom confluent_kafka.schema_registry.avro import AvroSerializer\nfrom confluent_kafka.serialization import MessageField, SerializationContext\n",
      "note": "The serialiser lives in `confluent_kafka.schema_registry`, which the `[avro]` extra installed."
    },
    {
      "code": "SHOPS = [\"recife\", \"olinda\", \"caruaru\", \"natal\", \"joao-pessoa\"]\nBOOKS = {\"bk-01\": 3990, \"bk-02\": 5490, \"bk-03\": 2990, \"bk-04\": 7900,\n         \"bk-05\": 4490, \"bk-06\": 6200, \"bk-07\": 3500, \"bk-08\": 8990}\nOPEN = datetime(2026, 3, 2, 9, 0, tzinfo=timezone(timedelta(hours=-3)))\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--count\", type=int, default=10)\nargs.add_argument(\"--schema\", default=\"sale.avsc\")\nargs.add_argument(\"--topic\", default=\"sales-avro\")\nargs.add_argument(\"--seed\", type=int, default=1)\nargs = args.parse_args()\n",
      "note": "The same shops, books and opening time as `tills.py`."
    },
    {
      "code": "registry = SchemaRegistryClient({\"url\": \"http://localhost:8080/apis/ccompat/v7\"})\nto_avro = AvroSerializer(registry, open(args.schema).read(),\n                         conf={\"auto.register.schemas\": False})\nproducer = Producer({\"bootstrap.servers\": \"localhost:9092\"})\n",
      "note": "**`auto.register.schemas` is switched off.** By default the serialiser registers whatever schema it is given, which turns every producer into somebody who can change the topic's schema. Off, it only looks the schema up, and refuses to send if the registry does not have it."
    },
    {
      "code": "rng, clock = random.Random(args.seed), OPEN\nfor n in range(1, args.count + 1):\n    clock += timedelta(seconds=rng.randint(1, 20))\n    shop, book = rng.choice(SHOPS), rng.choice(list(BOOKS))\n    qty = rng.choice([1, 1, 1, 2, 3])\n    sale = {\"sale\": f\"{shop[:3]}-{n:06d}\", \"shop\": shop, \"book\": book, \"qty\": qty,\n            \"cents\": BOOKS[book] * qty, \"at\": clock.isoformat(), \"till\": f\"{shop}-1\"}",
      "note": "Each sale is a dictionary as before. It also carries `till`, which the schema in `sale.avsc` does not have: **the serialiser writes the fields its schema names and ignores the rest**, which is what lets the same program write a later version."
    },
    {
      "code": "    value = to_avro(sale, SerializationContext(args.topic, MessageField.VALUE))\n    producer.produce(args.topic, key=shop, value=value)\nproducer.flush()\nprint(f\"sent {args.count} sales to {args.topic} as Avro\")",
      "note": "The serialiser needs to know the topic and that this is a value, because together they name the subject: `sales-avro` and value make `sales-avro-value`."
    }
  ]
}
```

Make the topic and send ten sales:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales-avro --partitions 3
```

## What went over the wire

The console consumer prints a message's value as it is, and `od` shows the bytes. One message,
from the start of partition 0:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales-avro --partition 0 --offset 0 --max-messages 1 2>/dev/null | od -A d -t x1z
```

@@WIRE@@

## The reader

The consumer is the mirror image. It takes a schema of its own, the **reader's schema** from the
section on Avro, and the deserialiser fetches the writer's schema from the registry by the id in
each message. Save it as `~/work/avro_read.py`:

```schooling-example
{
  "file": "avro_read.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"avro_read.py: read every Avro sale as the schema in one file, whatever it was written with.\n\n    python avro_read.py [SCHEMA]      (sale.avsc if not given)\n\"\"\"\nimport sys\nimport uuid\nfrom collections import Counter\n\nfrom confluent_kafka import Consumer\nfrom confluent_kafka.schema_registry import SchemaRegistryClient\nfrom confluent_kafka.schema_registry.avro import AvroDeserializer\nfrom confluent_kafka.serialization import MessageField, SerializationContext\n",
      "note": "The schema the reader wants comes from a file, `sale.avsc` unless another is named."
    },
    {
      "code": "schema = sys.argv[1] if len(sys.argv) > 1 else \"sale.avsc\"\nregistry = SchemaRegistryClient({\"url\": \"http://localhost:8080/apis/ccompat/v7\"})\nfrom_avro = AvroDeserializer(registry, open(schema).read())\nconsumer = Consumer({\"bootstrap.servers\": \"localhost:9092\",\n                     \"group.id\": f\"avro-read-{uuid.uuid4()}\",\n                     \"auto.offset.reset\": \"earliest\"})\nconsumer.subscribe([\"sales-avro\"])\n",
      "note": "**The deserialiser is given the reader's schema**, and resolves each message from its writer's schema to this one."
    },
    {
      "code": "cents, written_with, fields = Counter(), Counter(), None\nwhile (msg := consumer.poll(10)) is not None:\n    written_with[int.from_bytes(msg.value()[1:5], \"big\")] += 1\n    sale = from_avro(msg.value(), SerializationContext(\"sales-avro\", MessageField.VALUE))\n    cents[sale[\"shop\"]] += sale[\"cents\"]\n    fields = fields or list(sale)\nconsumer.close()\n\nprint(\"schema ids:\", dict(written_with))\nprint(\"fields read:\", \", \".join(fields))\nfor shop, total in sorted(cents.items()):\n    print(f\"{shop:12} {total / 100:10.2f}\")",
      "note": "Bytes 1 to 4 of each value are the writer's schema id, counted here so you can see which versions are on the topic. The fields of the first sale read are kept to show what the reader's schema produced."
    }
  ]
}
```

```
ubuntu@stream:~/work$ python avro_read.py
```

@@READ@@
