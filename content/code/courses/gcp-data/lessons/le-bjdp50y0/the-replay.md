---
title: A consumer that crashes, counted twice and then once
version: 1
---

**This section makes duplicates happen and then makes them harmless, in programs you can run.** The
setting is Quitanda's payments: a topic with one message per paid order, and a consumer that keeps
each customer's running total in a database. The totals are the kind of number somebody reports to
finance, so counting an order twice is not a rounding error; it is a wrong invoice.

The emulator is the one of the last section, still running. A topic, its one subscription, and a
**snapshot** of the subscription taken before anything is published, which is what lets every run
below start again from the same messages:

```sh
gcloud pubsub topics create payments
gcloud pubsub subscriptions create totals --topic=payments
gcloud pubsub snapshots create totals-start --subscription=totals
```

## The publisher, with one retry in it

Save it as `~/gcp/pay.py`:

```schooling-example
{"language": "python", "file": "pay.py", "parts": [{"code": "import json\n\nfrom google.cloud import pubsub_v1\n\npublisher = pubsub_v1.PublisherClient()\ntopic = publisher.topic_path('planner-dev', 'payments')\n\n", "note": "The topic `payments` is created by the commands above this block, with its one subscription."}, {"code": "PAYMENTS = [\n    ('o-301', 'c-17', 4590), ('o-302', 'c-02', 12800), ('o-303', 'c-17', 990),\n    ('o-304', 'c-05', 2350), ('o-305', 'c-02', 1500), ('o-306', 'c-17', 7200),\n]\nRETRIED = {'o-303'}\n\n", "note": "Six payments for three customers. **The idempotency key is the order id**: an order is paid once, so a second message for the same order is a duplicate whatever caused it."}, {"code": "for order, customer, cents in PAYMENTS:\n    data = json.dumps({'order_id': order, 'customer_id': customer, 'cents': cents}).encode()\n    for _ in range(2 if order in RETRIED else 1):\n        message_id = publisher.publish(topic, data, order_id=order).result()\n        print(f'{order} {customer} {cents:>6}  id {message_id}')\n", "note": "**`o-303` is published twice**, as a publisher does when its first attempt timed out and it cannot tell whether the message was stored. Pub/Sub gives the second copy a message id of its own. The order id also travels as an attribute, where a consumer can read it without parsing the body."}]}
```

```
ana@laptop:~/gcp$ python3 pay.py
o-301 c-17   4590  id 3
o-302 c-02  12800  id 4
o-303 c-17    990  id 5
o-303 c-17    990  id 6
o-304 c-05   2350  id 7
o-305 c-02   1500  id 8
o-306 c-17   7200  id 9
```

**Seven messages for six payments.** Ids 5 and 6 hold the same payment, and the correct totals are the
sums of the six: 12,780 cents for `c-17`, 14,300 for `c-02` and 2,350 for `c-05`. Those are the numbers
to hold every run below against.

## The consumer

Save it as `~/gcp/totals.py`:

```schooling-example
{"language": "python", "file": "totals.py", "parts": [{"code": "import json\nimport os\nimport sqlite3\nimport sys\n\nfrom google.cloud import pubsub_v1\n\nsubscriber = pubsub_v1.SubscriberClient()\npath = subscriber.subscription_path('planner-dev', 'totals')\nmode = sys.argv[1]\ncrash_after = int(sys.argv[2]) if len(sys.argv) > 2 else None\n\n", "note": "**A consumer that adds each payment to its customer's total.** The mode chooses what it checks before adding: nothing, the message id, or the order id. A second argument makes it crash after that many messages, the way a process dies when its machine is taken away."}, {"code": "db = sqlite3.connect('totals.db')\ndb.execute('CREATE TABLE IF NOT EXISTS totals (customer_id TEXT PRIMARY KEY, cents INTEGER)')\ndb.execute('CREATE TABLE IF NOT EXISTS processed (key TEXT PRIMARY KEY)')\n\nADD = '''INSERT INTO totals VALUES (?, ?)\n         ON CONFLICT (customer_id) DO UPDATE SET cents = cents + excluded.cents'''\n\n\n", "note": "The sink is SQLite, the database in a file that comes with Python. `totals` holds the running sums and `processed` the keys already applied. `ADD` adds to a total, so it is **not idempotent**: run twice, it counts twice."}, {"code": "def apply(message, e):\n    with db:\n        if mode != 'plain':\n            key = message.message_id if mode == 'by-message-id' else e['order_id']\n            try:\n                db.execute('INSERT INTO processed VALUES (?)', (key,))\n            except sqlite3.IntegrityError:\n                return 'duplicate, skipped'\n        db.execute(ADD, (e['customer_id'], e['cents']))\n        return 'added'\n\n\n", "note": "**The dedupe and the effect are one transaction**: `with db` commits both writes together or neither. A key already in `processed` breaks its primary key, the insert fails, and nothing is added. Two separate commits would leave a gap, where a crash between them counts an order without recording it, or records it and never counts it."}, {"code": "done = 0\nwhile received := subscriber.pull(subscription=path, max_messages=10, timeout=5).received_messages:\n    for r in received:\n        if crash_after is not None and done == crash_after:\n            print(f'crash after {done} messages, before the ack')\n            os._exit(1)\n        e = json.loads(r.message.data)\n        print(f\"id {r.message.message_id:>2}  {e['order_id']} {e['customer_id']} {e['cents']:>6}  {apply(r.message, e)}\")\n        done += 1\n    subscriber.acknowledge(subscription=path, ack_ids=[r.ack_id for r in received])\nprint(f'{done} messages, acknowledged')\n", "note": "It pulls batches of up to ten until a pull comes back empty, and **acknowledges each batch after applying it**. That order, the work and then the ack, is what makes it at least once: everything pulled before a crash comes back."}]}
```

