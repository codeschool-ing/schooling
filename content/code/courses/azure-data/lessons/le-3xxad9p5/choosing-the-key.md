---
title: Choosing the key, by measuring it
version: 1
---

**The partition key is chosen from the questions the application asks and the way its writes arrive,
not from what looks like the item's natural identity.** Every candidate is a trade between the three
properties of the previous section, and the trade can be measured before a single container exists,
with the data you already have, or with data shaped like it.

Quitanda's app asks one question far more than any other: show this customer their orders. The
candidates are the order's own `id`, the customer, the day the order was placed, and its status. This
program measures all four over a year of orders shaped like Quitanda's. It needs no emulator. Save it
as `~/azure/spread.py`:

```schooling-example
{"language": "python", "file": "spread.py", "parts": [{"code": "\"\"\"How four candidate partition keys would spread a year of Quitanda's orders.\"\"\"\nimport collections, random\n\nrng = random.Random(7)\nHOURS = [1, 1, 1, 1, 1, 2, 4, 6, 8, 8, 9, 10, 12, 10, 8, 8, 9, 11, 12, 10, 7, 4, 2, 1]\norders = []\nfor n in range(100_000):\n    day = n * 365 // 100_000\n    orders.append({\n        \"id\": f\"o-{n}\",\n        \"customerId\": f\"c-{int(7000 * rng.random() ** 3)}\",\n        \"placedDate\": f\"2026-{day:03}\",\n        \"hour\": rng.choices(range(24), weights=HOURS)[0],\n        \"status\": \"delivered\" if day < 364 else rng.choice([\"placed\", \"paid\", \"delivered\"]),\n    })\n", "note": "**A year of orders made up by the program, the same every run** because the random generator is seeded. A hundred thousand orders, spread evenly over 365 days and unevenly over the hours, with the lunchtime and evening peaks. Customers are skewed on purpose: cubing a random number piles the draws towards the low ids, so a few customers, restaurants, order far more than the rest. Every order but the last day's is delivered."}, {"code": "\nevening = [o for o in orders if o[\"placedDate\"] == \"2026-200\" and o[\"hour\"] == 19]\n\n\ndef report(key):\n    sizes = collections.Counter(o[key] for o in orders)\n    largest = sizes.most_common(1)[0][1]\n    hot = collections.Counter(o[key] for o in evening).most_common(1)[0][1]\n    question = \"one\" if key == \"customerId\" else \"every\"\n    print(f\"/{key:<12}{len(sizes):>9,}{largest:>9,}{100 * largest / len(orders):>7.1f}%\"\n          f\"{100 * hot / len(evening):>9.0f}%{question:>8}\")\n", "note": "**Three measures for each key, one per property of a good key.** How many distinct values there are, and how large the largest logical partition is, in orders and as a share of all of them. What share of one busy evening hour's writes lands on a single value. And how many partitions the app's most common question, a customer's orders, has to visit."}, {"code": "\n\nprint(f\"{'key':<13}{'values':>9}{'largest':>9}{'share':>8}{'hot hour':>10}{'visits':>8}\")\nfor key in (\"id\", \"customerId\", \"placedDate\", \"status\"):\n    report(key)\n", "note": "The four candidates: the order's own `id`, the customer, the day it was placed, and its status."}]}
```

<<CAP spread>>

Each row is one decision, read across:

- **`/id` spreads perfectly and answers nothing.** A hundred thousand values, one order each, and no
  busy hour can heat one of them. But "a customer's orders" names no `id`, so it visits every
  partition, every time. A key on `id` suits a container read only by point reads, such as a cache of
  documents fetched by their name.
- **`/customerId` answers the question in one partition**, with nearly seven thousand values and the
  evening's writes spread thin. Its largest partition is the skew: the busiest customer holds 5.2% of
  all orders, which is a few MB this year and far from the 20 GB limit even at a thousand times the
  volume. It is the key Quitanda chooses.
- **`/placedDate` fails at the moment of writing.** 365 values, each a modest 274 orders, look
  harmless over the year. But every order written this evening carries this evening's date, so all of
  that hour's writes land on one value, 100%, which is one physical partition taking the whole load
  while the others idle. A key on the date is the classic hot partition.
- **`/status` fails everywhere.** Three values, one of them holding 99.8% of the orders, a hot hour of
  100%, and every customer's question visiting all three. Worse, a status changes: an order moves from
  `paid` to `delivered`, and an item cannot move between partition key values; it has to be deleted
  and written again under the new one.

**So the design starts from the question and checks the writes**: `/customerId` because the app asks
by customer, kept because the writes of any hour spread over thousands of customers and no customer
approaches the limit.

## And you cannot change your mind

**A container's partition key is fixed when the container is created**, and Microsoft's documentation
says it cannot be changed; choosing another means a new container and a copy of every item into it.
The emulator agrees, in its own way. Save this as `~/azure/rekey.py`:

`rekey.py`:

```python
from azure.cosmos import CosmosClient, PartitionKey

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
db = CosmosClient("http://localhost:8081", KEY).get_database_client("quitanda")
orders = db.get_container_client("orders")

print("before:", orders.read()["partitionKey"]["paths"])
db.replace_container(orders, PartitionKey("/placedDate"))
print("replace_container returned without an error")
print("after: ", orders.read()["partitionKey"]["paths"])
```

<<CAP rekey>>

**The emulator accepted a request to change the key and kept the old one**, without a word. That is
the failure lesson 1 warned about in its plainest form: a success that did nothing. What Azure answers
to the same request was not run here; the documentation's rule is that the key does not change, and a
program that believes the success above has a container still partitioned by customer while its author
thinks otherwise.
