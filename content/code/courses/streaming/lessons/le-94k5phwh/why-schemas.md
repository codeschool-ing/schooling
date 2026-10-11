---
title: Why a stream needs a schema
version: 1
---

**A message in Kafka is a key and a value, and both are bytes.** The broker never looks inside
them: it stores what the producer sent and hands it to whoever asks. So the shape of a sale —
which fields it has, what they are called, what type each one is — is not written down anywhere
Kafka can see. It lives in two places at once: in the code that writes the sales and in the code
that reads them. As long as both were written on the same day by the same person, the two agree.

The wrong picture is that JSON solves this because it is self-describing. JSON carries the
**names** of the fields with every message, which is not the same as carrying an agreement about
them. A reader that finds a name it does not know ignores it, and a reader that misses a name it
expected gets nothing back and carries on. Nothing fails, and that is the trouble.

## A field renamed on a Monday

Here is a reader of the kind every team writes first. It adds up the money per shop from every
sale in a topic of JSON sales, and it uses `.get` with a default, because somebody once saw it
crash on a sale with a field missing. Save it as `~/work/totals.py`:

```python
"""totals.py: money per shop, from every JSON sale in a topic."""
import json
import sys
import uuid
from collections import Counter

from confluent_kafka import Consumer

topic = sys.argv[1] if len(sys.argv) > 1 else "sales-json"
consumer = Consumer({"bootstrap.servers": "localhost:9092",
                     "group.id": f"totals-{uuid.uuid4()}",
                     "auto.offset.reset": "earliest"})
consumer.subscribe([topic])

cents, count = Counter(), 0
while (msg := consumer.poll(10)) is not None:
    sale = json.loads(msg.value())
    cents[sale["shop"]] += sale.get("cents", 0)
    count += 1
consumer.close()

print(f"{count} sales")
for shop, total in sorted(cents.items()):
    print(f"{shop:12} {total / 100:10.2f}")
```

The `group.id` is new on every run, so each run reads the topic from its first message; `poll(10)`
returning nothing for ten seconds is taken as the end. Make a topic of JSON sales, put twenty
sales in it with the till from lesson 1, and add them up:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales-json --partitions 3
Created topic sales-json.
ubuntu@stream:~/work$ python tills.py --count 20 --rate 0 --topic sales-json
sent 20 sales to sales-json, the last one at 09:02:55
ubuntu@stream:~/work$ python totals.py
20 sales
caruaru          398.50
joao-pessoa      159.90
natal            877.10
olinda           330.80
recife           531.30
```

Now the tills are upgraded. The new software is right in every way but one: its programmer
thought `amount` was a clearer name than `cents`. Save it as `~/work/till_v2.py`:

```python
"""till_v2.py: five sales from the new till software, which calls the money `amount`."""
import json

from confluent_kafka import Producer

producer = Producer({"bootstrap.servers": "localhost:9092"})
for n in range(1, 6):
    sale = {"sale": f"rec-9{n:05d}", "shop": "recife", "book": "bk-04", "qty": 1,
            "amount": 7900, "at": f"2026-03-02T11:0{n}:00-03:00"}
    producer.produce("sales-json", key="recife", value=json.dumps(sale))
producer.flush()
print("sent 5 sales from the new till")
```

Five more sales from Recife, and the totals again:

```
ubuntu@stream:~/work$ python till_v2.py
sent 5 sales from the new till
ubuntu@stream:~/work$ python totals.py
25 sales
caruaru          398.50
joao-pessoa      159.90
natal            877.10
olinda           330.80
recife           531.30
```

**Twenty-five sales, and Recife's total has not moved**: 531.30 before the new till and 531.30
after it, although Recife has just sold five copies of `bk-04` at 79.00 each. The 395.00 is in
the topic, in a field called `amount`, and `sale.get("cents", 0)` returned the 0 it was told to
return five times. No error, no warning, no log line. The count of sales is right, which makes
the total look checked.

That is the shape of the failure a schema exists to prevent. The producer and the consumer never
met; they shared a **guess** about what a sale looks like, written in two programs, and one of
them changed its half. A crash would have been better: somebody would have looked. The report
that goes to the manager tomorrow is wrong, and nothing in the system knows.

## Where the agreement has to live

The repair is not a better `.get`. A reader that crashes on the first sale with no `cents` would
at least have said something, and a reader that tries `cents`, then `amount`, then `price` has
only moved the guess into more places. What was missing is a **written description of a sale**
that both sides use and that cannot change without somebody checking the change against the
readers. That description is a **schema**, and the rest of this lesson is the machinery around
one:

- a format that cannot be written without one, **Avro**, in the next section;
- a service that stores every version and gives each one a number, the **schema registry**;
- a rule the registry applies to each new version before accepting it, **compatibility**.

Lesson 2 said an event should carry a version of its own shape. A registry is where those
versions are kept, and the number the producer puts into each message is how a reader finds the
one a message was written with.
