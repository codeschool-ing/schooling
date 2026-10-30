---
title: Documents, collections and subcollections
version: 1
---

**Firestore stores documents, and a document is a small map of fields with a name.** Documents live
in collections, a collection is nothing but the documents in it, and a document can hold
collections of its own, called subcollections. So every document has a path that alternates the
two, `customers/c-17/orders/o-10001`: the collection `customers`, the document `c-17`, its
subcollection `orders`, and the document `o-10001` inside it. There is no schema, no table to create
and no column to declare. A collection exists while it holds a document and vanishes when it holds
none.

**The wrong idea is that a collection is a table and a subcollection a join.** A subcollection is not
stored inside its parent and is not read with it: reading `customers/c-17` returns the customer's two
fields and nothing of the orders, however many there are. What the path gives is a name and a scope. The
orders under `c-17` are a collection you can read on its own, cheaply, because the path says exactly
where they are, which is the same idea as the key of lesson 9, reached from the other side.

**This lesson is practised on the Firestore emulator**, which lesson 1 installed as
`cloud-firestore-emulator`. It is a Java program that speaks Firestore's API on your laptop, keeps
everything in memory, and is weaker than Firestore in one place this lesson goes looking for in its
third section.

## The emulator, in a terminal of its own

```sh
cd ~/gcp && export PATH="$HOME/gcp/google-cloud-sdk/bin:$HOME/gcp/bin:$PATH" && source venv/bin/activate
gcloud emulators firestore start --host-port=localhost:8080
```

**The Python client finds it through `FIRESTORE_EMULATOR_HOST`**, one of lesson 1's variables, and
sends no credentials when it is set. Leave it running and type the rest in your other terminal.

## Twenty customers and their orders

```schooling-example
{"language": "python", "file": "seed.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Write Quitanda's customers, each with a subcollection of orders, into Firestore.\n\n    python3 seed.py        # 20 customers, c-17 to c-36\n\nThe same run always writes the same documents.\n\"\"\"\nimport random\n\nfrom google.cloud import firestore\n\n", "note": "The docstring says how to run it. The library is the one lesson 1 installed, `google-cloud-firestore`."}, {"code": "NAMES = ['Ana', 'Bruno', 'Carla', 'Diego', 'Elisa', 'Fábio', 'Gabi', 'Heitor']\nDISTRICTS = ['Pinheiros', 'Mooca', 'Lapa', 'Tatuapé', 'Santana', 'Butantã']\nPRODUCTS = {'banana': 690, 'tomato': 899, 'rice-5kg': 2790, 'coffee-500g': 3450, 'eggs-12': 1590}\nSTATUSES = ['delivered', 'delivered', 'delivered', 'pending', 'cancelled']\n\n", "note": "What the generator draws from. Prices are integer cents, and three statuses in five are `delivered`, as most orders are."}, {"code": "db = firestore.Client(project='planner-dev')\nrnd = random.Random(17)\nbatch, written, order_no = db.batch(), {'customers': 0, 'orders': 0}, 10000\n\n", "note": "**The client finds the emulator through `FIRESTORE_EMULATOR_HOST`.** A seeded `Random` makes every run write the same documents, and one `batch` collects all the writes to send them together."}, {"code": "for n in range(20):\n    cid = f'c-{17 + n}'\n    customer = db.collection('customers').document(cid)\n    district = rnd.choice(DISTRICTS)\n    batch.set(customer, {'name': rnd.choice(NAMES), 'district': district})\n    written['customers'] += 1\n", "note": "**A document is named by its path**: collection `customers`, document id `c-17`. `set` writes the whole document, creating it if it does not exist and replacing it if it does."}, {"code": "    for day in sorted(rnd.sample(range(1, 31), rnd.randint(1, 5))):\n        order_no += 1\n        products = rnd.sample(sorted(PRODUCTS), rnd.randint(1, 3))\n        batch.set(customer.collection('orders').document(f'o-{order_no}'), {\n            'day': f'2026-10-{day:02d}',\n            'status': rnd.choice(STATUSES),\n            'district': district,\n            'products': products,\n            'total_cents': sum(PRODUCTS[p] * rnd.randint(1, 3) for p in products),\n        })\n        written['orders'] += 1\n", "note": "**Each order is a document in the customer's own `orders` subcollection**, `customers/c-17/orders/o-10001`. It repeats the district, because a query reads one collection group and cannot join to the customer; `products` is an array, which gets an index of its own."}, {"code": "batch.commit()\nprint(f\"{written['customers']} customers, {written['orders']} orders\")\n", "note": "`commit` sends the batch. Nothing was written before this line, and everything is written by it, or nothing is."}]}
```

