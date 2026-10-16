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
      "code": "def resume(consumer, partitions):\n    for p in partitions:\n        row = db.execute(\"SELECT next FROM offsets WHERE part = ?\", (p.partition,)).fetchone()\n        p.offset = row[0] if row else OFFSET_BEGINNING\n        print(f\"partition {p.partition}: starting at {'the beginning' if row is None else row[0]}\")\n    consumer.assign(partitions)\n\n\nconsumer = Consumer({\"bootstrap.servers\": \"localhost:9092\", \"group.id\": \"offset-sink\",\n                     \"enable.auto.commit\": False, \"session.timeout.ms\": 6000})\nconsumer.subscribe([\"sales\"], on_assign=resume)\n",
      "note": "**When the group gives this consumer its partitions, it sets each one's starting offset from the database**, and from the beginning for a partition it has never seen."
    },
    {
      "code": "applied = 0\nwhile (msg := consumer.poll(15)) is not None:\n    sale = json.loads(msg.value())\n    with db:\n        db.execute(\"UPDATE stock SET qty = qty - ? WHERE book = ?\", (sale[\"qty\"], sale[\"book\"]))\n        db.execute(\"INSERT OR REPLACE INTO offsets VALUES (?, ?)\", (msg.partition(), msg.offset() + 1))\n    applied += 1\n    if applied == args.crash_after:\n        print(f\"crashed after {applied} sales\", flush=True)\n        os._exit(1)\nconsumer.close()\nprint(f\"applied {applied} sales\")",
      "note": "The stock and the offset change in **one transaction**. There is no Kafka commit to crash before, so the crash can fall anywhere."
    }
  ]
}
```

Crash it after fifteen sales and start it again:

```
ubuntu@stream:~/work$ python offset_sink.py --crash-after 15
partition 0: starting at the beginning
partition 1: starting at the beginning
partition 2: starting at the beginning
crashed after 15 sales
ubuntu@stream:~/work$ python offset_sink.py
partition 0: starting at the beginning
partition 1: starting at 15
partition 2: starting at the beginning
applied 25 sales
ubuntu@stream:~/work$ python -m sqlite3 stock2.db "SELECT sum(qty) FROM stock"
(729,)
ubuntu@stream:~/work$ python -m sqlite3 stock2.db "SELECT * FROM offsets"
(0, 7)
(1, 33)
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group offset-sink

Consumer group 'offset-sink' has no active members.
```

The fifteen sales of the first run all came from partition 1, so after the crash the database
held one row of `offsets`, saying partition 1 should resume at 15. **The restart read that and
started partition 1 at 15**, and the other two from the beginning. It applied the remaining 25,
and the stock is 729, as with the deduplicating sink, with no table of ids.

`offsets` now says where to resume in each partition that had sales: 7 for partition 0 and 33 for
partition 1; partition 2 received none of the forty. And the consumer group has **no committed
offsets at all**: `kafka-consumer-groups.sh` has nothing to show beyond the fact that nobody is
connected. Every tool that reads lag from the group sees nothing, which is the price of this
design, and the reason some teams commit to the group as well, after the database, purely as a
hint for monitoring. A hint that is wrong after a crash is harmless, because nothing reads it on
start.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Three designs side by side. First, at least once: the database commits the effect, then Kafka is told the offset; a crash between the two repeats the sale. Second, deduplication: the effect and the sale's id commit together in the database, and a repeated sale is skipped because its id is there. Third, offsets in the sink: the effect and the next offset commit together in the database, the consumer starts from that offset, and Kafka's group offset is not used.\" data-fig=\"l8-offsets\"><defs><marker id=\"l8-offsets-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">at least once</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">dedup by id</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">offset in the sink</text><rect x=\"20\" y=\"40\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">database: stock - 2</text><rect x=\"20\" y=\"120\" width=\"200\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Kafka: commit offset</text><line x1=\"120\" y1=\"76\" x2=\"120\" y2=\"118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l8-offsets-ah-8343)\"></line><text x=\"128\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">crash here repeats the sale</text><text x=\"120\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">two commits</text><rect x=\"260\" y=\"40\" width=\"200\" height=\"70\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">one transaction</text><rect x=\"270\" y=\"64\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">database: stock - 2, id</text><text x=\"360\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">repeat: id found, skipped</text><rect x=\"500\" y=\"40\" width=\"200\" height=\"70\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">one transaction</text><rect x=\"510\" y=\"64\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">database: stock - 2, next offset</text><text x=\"600\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">start: seek to stored offset</text></svg>", "caption": "Two commits leave a gap; putting the record of progress in the same transaction as the effect closes it, either as the event's id or as the offset."}
```
