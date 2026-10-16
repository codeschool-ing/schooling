---
title: The outbox: changing a database and announcing it, in one transaction
version: 1
---

**The outbox pattern writes the event a change should announce into a table of the same database,
in the same transaction as the change, and a separate relay copies that table to Kafka.** It solves
the problem on the other side of the stream: not a consumer applying events, but a program that
changes its own data and has to tell everybody else.

The wrong way is the one that looks obvious, and lesson 14 opens with it: update the database, then
produce to Kafka. A crash between the two leaves a change nobody hears about; produce first and a
crash leaves an announcement of a change that never happened. It is lesson 7's gap again, between
two systems that cannot share a transaction. The outbox removes one of the two systems from the
moment that matters: **the change and the event are rows in the same database**, so they commit
together or not at all.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Left, the program that restocks writes one database transaction containing two rows: the stock change and the event in the outbox table. Right, a separate relay reads unsent rows from the outbox, sends them to Kafka, waits for the acknowledgement, and only then marks them sent. A crash before the commit loses both rows together; a crash in the relay after Kafka's acknowledgement sends the event again, with the same id.\" data-fig=\"l8-outbox\"><defs><marker id=\"l8-outbox-ah-726\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l8-outbox-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l8-outbox-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"240\" height=\"130\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"140\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">one database transaction</text><rect x=\"40\" y=\"62\" width=\"200\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">stock: bk-04 +10</text><rect x=\"40\" y=\"108\" width=\"200\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">outbox: restocked, id, sent = 0</text><rect x=\"330\" y=\"92\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"385\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">relay</text><line x1=\"240\" y1=\"125\" x2=\"328\" y2=\"117\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l8-outbox-ah-8343)\"></line><text x=\"294\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">1  read unsent rows</text><rect x=\"560\" y=\"92\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Kafka: stock-events</text><line x1=\"440\" y1=\"110\" x2=\"558\" y2=\"110\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l8-outbox-ah-726)\"></line><text x=\"500\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2  produce, wait for the ack</text><path d=\"M 385 142 Q 300 190 240 140\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l8-outbox-ah-0)\"></path><text x=\"320\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3  mark them sent</text><text x=\"560\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a crash here repeats step 2</text><line x1=\"470\" y1=\"125\" x2=\"470\" y2=\"160\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></line></svg>", "caption": "The change and its event commit together. The relay delivers at least once, so the event carries an id for its readers to deduplicate."}
```

## A restock, and its event

When a delivery of books arrives at a shop, the stock goes up and an event `restocked` has to reach
Kafka. This program does both halves, as two commands. Save it as `~/work/outbox.py`:

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
Created topic stock-events.
ubuntu@stream:~/work$ python outbox.py restock bk-04 10
bk-04: +10, event queued
ubuntu@stream:~/work$ python outbox.py restock bk-07 5
bk-07: +5, event queued
ubuntu@stream:~/work$ python -m sqlite3 shop.db "SELECT id, sent FROM outbox"
('12098da2-b441-40bd-a0d4-ea83a638a598', 0)
('0e605ed6-41ea-49b0-8d81-b5d62bface21', 0)
ubuntu@stream:~/work$ python outbox.py relay
%4|1792112069.651|GETPID|rdkafka#producer-1| [thrd:main]: Failed to acquire idempotence PID from broker localhost:9092/1: Broker: Coordinator load in progress: retrying
relayed 2 events
ubuntu@stream:~/work$ python outbox.py relay
relayed 0 events
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic stock-events --from-beginning --timeout-ms 5000 2>/dev/null
{"event": "12098da2-b441-40bd-a0d4-ea83a638a598", "type": "restocked", "book": "bk-04", "qty": 10}
{"event": "0e605ed6-41ea-49b0-8d81-b5d62bface21", "type": "restocked", "book": "bk-07", "qty": 5}
```

Each restock queued its event in the same transaction, and both rows of `outbox` say `sent` is 0;
the ids are random, so yours differ. The first relay sent both, after the same first-time line from
the client that lesson 7 showed, and marked them; **the second relay found nothing to send**. The
topic holds the two events, each with the id it was given when the stock changed.

## What the relay still owes

The relay itself has lesson 7's gap: a crash after Kafka acknowledged and before the rows were
marked sends those events again on the next run. **An outbox delivers at least once**, and that is
why each event carries an id made when the change was made. A consumer of `stock-events`
deduplicates by it, as the section on remembering applied events did with sale ids.

Two practical points. The outbox grows, so sent rows are deleted after a while, the same question
as the section on how long to remember an id. And a relay that polls a table is the simple version;
the version used at scale reads the database's own change log instead of querying the table, so
nothing polls and no event is missed between two queries. That is change data capture, and lesson
14 does it with Debezium.
