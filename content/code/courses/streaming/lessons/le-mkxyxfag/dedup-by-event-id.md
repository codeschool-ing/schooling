---
title: Remembering which events were applied
version: 1
---

**A consumer can turn duplicates into nothing by recording the id of each event it applies, in
the same database transaction as the effect, and skipping an event whose id is already
recorded.** The two writes have to share the transaction. With the id written first and the effect
second, a crash in between marks a sale as applied that never was; the other way round, a crash
leaves a sale applied and not marked, and the next delivery applies it again.

The id has to come from the event, which is what lesson 2 meant by giving every event an id of
its own: here it is the `sale` field, `nat-000002` and so on, given by the till. An id made up by
the consumer, or the offset in Kafka, would not do, because the same sale written twice by a
producer that retried sits at two offsets.

## A sink for the stock

This consumer keeps the stock of each book in `stock.db`, starting from a hundred copies of each,
and subtracts every sale. With `--dedup` it also keeps the sale ids in a table `processed`. It
commits the Kafka offset of each sale after the database has committed, so it delivers at least
once, and `--crash-after` stops it dead between the two commits. Save it as
`~/work/stock_sink.py`:

```schooling-example
{
  "file": "stock_sink.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"stock_sink.py: the stock of each book in SQLite, kept from the sales in Kafka.\n\n    python stock_sink.py [--dedup] [--replay] [--crash-after N]\n\n--dedup        remember each sale's id, in the same transaction as the stock\n--replay       read the topic from the beginning again, as a reprocessing would\n--crash-after  stop dead after N sales, between the database's commit and Kafka's\n\"\"\"\nimport argparse\nimport json\nimport os\nimport sqlite3\n\nfrom confluent_kafka import OFFSET_BEGINNING, Consumer\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--dedup\", action=\"store_true\")\nargs.add_argument(\"--replay\", action=\"store_true\")\nargs.add_argument(\"--crash-after\", type=int, default=0)\nargs = args.parse_args()\n",
      "note": "Three options, each used by a section of this lesson."
    },
    {
      "code": "db = sqlite3.connect(\"stock.db\")\ndb.executescript(\"\"\"\n    CREATE TABLE IF NOT EXISTS stock (book TEXT PRIMARY KEY, qty INTEGER NOT NULL);\n    CREATE TABLE IF NOT EXISTS processed (sale TEXT PRIMARY KEY);\n    INSERT OR IGNORE INTO stock VALUES ('bk-01', 100), ('bk-02', 100), ('bk-03', 100),\n        ('bk-04', 100), ('bk-05', 100), ('bk-06', 100), ('bk-07', 100), ('bk-08', 100);\n\"\"\")\n\n",
      "note": "Two tables: the stock, and **the ids already applied, as a primary key**, so the database itself refuses a second copy. A new file starts every book at 100."
    },
    {
      "code": "def from_the_start(consumer, partitions):\n    if args.replay:\n        for p in partitions:\n            p.offset = OFFSET_BEGINNING\n    consumer.assign(partitions)\n\n\nconsumer = Consumer({\"bootstrap.servers\": \"localhost:9092\", \"group.id\": \"stock-sink\",\n                     \"auto.offset.reset\": \"earliest\", \"enable.auto.commit\": False})\nconsumer.subscribe([\"sales\"], on_assign=from_the_start)\n",
      "note": "`--replay` moves every partition back to its first offset when the group is given them, which is what reprocessing a topic looks like to a consumer."
    },
    {
      "code": "applied = skipped = 0\nwhile (msg := consumer.poll(10)) is not None:\n    sale = json.loads(msg.value())\n    with db:\n        first_time = not args.dedup or db.execute(\n            \"INSERT OR IGNORE INTO processed VALUES (?)\", (sale[\"sale\"],)).rowcount == 1\n        if first_time:\n            db.execute(\"UPDATE stock SET qty = qty - ? WHERE book = ?\", (sale[\"qty\"], sale[\"book\"]))\n    applied, skipped = applied + first_time, skipped + (not first_time)",
      "note": "**`with db:` is one transaction**: it commits when the block ends and rolls back if anything in it raises. `INSERT OR IGNORE` changes one row for a new id and none for a known one, and `rowcount` says which."
    },
    {
      "code": "    if applied + skipped == args.crash_after:\n        print(f\"crashed after {args.crash_after} sales, before committing the offset\", flush=True)\n        os._exit(1)\n    consumer.commit(msg, asynchronous=False)\nconsumer.close()\nprint(f\"applied {applied} sales, skipped {skipped} already seen\")",
      "note": "The crash falls **after the database commit and before Kafka's**, the gap from lesson 7 in which at least once repeats a message."
    }
  ]
}
```

The stock of the eight books starts at 800 copies in all, so the sum of `stock` after the
consumer has run is 800 minus the copies sold. Make a fresh topic with forty sales:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3
```

As in lesson 7, a `sales` topic left from an earlier lesson means starting from a fresh cluster.

## Without the ids

Run it once, then replay the topic, the way a team does after fixing a bug in some other consumer
of the same topic, or after restoring this database from last night's backup:

```
ubuntu@stream:~/work$ python stock_sink.py
```

@@NAIVE@@

## With them

Start the database again and do the same with `--dedup`:

```
ubuntu@stream:~/work$ rm stock.db
```

@@DEDUP@@

## And the crash it was built for

The replay was a deliberate duplicate. The ordinary one comes from a crash between the two
commits. Delete the database and the group's offsets, crash the sink after fifteen sales, and
start it again:

```
ubuntu@stream:~/work$ rm stock.db
```

@@CRASH@@
