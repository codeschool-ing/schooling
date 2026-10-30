---
title: The feed, read from the beginning and from a token
version: 1
---

**Every Cosmos DB container keeps a change feed, and nothing has to be switched on for it.** The feed
is the container's items listed in the order they were last written, and a program reads it the way
it reads a query: in pages, paying request units for them. It is how something outside the container
learns that an order was paid without asking every few seconds whether anything is new. Quitanda uses
it to keep a second view of its orders, what each customer has spent, which this lesson builds.

**The order is guaranteed inside one partition key and nowhere else.** Two changes to customer
`c-7`'s orders come out in the order they were made; a change for `c-7` and one for `c-8` come out in
whatever order their partitions are read. That is lesson 11's partition key deciding something again,
and it is the reason a consumer of the feed should never depend on two keys arriving in a particular
order.

This section is practised. With the Cosmos DB emulator started as in lesson 12, save this as `feed.py`
in `~/azure`. It writes six times, then reads the feed three times:

`feed.py`:

```python
import base64
import json

from azure.cosmos import CosmosClient, PartitionKey

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
db = CosmosClient("http://localhost:8081", KEY).create_database_if_not_exists("quitanda")
orders = db.create_container_if_not_exists("orders", PartitionKey("/customerId"), default_ttl=-1)

orders.upsert_item({"id": "o-1", "customerId": "c-7", "status": "paid", "totalCents": 4890})
orders.upsert_item({"id": "o-2", "customerId": "c-8", "status": "paid", "totalCents": 1250})
orders.upsert_item({"id": "o-3", "customerId": "c-7", "status": "paid", "totalCents": 7300})
orders.upsert_item({"id": "o-1", "customerId": "c-7", "status": "packed", "totalCents": 4890})
orders.upsert_item({"id": "o-1", "customerId": "c-7", "status": "delivered", "totalCents": 4890})
orders.delete_item("o-2", partition_key="c-8")
print("six writes: three creates, two updates of o-1, one delete of o-2")

for change in orders.query_items_change_feed(start_time="Beginning"):
    print("  from the beginning:", change["id"], change["status"], "lsn", change["_lsn"])
token = orders.client_connection.last_response_headers["etag"]
print("continuation:", json.loads(base64.b64decode(token))["continuation"]["continuation"])

print("again from the token:", list(orders.query_items_change_feed(continuation=token)))
orders.upsert_item({"id": "o-4", "customerId": "c-9", "status": "paid", "totalCents": 2100})
print("after one more write:", [c["id"] for c in orders.query_items_change_feed(continuation=token)])
```

```
ana@laptop:~/azure$ python feed.py
six writes: three creates, two updates of o-1, one delete of o-2
  from the beginning: o-3 paid lsn 3
  from the beginning: o-1 delivered lsn 5
continuation: [{'token': '"5"', 'range': {'min': '', 'max': 'FF', 'isMinInclusive': True, 'isMaxInclusive': False}}]
again from the token: []
after one more write: ['o-4']
```

**Six writes went in and two entries came out.** That is the subject of the next section, and the
short version is that the feed lists each item once, as it is now: `o-1` as `delivered`, never as
`paid` or `packed`, and `o-2` not at all, because it no longer exists. **Each entry carries `_lsn`, its
position in the partition's log**, 3 for `o-3` and 5 for `o-1`, the same counter lesson 12's session
token named.

**The continuation token is where the reader stopped, and it is just data.** The library hands it over
in the `etag` header of the last page, base64-encoded JSON, and the line that decodes it shows what is
inside: for each feed range, the range of partition key hashes it covers and the position reached in it,
`"5"`. The emulator has one feed range covering every key, from `''` to `FF`. A container on Azure with
several physical partitions has one entry per range, which is how a token can say where the reader is in
each of them at once.

**Read again from the token, and nothing comes back**; write one more order, and only that one does.
That is the contract the rest of this lesson is built on. A reader that saves its token after each batch
and passes it next time sees every change once in the normal case, and never has to ask the container
what is new.

## Where a reader may start

| `start_time` or `continuation` | starts at |
|---|---|
| `"Beginning"` | the oldest entry the feed still has |
| `"Now"` | the next change written after the request |
| a `datetime` | the first change written at or after that time |
| a saved token | just after the position the token records |

A new consumer of an existing container chooses between the first two: from the beginning, it builds its
view from every item there is; from now, it only cares about what happens next.
