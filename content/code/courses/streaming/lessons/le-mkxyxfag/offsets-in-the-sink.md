---
title: Keeping the offset in the database
version: 1
---

**If the database stores, in the same transaction as each effect, the offset of the next message
to read, then the database and the stream cannot disagree about how far the consumer has got.** On
start, the consumer reads that offset and seeks to it. A crash anywhere leaves either the effect
and its offset, or neither, and the restart resumes exactly after the last effect. No sale is
applied twice, and no table of ids is needed.

This changes what the consumer group's commit means. It used to be the record of progress; now it
is not used at all, or is used only as a **hint** for tools such as `kafka-consumer-groups.sh` to
show lag. The database is the record, because it is the only place that knows what was actually
applied.

## The same sink, keeping its own place

This variant keeps the stock in `stock2.db` and adds a table `offsets` with one row per partition.
It never calls `commit`. Save it as `~/work/offset_sink.py`:

```schooling-example
{
  "file": "offset_sink.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"offset_sink.py: the stock in SQLite, with Kafka's offsets kept in the same database.\n\n    python offset_sink.py [--crash-after N]\n\nThe offset of the next sale to read is written in the transaction that applies\na sale, and read back when partitions are assigned. Kafka's group commit is\nnever used, so the database is the only record of how far this sink has got.\n\"\"\"\nimport argparse\nimport json\nimport os\nimport sqlite3\n\nfrom confluent_kafka import OFFSET_BEGINNING, Consumer\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--crash-after\", type=int, default=0)\nargs = args.parse_args()\n",
      "note": "The docstring says the design in three sentences."
    },
    {
      "code": "db = sqlite3.connect(\"stock2.db\")\ndb.executescript(\"\"\"\n    CREATE TABLE IF NOT EXISTS stock (book TEXT PRIMARY KEY, qty INTEGER NOT NULL);\n    CREATE TABLE IF NOT EXISTS offsets (part INTEGER PRIMARY KEY, next INTEGER NOT NULL);\n    INSERT OR IGNORE INTO stock VALUES ('bk-01', 100), ('bk-02', 100), ('bk-03', 100),\n        ('bk-04', 100), ('bk-05', 100), ('bk-06', 100), ('bk-07', 100), ('bk-08', 100);\n\"\"\")\n\n",
      "note": "`offsets` holds, per partition, **the offset of the next sale to read**: the last one applied plus one."
    },
    {
      "code": "def resume(consumer, partitions):\n    for p in partitions:\n        row = db.execute(\"SELECT next FROM offsets WHERE part = ?\", (p.partition,)).fetchone()\n        p.offset = row[0] if row else OFFSET_BEGINNING\n        print(f\"partition {p.partition}: starting at {'the beginning' if row is None else row[0]}\")\n    consumer.assign(partitions)\n\n\nconsumer = Consumer({\"bootstrap.servers\": \"localhost:9092\", \"group.id\": \"offset-sink\",\n                     \"enable.auto.commit\": False})\nconsumer.subscribe([\"sales\"], on_assign=resume)\n",
      "note": "**When the group gives this consumer its partitions, it sets each one's starting offset from the database**, and from the beginning for a partition it has never seen."
    },
    {
      "code": "applied = 0\nwhile (msg := consumer.poll(10)) is not None:\n    sale = json.loads(msg.value())\n    with db:\n        db.execute(\"UPDATE stock SET qty = qty - ? WHERE book = ?\", (sale[\"qty\"], sale[\"book\"]))\n        db.execute(\"INSERT OR REPLACE INTO offsets VALUES (?, ?)\", (msg.partition(), msg.offset() + 1))\n    applied += 1\n    if applied == args.crash_after:\n        print(f\"crashed after {applied} sales\", flush=True)\n        os._exit(1)\nconsumer.close()\nprint(f\"applied {applied} sales\")",
      "note": "The stock and the offset change in **one transaction**. There is no Kafka commit to crash before, so the crash can fall anywhere."
    }
  ]
}
```

Crash it after fifteen sales and start it again:

```
ubuntu@stream:~/work$ python offset_sink.py --crash-after 15
```

@@OFFSETS@@
