---
title: Transactions, and readers that only see what was committed
version: 1
---

**A Kafka transaction makes several writes, to any number of partitions and topics, become
visible together or not at all.** The producer opens a transaction, writes, and then commits or
aborts it. The writes reach the logs straight away either way; what the commit adds is a
**marker** in each partition saying the transaction ended, and how. A consumer that asks to read
only committed data holds back until it has seen the marker, and drops what an abort marked.

That last sentence corrects the usual picture, in which an aborted write is never written. It is
written, takes up its offsets and stays in the log until retention removes it. Whether anybody
sees it is a property of the **reader**, chosen with `isolation.level`:

| `isolation.level` | what the consumer is given |
|---|---|
| `read_uncommitted` | everything in the log, committed, aborted or still open |
| `read_committed` | committed transactions, and messages written outside any transaction |

The Java and Python consumers default to opposite values: the Python client, through librdkafka,
defaults to `read_committed`, while the Java client and the console consumer built on it default
to `read_uncommitted`. The run below uses the console consumer, so the default you see there is
Java's.

## A producer with a transactional id

A transactional producer needs a **`transactional.id`**, a name that stays the same across
restarts. It is how the cluster recognises the same producer coming back: on `init_transactions`
the new instance is given the old one's producer id with a higher epoch, any transaction the old
one left open is aborted, and the old one, if it is somehow still alive, is **fenced**, refused on
its next write. This program writes two transactions of five sales; the first is committed and the
second aborted. Save it as `~/work/txn.py`:

```python
"""txn.py: two transactions of five sales each; the first is committed, the second aborted."""
import json

from confluent_kafka import Producer

producer = Producer({"bootstrap.servers": "localhost:9092", "transactional.id": "txn-demo"})
producer.init_transactions()

for t, outcome in ((1, "committed"), (2, "aborted")):
    producer.begin_transaction()
    for n in range(1, 6):
        sale = {"sale": f"txn-{t}-{n}", "shop": "olinda", "book": "bk-03", "qty": 1, "cents": 2990}
        producer.produce("ledger", key="olinda", value=json.dumps(sale))
    producer.flush()
    if outcome == "committed":
        producer.commit_transaction()
    else:
        producer.abort_transaction()
    print(f"transaction {t}: 5 sales written, {outcome}")
```

The `flush` before the abort is there for the demonstration: it makes sure the five aborted sales
really reached the log, so that you can see them. A real program aborts because something failed,
and whatever had been sent by then is in the log in the same way.

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic ledger --partitions 1
```

## Two readers of the same log

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic ledger --from-beginning --timeout-ms 5000 2>/dev/null
```

@@ISOLATION@@