## Without a dedupe

`plain`, told to crash after four messages, then started again, as a supervisor restarts a process
that died. The first restart is immediate:

```
ana@laptop:~/gcp$ python3 totals.py plain 4
id  3  o-301 c-17   4590  added
id  4  o-302 c-02  12800  added
id  5  o-303 c-17    990  added
id  6  o-303 c-17    990  added
crash after 4 messages, before the ack
ana@laptop:~/gcp$ python3 totals.py plain
0 messages, acknowledged
ana@laptop:~/gcp$ sleep 10; python3 totals.py plain
id  3  o-301 c-17   4590  added
id  4  o-302 c-02  12800  added
id  5  o-303 c-17    990  added
id  6  o-303 c-17    990  added
id  7  o-304 c-05   2350  added
id  8  o-305 c-02   1500  added
id  9  o-306 c-17   7200  added
7 messages, acknowledged
ana@laptop:~/gcp$ python3 -c "import sqlite3; print(sqlite3.connect('totals.db').execute('SELECT * FROM totals ORDER BY 1').fetchall())"
[('c-02', 27100), ('c-05', 2350), ('c-17', 20340)]
```

**The restart that came at once found nothing, and the one ten seconds later found everything.** The
first run took all seven messages in one pull, added four of them and died before its ack, so the
seven were still lent to a process that no longer existed. The immediate restart asked, got an empty
pull and stopped; the deadline had not run out. Ten seconds on, all seven were delivered again.

**Every total is wrong, and nothing printed an error.** `c-17` came out at 20,340 instead of 12,780:
`o-301` counted twice by the redelivery, and `o-303` four times, twice for the publisher's retry and
twice again for the redelivery. `c-02` is 27,100 instead of 14,300. Only `c-05` is right, because its
payment was not among the four applied before the crash. This is at-least-once delivery working as
designed, into a sink that is not idempotent.

## The replay, and a dedupe by message id

**The snapshot gives the run a second chance with the same messages.** Seeking `totals` to
`totals-start` marks all seven messages unacknowledged again, as lesson 19's seek did for `analytics`,
and removing `totals.db` starts the sums from nothing. The obvious key to dedupe on is the one Pub/Sub
gives every message, its id:

```
ana@laptop:~/gcp$ rm totals.db && gcloud pubsub subscriptions seek totals --snapshot=totals-start
snapshotId: projects/planner-dev/snapshots/totals-start
subscriptionId: projects/planner-dev/subscriptions/totals
ana@laptop:~/gcp$ python3 totals.py by-message-id 4
id  3  o-301 c-17   4590  added
id  4  o-302 c-02  12800  added
id  5  o-303 c-17    990  added
id  6  o-303 c-17    990  added
crash after 4 messages, before the ack
ana@laptop:~/gcp$ sleep 10; python3 totals.py by-message-id
id  3  o-301 c-17   4590  duplicate, skipped
id  4  o-302 c-02  12800  duplicate, skipped
id  5  o-303 c-17    990  duplicate, skipped
id  6  o-303 c-17    990  duplicate, skipped
id  7  o-304 c-05   2350  added
id  8  o-305 c-02   1500  added
id  9  o-306 c-17   7200  added
7 messages, acknowledged
ana@laptop:~/gcp$ python3 -c "import sqlite3; print(sqlite3.connect('totals.db').execute('SELECT * FROM totals ORDER BY 1').fetchall())"
[('c-02', 14300), ('c-05', 2350), ('c-17', 13770)]
```

