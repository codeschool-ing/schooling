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
```

@@NUMBERS@@

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
