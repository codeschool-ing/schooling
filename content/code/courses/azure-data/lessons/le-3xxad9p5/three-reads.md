---
title: Three reads, and the one number the emulator gets wrong
version: 1
---

**A point read, a query in one partition and a query across partitions are three different
operations**, and on Azure they have three different prices. This section runs all three against the
emulator, counts what each one sends and reads the charge Cosmos DB attaches to every answer. Save this
as `~/azure/reads.py`:

```schooling-example
{"language": "python", "file": "reads.py", "parts": [{"code": "\"\"\"Three ways to read Quitanda's orders, and what each one sends.\"\"\"\nimport collections\nfrom azure.cosmos import CosmosClient, PartitionKey\n\nKEY = \"C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==\"\nsent = collections.Counter()\n\n\ndef count(request):\n    sent[\"requests\"] += 1\n\n\nclient = CosmosClient(\"http://localhost:8081\", KEY, raw_request_hook=count)\ndb = client.create_database_if_not_exists(\"quitanda\")\norders = db.create_container_if_not_exists(\"orders\", PartitionKey(\"/customerId\"))\n", "note": "**The same hook as lesson 7's `count.py`**, because the Cosmos DB library is built on the same core as Blob Storage's: every HTTP request it sends passes through `count` first. The container is the previous section's, partitioned by customer."}, {"code": "\nfor n in range(1000):\n    orders.upsert_item({\"id\": f\"o-{n}\", \"customerId\": f\"c-{n % 100}\",\n                        \"totalCents\": 1500 + n * 37 % 30000})\n", "note": "A thousand orders of a hundred customers, ten each, written one request at a time."}, {"code": "\n\ndef measure(name, read):\n    sent.clear()\n    items = read()\n    charge = orders.client_connection.last_response_headers[\"x-ms-request-charge\"]\n    print(f\"{name:<26}{sent['requests']:>2} request(s){charge:>6} RU{len(items):>5} item(s)\")\n", "note": "**Every answer from Cosmos DB carries its price in a header**, `x-ms-request-charge`, in request units. `measure` runs one read and prints the requests it took, the charge of the last answer and the items it returned."}, {"code": "\n\nmeasure(\"point read\", lambda: [orders.read_item(\"o-17\", partition_key=\"c-17\")])\nmeasure(\"query in one partition\", lambda: list(orders.query_items(\n    \"SELECT * FROM c WHERE c.customerId = 'c-17'\", partition_key=\"c-17\")))\nmeasure(\"query across partitions\", lambda: list(orders.query_items(\n    \"SELECT * FROM c WHERE c.totalCents > 30000\", enable_cross_partition_query=True)))\nprint(\"feed ranges in the container:\", len(list(orders.read_feed_ranges())))\n", "note": "**Three reads, from the cheapest kind to the dearest.** A point read names the `id` and the partition key. A query that names the key's value is answered inside one logical partition. A query on any other field has to ask every physical partition, and the library refuses to send one unless `enable_cross_partition_query` says you meant it. The last line asks how many ranges of the hash, physical partitions, the container has."}]}
```

```
ana@laptop:~/azure$ python reads.py
point read                 1 request(s)     1 RU    1 item(s)
query in one partition     1 request(s)     1 RU   11 item(s)
query across partitions    1 request(s)     1 RU   40 item(s)
feed ranges in the container: 1
```

**One request each, one request unit each, and one feed range.** The items are right: one order, then
customer `c-17`'s eleven, the ten written here and the `o-1001` of the previous section, then the 40
orders above 30,000 cents. Everything else on those lines is the
emulator's simplification, and the section is about reading past it.

## What Azure charges instead

**This part is taught from Microsoft's documentation, and was not run.** On Azure:

- **a point read of a 1 KB item costs 1 request unit**, the documented baseline the whole unit is
  defined by, and it grows with the item's size. It is the cheapest read Cosmos DB has, and it needs
  the `id` and the partition key value;
- **a query in one partition costs more than a point read of the same item**, because the query engine
  has to parse it, plan it and use the index, and its charge grows with the items it reads and returns;
- **a query across partitions is sent to every physical partition**, each answer carries its own
  charge, and the library adds them up. A container with four physical partitions answers it four
  times. As the container grows and Azure splits it, the same query, returning the same items, costs
  more every year.

**The emulator has one physical partition**, which is what `feed ranges in the container: 1` says,
and it charges 1 for everything, as lesson 1 found. So it cannot show the fan-out and it cannot show the
price. It does show what the code has to say to get each kind of read: the point read needed both
halves of the identity, the query in one partition named the value, and the third query had to be
allowed explicitly. **`enable_cross_partition_query=True` in a program is the line to look for in a
review**: it marks a read that will cost more as the data grows, and on the hot path of an application
it is usually a key chosen for the wrong question.

Lesson 13 measures request units properly, from the documentation, with the throttling that follows
when a container runs out of them.