**The redelivery was caught and the publisher's retry was not.** On the second run, ids 3 to 6 were
refused one by one, because the first run had recorded them in `processed` in the same transaction as
their totals. But ids 5 and 6 are two messages for one payment, and both were added in the first run:
`c-17` is 13,770, which is 12,780 plus a second `o-303`. A message id identifies a delivery's message,
not the event it reports.

## A dedupe by order id

```
ana@laptop:~/gcp$ rm totals.db && gcloud pubsub subscriptions seek totals --snapshot=totals-start
snapshotId: projects/planner-dev/snapshots/totals-start
subscriptionId: projects/planner-dev/subscriptions/totals
ana@laptop:~/gcp$ python3 totals.py by-order-id 4
id  3  o-301 c-17   4590  added
id  4  o-302 c-02  12800  added
id  5  o-303 c-17    990  added
id  6  o-303 c-17    990  duplicate, skipped
crash after 4 messages, before the ack
ana@laptop:~/gcp$ sleep 10; python3 totals.py by-order-id
id  3  o-301 c-17   4590  duplicate, skipped
id  4  o-302 c-02  12800  duplicate, skipped
id  5  o-303 c-17    990  duplicate, skipped
id  6  o-303 c-17    990  duplicate, skipped
id  7  o-304 c-05   2350  added
id  8  o-305 c-02   1500  added
id  9  o-306 c-17   7200  added
7 messages, acknowledged
ana@laptop:~/gcp$ python3 -c "import sqlite3; print(sqlite3.connect('totals.db').execute('SELECT * FROM totals ORDER BY 1').fetchall())"
[('c-02', 14300), ('c-05', 2350), ('c-17', 12780)]
```

**The totals are the correct ones**, 12,780, 14,300 and 2,350, through the same retry and the same
crash. In the first run, message 6 failed the dedupe because its order id was already recorded by
message 5, and nothing was added for it. In the second run, the four redelivered messages failed the
same way, and only the three nobody had applied were added. The consumer is still at least once; the
effect is now exactly once.

**And it survives the worst case, a replay of the whole subscription:**

```
ana@laptop:~/gcp$ gcloud pubsub subscriptions seek totals --snapshot=totals-start && python3 totals.py by-order-id
snapshotId: projects/planner-dev/snapshots/totals-start
subscriptionId: projects/planner-dev/subscriptions/totals
id  3  o-301 c-17   4590  duplicate, skipped
id  4  o-302 c-02  12800  duplicate, skipped
id  5  o-303 c-17    990  duplicate, skipped
id  6  o-303 c-17    990  duplicate, skipped
id  7  o-304 c-05   2350  duplicate, skipped
id  8  o-305 c-02   1500  duplicate, skipped
id  9  o-306 c-17   7200  duplicate, skipped
7 messages, acknowledged
ana@laptop:~/gcp$ python3 -c "import sqlite3; db = sqlite3.connect('totals.db'); print(db.execute('SELECT * FROM totals ORDER BY 1').fetchall(), db.execute('SELECT count(*) FROM processed').fetchone())"
[('c-02', 14300), ('c-05', 2350), ('c-17', 12780)] (6,)
```

Seven messages read, seven skipped, the totals unchanged, and six order ids recorded, one per
payment. **That is what idempotent means: running it again changes nothing.** It is also what makes
lesson 19's seek safe to use. Keeping a week of retention to replay a bad deploy is only half of the
second chance; the other half is a consumer that can be pointed back a week without corrupting what it
already wrote.

## What the dedupe costs

**One more write per message, and a table that grows.** Every payment now costs an insert into
`processed` beside the update of its total, and the table gains a row per event for ever. The way out is
to delete old keys after a window a little longer than the longest replay anybody would run, such as
the topic's retention plus a margin. A duplicate older than that window is no longer caught, which is the
trade, and it is made by choosing the window. On a managed database the extra write is a line on the
bill: Firestore's price per document write, from lesson 10, or a row in Cloud SQL, from lesson 6.
