---
title: Account, database, container, item
version: 1
---

**Cosmos DB stores JSON documents, which it calls items, in containers, and every container is
created with a partition key that it can never change.** The layers above are simple: an account is
the address and the bill, `quitanda-prd.documents.azure.com` on Azure, and holds databases; a
database is a namespace that groups containers. The container is where everything that matters is
decided, and the partition key, a path into each item such as `/customerId`, is the first of those
decisions. This lesson is about that one choice, because every later one, the cost of a read, the
limit of a write and the shape of the bill, follows from it.

The Cosmos DB emulator of lesson 1 answers all of it, apart from the account, which is one fixed
account the emulator always has, like Azurite's `devstoreaccount1`. Start it in `~/azure`; it takes
about ten seconds before it answers:

```sh
docker compose --profile cosmos up -d
```

Then a first container for Quitanda's orders, partitioned by customer, and two items. Save this as
`~/azure/model.py`:

`model.py`:

```python
from azure.cosmos import CosmosClient, PartitionKey, exceptions

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
client = CosmosClient("http://localhost:8081", KEY)
db = client.create_database_if_not_exists("quitanda")
orders = db.create_container_if_not_exists("orders", PartitionKey("/customerId"))

orders.upsert_item({"id": "o-1001", "customerId": "c-17", "totalCents": 4890})
orders.upsert_item({"id": "o-1001", "customerId": "c-18", "totalCents": 1250})
same = list(orders.query_items("SELECT c.customerId FROM c WHERE c.id = 'o-1001'",
                               enable_cross_partition_query=True))
print("items called o-1001:", same)

try:
    orders.create_item({"id": "o-1001", "customerId": "c-17", "totalCents": 999})
except exceptions.CosmosHttpResponseError as e:
    print("o-1001 again in c-17:", e.status_code, e.reason)

item = orders.read_item("o-1001", partition_key="c-17")
print("system properties:", sorted(k for k in item if k.startswith("_")))

try:
    orders.upsert_item({"id": "o-big", "customerId": "c-17", "note": "x" * 2_100_000})
except exceptions.CosmosHttpResponseError as e:
    print("an item of 2.1 MB:", e.status_code, e.reason)
```

<<CAP model>>

**Two items called `o-1001` live in one container**, because an `id` is unique only within a value of
the partition key: `o-1001` of customer `c-17` and `o-1001` of `c-18` are different items. Writing
the first one again with `create_item` is refused with `409 Conflict`, the answer `upsert_item` would
have avoided by replacing it. **So an item's identity is the pair, the partition key value and the
`id`**, and a point read, `read_item`, needs both.

The properties that begin with an underscore are the service's: `_rid` is its internal id, `_self`
its address, `_etag` changes on every write and makes conditional updates possible, and `_ts` is the
time of the last write, in seconds since 1970. **And an item has a ceiling of 2 MB**, which the
emulator enforces as Azure documents it: the 2.1 MB note was refused with `413`. A document that
might grow past that, an order with an unbounded list of events inside it, is a design that will one
day fail on a write.
