---
title: What the emulators are, and where they stop
version: 1
---

**Every emulator in this course is Microsoft's own, or the open-source engine Azure runs as a
managed service**. That is the good news: a blob Azurite stores, a document the Cosmos DB
emulator returns and an event the Event Hubs emulator delivers come back through the same
protocol, the same libraries and the same command line as on Azure. Code that works against them
needs a different connection string and nothing else to run against a real account.

The bad news is in what they leave out, and it is the same thing every time: **an emulator answers
the data plane of one service, and nothing above it.** There is no subscription, no resource group,
no storage account to create, no role to assign, no network rule, no metric and no bill. Those are
the control plane, Azure Resource Manager, and no emulator anywhere answers it.

## What answers, and what does not

| service | in this course | what it answers | what it does not |
|---|---|---|---|
| Blob Storage, Queue, Table | Azurite 3.37.0 | containers, blobs, tiers, SAS | life-cycle rules, soft delete, versioning, the Data Lake endpoint |
| Cosmos DB | the vNext emulator | databases, containers, items, queries, change feed | consistency levels, real request units, throttling, regions |
| Event Hubs | the emulator 2.2.1 | partitions, consumer groups, sending, reading | capture into storage, throughput units, the Kafka-compatible scaling |
| Azure SQL, Managed Instance | SQL Server 2025 | the engine, T-SQL, the query plans | purchasing models, serverless pause, elastic pools, failover |
| PostgreSQL flexible server | PostgreSQL 17.6 | the engine | high availability, the server parameters Azure locks |
| Azure Cache for Redis | Redis 8.2.2 | the engine | tiers, clustering across shards, patching |
| Synapse, Fabric, Databricks, Data Factory, Stream Analytics, Purview | nothing | | everything |

**The last row is seven of the course's twenty-six lessons, and they are taught from Microsoft's
documentation, marked as not run.** Where one of them works on a file format or an idea that runs on
a laptop, such as Parquet, Delta Lake or a window over a stream, the lesson runs that part with an
open tool and says plainly which tool did it. No section in this course shows an answer that looks
like Azure's and was produced by something else.

## Answering is not checking

The more dangerous gap is quieter. **An emulator can accept a request and not do what it promised**,
and the only symptom is that nothing goes wrong. Two examples, one from each end of the course.

The Cosmos DB emulator reports a request charge on every answer, which is how Azure bills a
database, in request units. This program writes one small document and then runs a query that has
to read across every partition, which on Azure is billed by the work it does, partition by partition:

`ru.py`:

```python
from azure.cosmos import CosmosClient, PartitionKey

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
client = CosmosClient("http://localhost:8081", KEY)
db = client.create_database_if_not_exists("quitanda")
orders = db.create_container_if_not_exists("orders", PartitionKey("/customerId"))

orders.upsert_item({"id": "o-1", "customerId": "c-7", "totalCents": 4890})
print("write:", orders.client_connection.last_response_headers["x-ms-request-charge"])

found = list(orders.query_items("SELECT * FROM c WHERE c.totalCents > 100",
                                enable_cross_partition_query=True))
print("query across partitions:", orders.client_connection.last_response_headers["x-ms-request-charge"])
```

The key is the emulator's own, published by Microsoft and the same on every computer. Start the
emulator, which takes about ten seconds to answer, and run it:

```
ana@laptop:~/azure$ docker compose --profile cosmos up -d 2>&1 | tail -1
 Container azure-cosmos-1 Started 
ana@laptop:~/azure$ python ru.py
write: 1
query across partitions: 1
```

**One request unit for both, and for everything else you will ask it.** The number is a placeholder
and not a measurement. Lesson 13 is about request units and teaches them from Microsoft's
documentation for exactly this reason: the emulator would teach that every operation costs the same,
which is the one belief that makes a Cosmos DB bill a surprise.

Azurite does the same with time. A blob moved to the archive tier on Azure takes up to fifteen hours
to come back; on Azurite it is back the moment you ask, as lesson 4 shows. Neither emulator is wrong
to do this. They are built for testing a program's logic, quickly, and they leave cost and time out
on purpose. **This course points at every such place where it meets one**, under a heading that says
so. And the rule for reading any transcript in it is always the same: **a success here proves your command
or your program is well formed, never that Azure would charge, wait or allow what the emulator
did.**