```
ana@laptop:~/gcp$ python3 seed.py
20 customers, 53 orders
```

**Seventy-three documents, written in one batch and created by nothing but being written.** Neither
`customers` nor `orders` was created first; the first `set` into each brought it into being. A batch
commits all its writes together or none of them.

## Reading a document, and what it does not bring

```
ana@laptop:~/gcp$ python3 -c "from google.cloud import firestore; print(firestore.Client(project='planner-dev').document('customers/c-17').get().to_dict())"
{'name': 'Gabi', 'district': 'Santana'}
ana@laptop:~/gcp$ python3 -c "from google.cloud import firestore; print([c.id for c in firestore.Client(project='planner-dev').document('customers/c-17').collections()])"
['orders']
```

**A document read returns its own fields and nothing else.** `c-17` has a subcollection, and the read
did not include it; listing the collections under the document is a separate call, and reading them is
another. On Google Cloud each of those is billed as reads, one per document returned, which the last
section of this lesson prices.

**A field's value has a type, and the type decides how it sorts.** Strings, integers, floating-point
numbers, booleans, timestamps, maps, arrays, references to other documents and geographical points
are all values a field can hold, and the same field may hold different types in different documents.
Firestore orders values of different types by a fixed order of types, documented as "the value type
ordering", before it orders values within a type. That matters the first time a field holds `"100"`
in one document and `100` in another and a query sorted on it puts them far apart. `seed.py` writes the
day as a string, `2026-10-06`, which sorts correctly because the format puts the year first; money is
an integer of cents, as everywhere in this course.

## A document has a size limit

**A document holds at most 1 MiB**, Firestore's documented limit, field names and values included, and
one field's value at most 1 MiB less 89 bytes. The emulator enforces the second:

```
ana@laptop:~/gcp$ python3 -c "from google.cloud import firestore; firestore.Client(project='planner-dev').document('customers/c-17').set({'notes': 'x' * 1100000})" 2>&1 | tail -1
google.api_core.exceptions.InvalidArgument: 400 The value of property "notes" is longer than 1048487 bytes.
```

**1,048,487 bytes is exactly 1 MiB less 89**, the limit Firestore documents for a field's value. That
limit is a design rule as much as a number: an order belongs
in its own document under the customer, not in an array inside the customer's document, which would
grow with every order until the day it stopped accepting them. A subcollection has no size limit at
all, and that is what it is for.

## Where an order should live

**The path is the one design decision Firestore asks for up front**, and there are three places an
order could go. Each answers one question cheaply and makes another harder:

| an order as | the cheap question | the harder one |
|---|---|---|
| an element of an array in the customer's document | the customer with all their orders, one read | anything past 1 MiB, and every order rewrites the customer |
| a document in `customers/{id}/orders` | one customer's orders, by path | every order of a day, which needs a collection group query |
| a document in a top-level `orders` collection, with a `customer` field | every order of a day, on one collection | one customer's orders, which needs an index on `customer` |

**Quitanda chooses the subcollection**, because the screen the app shows most is one customer's own
orders, and a path reaches them without any index of its own. The analysts' questions across all
customers go through collection group queries, the subject of the next two sections, and the
heaviest of them belong in the warehouse of lesson 13 rather than in Firestore at all. **A
reference between documents is a value, not a constraint**: the order could store the path of a
product document, and nothing would stop that product being deleted. There are no foreign keys in
Firestore, and the integrity the schema enforced in lesson 9 is the program's job here.
