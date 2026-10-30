---
title: Sinks that do not care how often they are written
version: 1
---

**The dedupe table of the last section is one answer; a sink that is idempotent by its nature is the
cheaper one.** A dedupe table remembers every event so that a second write can be refused. An
idempotent sink needs no memory, because writing the same thing twice already lands in the same place
with the same result. The test of a sink is one question: if this write is repeated, is the result
different? Adding to a total answers yes. Two kinds of write answer no, and they are the two this
course uses most.

## An upsert, not an increment

Save it as `~/gcp/sink.py`:

```schooling-example
{"language": "python", "file": "sink.py", "parts": [{"code": "import sqlite3\nimport sys\n\ndb = sqlite3.connect('sink.db')\ndb.execute('CREATE TABLE IF NOT EXISTS balances (customer_id TEXT PRIMARY KEY, cents INTEGER)')\nhow, customer, cents = sys.argv[1], sys.argv[2], int(sys.argv[3])\n\n", "note": "One write, chosen on the command line, against a table of balances."}, {"code": "with db:\n    if how == 'add':\n        db.execute('INSERT INTO balances VALUES (?, ?) ON CONFLICT (customer_id) '\n                   'DO UPDATE SET cents = cents + excluded.cents', (customer, cents))\n", "note": "`add` changes the value by an amount, the write `totals.py` makes."}, {"code": "    else:\n        db.execute('INSERT INTO balances VALUES (?, ?) ON CONFLICT (customer_id) '\n                   'DO UPDATE SET cents = excluded.cents', (customer, cents))\n", "note": "**`put` sets the value**: an upsert. The two statements differ by one expression, `cents +`, and that expression is the whole difference between a sink that counts twice and one that does not."}, {"code": "print(customer, db.execute('SELECT cents FROM balances WHERE customer_id = ?', (customer,)).fetchone()[0])\n", "note": "And it prints what the row holds afterwards."}]}
```

```
ana@laptop:~/gcp$ python3 sink.py add c-08 500
c-08 500
ana@laptop:~/gcp$ python3 sink.py add c-08 500
c-08 1000
ana@laptop:~/gcp$ python3 sink.py put c-09 500
c-09 500
ana@laptop:~/gcp$ python3 sink.py put c-09 500
c-09 500
```

**`add` twice made 1,000 out of 500; `put` twice left 500.** An upsert replaces the value with the one
given, so repeating it is harmless, and the same is true of PostgreSQL's `INSERT ... ON CONFLICT DO
UPDATE`, of `MERGE`, which `sql-databases` covers, and of a Firestore `set()` on a document named by
its key. The catch is that an upsert has to carry the **whole state**, the balance itself rather than
the amount to add to it, and the publisher has to know that state. That suits a stream of snapshots,
such as "customer `c-09`'s balance is now 500", and does not suit a stream of changes, such as "add
500", which is what payments are. A stream of changes into a sink that adds is the case that needs
the dedupe of the last section.

**Design the events to make the sink easy.** If a publisher can send the new state rather than the
difference, every consumer downstream can upsert and stop worrying about duplicates. When the event
has to be a difference, it carries an id, and the sink either records the id with the effect, as
`totals.py` does, or is rebuilt later from the deduplicated history.

## An object named by its content, not by the moment

A consumer that gathers messages into files in Cloud Storage needs a name for each object. The
tempting name is the time of writing; the idempotent one is derived from what the file holds. This
needs fake-gcs-server from lesson 1 running in a terminal of its own, with the command of lesson 1's
"Two terminals". One small batch, written twice under each kind of name:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-raw-prod --location=southamerica-east1
Creating gs://quitanda-raw-prod/...
ana@laptop:~/gcp$ printf '%s\n' '{"order_id": "o-301", "cents": 4590}' '{"order_id": "o-302", "cents": 12800}' > batch.json
ana@laptop:~/gcp$ gcloud storage cp batch.json gs://quitanda-raw-prod/raw/payments-by-time/$(date +%s%N).json
Copying file://batch.json to gs://quitanda-raw-prod/raw/payments-by-time/1793386454387317596.json
  

ana@laptop:~/gcp$ gcloud storage cp batch.json gs://quitanda-raw-prod/raw/payments-by-time/$(date +%s%N).json
Copying file://batch.json to gs://quitanda-raw-prod/raw/payments-by-time/1793386455620381634.json
  

ana@laptop:~/gcp$ gcloud storage cp batch.json gs://quitanda-raw-prod/raw/payments-by-content/$(sha256sum batch.json | cut -c1-16).json
Copying file://batch.json to gs://quitanda-raw-prod/raw/payments-by-content/9a93139ad353bd4a.json
  

ana@laptop:~/gcp$ gcloud storage cp batch.json gs://quitanda-raw-prod/raw/payments-by-content/$(sha256sum batch.json | cut -c1-16).json
Copying file://batch.json to gs://quitanda-raw-prod/raw/payments-by-content/9a93139ad353bd4a.json
  

ana@laptop:~/gcp$ gcloud storage ls gs://quitanda-raw-prod/raw/**
gs://quitanda-raw-prod/raw/payments-by-content/9a93139ad353bd4a.json
gs://quitanda-raw-prod/raw/payments-by-time/1793386454387317596.json
gs://quitanda-raw-prod/raw/payments-by-time/1793386455620381634.json
```

**The time-named batch is now in the lake twice; the content-named one is there once.** The second
copy to `9a93139ad353bd4a.json` overwrote an identical object with identical bytes, which changes
nothing, so a consumer that crashed after writing the object and before its ack can write it again on
the redelivery with no harm. Under the time-named keys the same redelivery leaves two objects with the
same two payments, and every query of the lake counts both. Lesson 1's warning that an overwrite is
silent and final is, here, exactly the property wanted.

**This works only if a redelivery rebuilds the same batch**, and on Pub/Sub that is the hard part. A
subscription has no positions to batch by: a redelivery arrives in whatever groups the pulls return,
mixed with messages that came later, so the second attempt's file is a different set of messages from
the first. A consumer that wants content-named files names them by something stable, such as one file
per order, or the sorted ids of the events inside it, and accepts that the same event can then sit in
two different files. **A Cloud Storage subscription**, which lesson 19 named, writes files named by
time like the first kind, so a duplicate it writes stays in the lake until a later job removes it.
That is why lake tables fed from Pub/Sub are deduplicated by the idempotency key when they are
compacted into the curated layer, in a query that keeps one row per order id.
