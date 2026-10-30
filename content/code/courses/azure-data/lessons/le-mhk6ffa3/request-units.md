---
title: The request unit, and what moves it
version: 1
---

**Cosmos DB does not bill requests, time or bytes read; it bills request units**, one number per
operation that stands for the processor, memory and input and output the operation took. Microsoft
fixes one point on the scale and leaves the rest to measurement: **reading one item of 1 KB by its
id and its partition key costs one request unit.** That is a point read, the cheapest thing Cosmos
DB does, and everything else is priced against it.

This section is taught from Microsoft's documentation, with one program run on the emulator to show
why the emulator cannot teach it.

## What makes an operation cost more

There is no published formula, only the factors, and they compound:

| factor | why it costs |
|---|---|
| the item's size | a 9 KB item is more bytes to read, write and index than a 1 KB one |
| indexing | every property is indexed by default, and each indexed property is work on every write |
| the kind of operation | a write costs more than a read of the same item, and an update is a write |
| consistency | reads at strong and bounded staleness cost about twice, as lesson 12 showed |
| the query | its filters and functions, how many items it reads and returns, and how many partitions it visits |

**A query that names its partition key goes to one physical partition; one that does not is sent to
all of them**, and each answers with its own charge. The fan-out is lesson 11's argument for the
partition key, seen from the bill. And the charge is deterministic: the same operation on the same
data costs the same every time, which is what makes it worth measuring once and multiplying.

## Where the number is

**Every answer carries its charge in the header `x-ms-request-charge`.** The Python library keeps the
last answer's headers on the container's client connection, as lesson 1's `ru.py` read them. On a
real account that header is the measurement every estimate in this lesson should start from: write
one realistic item, read it, run each query the application runs, and write the numbers down.

On the emulator it is not a measurement. This program writes a product of about 1 KB and one of about
9 KB, reads both, and runs a query inside one partition and another across all of them. Save it as
`charges.py` in `~/azure`, with the emulator started as in lesson 12:

`charges.py`:

```python
from azure.cosmos import CosmosClient, PartitionKey

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
client = CosmosClient("http://localhost:8081", KEY)
db = client.create_database_if_not_exists("quitanda")
products = db.create_container_if_not_exists("products", PartitionKey("/category"))


def charge(what):
    print(f"{what:34}", products.client_connection.last_response_headers["x-ms-request-charge"])


small = {"id": "cafe-500g", "category": "mercearia", "description": "x" * 900}
large = {"id": "cafe-1kg", "category": "mercearia", "description": "x" * 9000}
products.upsert_item(small); charge("write, about 1 KB")
products.upsert_item(large); charge("write, about 9 KB")
products.read_item("cafe-500g", "mercearia"); charge("point read, about 1 KB")
products.read_item("cafe-1kg", "mercearia"); charge("point read, about 9 KB")
list(products.query_items("SELECT * FROM p WHERE p.category = 'mercearia'",
                          partition_key="mercearia")); charge("query inside one partition")
list(products.query_items("SELECT * FROM p WHERE CONTAINS(p.description, 'y')",
                          enable_cross_partition_query=True)); charge("query across partitions")
```

```
ana@laptop:~/azure$ python charges.py
write, about 1 KB                  1
write, about 9 KB                  1
point read, about 1 KB             1
point read, about 9 KB             1
query inside one partition         1
query across partitions            1
```

**Six operations, six ones.** On Azure the first point read would be the one unit Microsoft fixes,
the 9 KB read would cost more, both writes would cost more than either read, and the query across
partitions would add a charge for every partition it visited. The emulator reports the header with
the right name, in the right place, holding a placeholder, which is the most convincing wrong number
a laptop can produce. **In this course request units are counted on paper, from Microsoft's anchor and
from charges you measure on an account, and never read off the emulator.**

Microsoft also publishes a capacity planner, a web form that estimates request units from item sizes
and operation counts. It was not used here, and its answer is an estimate too: the header on a real
account is the only number that is not.
