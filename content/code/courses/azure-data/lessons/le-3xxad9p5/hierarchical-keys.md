---
title: Hierarchical partition keys, for the customer who outgrows one
version: 1
---

**A hierarchical partition key is a key of up to three levels**, such as `/customerId` and then
`/orderMonth`, and it exists for the case the previous section waved away: a single value that
outgrows 20 GB, or the load one physical partition can take. With a plain key, every order of the
busiest customer is one logical partition, which can never be split. With a hierarchical key, each
pair of customer and month is a logical partition of its own, so the busiest customer's history can
spread over many physical partitions. A query that names only the customer is still sent to the
partitions holding that customer and to no others.

Quitanda's business customers, the restaurants at the top of the previous table, are the reason it
would consider one. The emulator accepts the kind of key Azure calls `MultiHash`. Save this as
`~/azure/hier.py`:

`hier.py`:

```python
from azure.cosmos import CosmosClient, PartitionKey

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
db = CosmosClient("http://localhost:8081", KEY).get_database_client("quitanda")
by_month = db.create_container_if_not_exists(
    "orders_by_month", PartitionKey(path=["/customerId", "/orderMonth"], kind="MultiHash"))
print(by_month.read()["partitionKey"])

for n, month in enumerate(["2026-08", "2026-09", "2026-10", "2026-10"]):
    by_month.upsert_item({"id": f"o-{n}", "customerId": "c-0", "orderMonth": month,
                          "totalCents": 2000 + n})

item = by_month.read_item("o-3", partition_key=["c-0", "2026-10"])
print("point read needs both levels:", item["id"], item["orderMonth"])
october = list(by_month.query_items("SELECT VALUE c.id FROM c", partition_key=["c-0", "2026-10"]))
print("one customer, one month:", october)
everything = list(by_month.query_items("SELECT VALUE c.id FROM c", partition_key=["c-0"]))
print("one customer, by the first level only:", everything)
```

```
ana@laptop:~/azure$ python hier.py
{'kind': 'MultiHash', 'paths': ['/customerId', '/orderMonth'], 'version': 2}
point read needs both levels: o-3 2026-10
one customer, one month: ['o-2', 'o-3']
one customer, by the first level only: ['o-0', 'o-1', 'o-2', 'o-3']
```

**The key is a list of paths with `kind` set to `MultiHash`**, and it is fixed at creation like any
other. A point read needs every level, both values here. A query can name all of them, and reach one
logical partition, or only the first ones, a **prefix**, and reach every logical partition under that
customer: the four orders of `c-0` across three months.

**What this run shows is the shape, not the routing.** The emulator has one physical partition, so
every query here was answered by the same one. On Azure, the documented behaviour is that a query naming
the prefix goes only to the physical partitions that hold it, and a query naming no level at all goes
everywhere. That was not run.

## When it is worth it

**A hierarchical key costs a second thing to know at every point read**, the month as well as the
customer, and that is a price the application pays in every line that reads. It is worth paying when
one top-level value is going to outgrow a logical partition, as a tenant of a multi-tenant system or a
customer that is a chain of restaurants does. For Quitanda's ordinary customers, a few hundred orders
each, the plain `/customerId` of the previous section is simpler and enough. The documentation's own advice is to reach for the hierarchy when a single value's data or load is the problem, and not
before.
