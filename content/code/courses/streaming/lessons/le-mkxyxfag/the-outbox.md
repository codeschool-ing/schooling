---
title: The outbox: changing a database and announcing it, in one transaction
version: 1
---

**The outbox pattern writes the event a change should announce into a table of the same
database, in the same transaction as the change, and a separate relay copies that table to
Kafka.** It solves the problem on the other side of the stream: not a consumer applying events,
but a program that changes its own data and has to tell everybody else.

The wrong way is the one that looks obvious, and lesson 14 opens with it: update the database,
then produce to Kafka. A crash between the two leaves a change nobody hears about; produce first
and a crash leaves an announcement of a change that never happened. It is lesson 7's gap again,
between two systems that cannot share a transaction. The outbox removes one of the two systems
from the moment that matters: **the change and the event are rows in the same database**, so they
commit together or not at all.

## A restock, and its event

When a delivery of books arrives at a shop, the stock goes up and an event `restocked` has to
reach Kafka. This program does both halves, as two commands. Save it as `~/work/outbox.py`:

```schooling-example
{
  "file": "outbox.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"outbox.py: a restock and the event announcing it, written in one transaction.\n\n    python outbox.py restock BOOK QTY    change the stock and queue the event\n    python outbox.py relay               send what is queued to Kafka, then mark it sent\n\"\"\"\nimport json\nimport sqlite3\nimport sys\nimport uuid\n\nfrom confluent_kafka import Producer\n",
      "note": "Two commands: one changes the stock, one relays."
    },
    {
      "code": "db = sqlite3.connect(\"shop.db\")\ndb.executescript(\"\"\"\n    CREATE TABLE IF NOT EXISTS stock (book TEXT PRIMARY KEY, qty INTEGER NOT NULL);\n    CREATE TABLE IF NOT EXISTS outbox (id TEXT PRIMARY KEY, topic TEXT, key TEXT,\n                                       payload TEXT, sent INTEGER NOT NULL DEFAULT 0);\n\"\"\")\n",
      "note": "**The outbox is an ordinary table**: the event's id, where it goes, and whether it has been sent."
    },
    {
      "code": "if sys.argv[1] == \"restock\":\n    book, qty = sys.argv[2], int(sys.argv[3])\n    event = {\"event\": str(uuid.uuid4()), \"type\": \"restocked\", \"book\": book, \"qty\": qty}\n    with db:\n        db.execute(\"INSERT INTO stock VALUES (?, ?) ON CONFLICT(book) DO UPDATE SET qty = qty + ?\",\n                   (book, qty, qty))\n        db.execute(\"INSERT INTO outbox (id, topic, key, payload) VALUES (?, 'stock-events', ?, ?)\",\n                   (event[\"event\"], book, json.dumps(event)))\n    print(f\"{book}: +{qty}, event queued\")\n",
      "note": "**The stock and the event are written in one transaction.** The event gets its id here, once, so every copy the relay may send carries the same id."
    },
    {
      "code": "elif sys.argv[1] == \"relay\":\n    producer = Producer({\"bootstrap.servers\": \"localhost:9092\", \"enable.idempotence\": True})\n    rows = db.execute(\"SELECT id, topic, key, payload FROM outbox WHERE sent = 0 ORDER BY rowid\")\n    sent = []\n    for id_, topic, key, payload in rows.fetchall():\n        producer.produce(topic, key=key, value=payload,\n                         on_delivery=lambda err, msg, id_=id_: err or sent.append(id_))\n    producer.flush()\n    with db:\n        db.executemany(\"UPDATE outbox SET sent = 1 WHERE id = ?\", [(i,) for i in sent])\n    print(f\"relayed {len(sent)} events\")",
      "note": "The relay sends every unsent row in the order it was written, waits for Kafka's acknowledgements, and **only then marks the acknowledged rows as sent**."
    }
  ]
}
```

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic stock-events --partitions 1
```

@@OUTBOX@@

## What the relay still owes

The relay itself has lesson 7's gap: a crash after Kafka acknowledged and before the rows were
marked sends those events again on the next run. **An outbox delivers at least once**, and that
is why each event carries an id made when the change was made. A consumer of `stock-events`
deduplicates by it, as this lesson's second section did with sale ids.

Two practical points. The outbox grows, so sent rows are deleted after a while, the same question
as the next section's. And a relay that polls a table is the simple version; the version used at
scale reads the database's own change log instead of querying the table, so nothing polls and no
event is missed between two queries. That is change data capture, and lesson 14 does it with
Debezium.
