---
title: Every query reads an index, and most indexes are already there
version: 1
---

**Firestore answers every query from an index, and refuses any query no index can answer.** There is
no scan to fall back on. That sounds like the strictest database in this course, and for most queries
it is the most relaxed, because Firestore builds the indexes itself: for every field of every
document, an ascending index, a descending one, and for an array an `array-contains` index. A query on
one field reads one of those, in order, and stops when it has what it asked for.

**The wrong idea is that indexes are something you add for speed.** In PostgreSQL a query without an
index still runs, slowly. In Firestore the index is what makes the query possible, and its cost is
paid on every write: one document written is one entry in every index that covers one of its fields,
which is why storage is billed with the index entries included. The automatic ones are called
**single-field indexes**, and this section uses nothing else.

## Six questions, by name

```schooling-example
{"language": "python", "file": "query.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Run one of Quitanda's queries by name and print what it returns.\n\n    python3 query.py NAME\n\"\"\"\nimport sys\n\nfrom google.cloud import firestore\nfrom google.cloud.firestore_v1.base_query import FieldFilter\n\ndb = firestore.Client(project='planner-dev')\norders = db.collection_group('orders')\nDESC = firestore.Query.DESCENDING\n\n", "note": "**`collection_group('orders')` is every collection named `orders`**, under every customer, read as one. `FieldFilter` is how the current library spells a `where`."}, {"code": "QUERIES = {\n    'one-customer': db.collection('customers').document('c-17').collection('orders'),\n    'pending': orders.where(filter=FieldFilter('status', '==', 'pending')),\n    'big': orders.where(filter=FieldFilter('total_cents', '>=', 10000)).order_by('total_cents', direction=DESC),\n    'coffee': orders.where(filter=FieldFilter('products', 'array_contains', 'coffee-500g')),\n", "note": "**Four questions about one field each.** One customer's orders by path; the pending ones; the ones of 100.00 or more, biggest first; the ones with coffee in them."}, {"code": "    'pending-biggest': orders.where(filter=FieldFilter('status', '==', 'pending')).order_by('total_cents', direction=DESC),\n    'lapa-late-october': orders.where(filter=FieldFilter('district', '==', 'Lapa'))\n                               .where(filter=FieldFilter('day', '>=', '2026-10-20')),\n}\n\n", "note": "**Two questions about two fields each**: an equality sorted by another field, and an equality with a range on another field. The next section is about these two."}, {"code": "for doc in QUERIES[sys.argv[1]].limit(5).stream():\n    o = doc.to_dict()\n    print(f\"{doc.reference.path:<32} {o['day']} {o['status']:<9} {o['total_cents']:>6} {','.join(o['products'])}\")\n", "note": "**At most five documents per query**, each printed with its full path, which shows which customer's subcollection it came from."}]}
```

**Four of those queries are about one field each**, so the single-field indexes cover them:

```
ana@laptop:~/gcp$ python3 query.py one-customer
customers/c-17/orders/o-10001    2026-10-06 delivered   6149 tomato,eggs-12,banana
customers/c-17/orders/o-10002    2026-10-10 pending     4287 eggs-12,tomato
customers/c-17/orders/o-10003    2026-10-12 delivered   3450 coffee-500g
ana@laptop:~/gcp$ python3 query.py pending
customers/c-17/orders/o-10002    2026-10-10 pending     4287 eggs-12,tomato
customers/c-18/orders/o-10006    2026-10-29 pending     7049 banana,eggs-12,tomato
customers/c-23/orders/o-10014    2026-10-09 pending    12449 eggs-12,tomato,rice-5kg
customers/c-26/orders/o-10020    2026-10-07 pending     9960 rice-5kg,eggs-12
customers/c-30/orders/o-10029    2026-10-04 pending     9929 coffee-500g,rice-5kg,tomato
ana@laptop:~/gcp$ python3 query.py big
customers/c-23/orders/o-10016    2026-10-27 delivered  20040 eggs-12,coffee-500g,rice-5kg
customers/c-33/orders/o-10042    2026-10-14 delivered  15810 coffee-500g,eggs-12,banana
customers/c-18/orders/o-10004    2026-10-04 delivered  15600 banana,eggs-12,coffee-500g
customers/c-34/orders/o-10046    2026-10-25 pending    14730 coffee-500g,rice-5kg,eggs-12
customers/c-33/orders/o-10040    2026-10-04 delivered  13740 eggs-12,coffee-500g,banana
ana@laptop:~/gcp$ python3 query.py coffee
customers/c-17/orders/o-10003    2026-10-12 delivered   3450 coffee-500g
customers/c-18/orders/o-10004    2026-10-04 delivered  15600 banana,eggs-12,coffee-500g
customers/c-18/orders/o-10005    2026-10-18 delivered  12210 coffee-500g,rice-5kg,eggs-12
customers/c-19/orders/o-10007    2026-10-18 cancelled   6900 coffee-500g
customers/c-20/orders/o-10008    2026-10-26 delivered  12148 coffee-500g,tomato
```

**`one-customer` is the cheapest read in Firestore**: a collection named by its full path, read in
document order. The other three are **collection group** queries, `collection_group('orders')`, which
read every collection called `orders` wherever it sits, under any customer. `pending` is an equality on
one field, `big` a range and an order on the same field, and `coffee` reads the `array-contains` index
of `products`, where each element of the array is an entry of its own.

**Each answer stops at five because of `limit(5)`**, and that is not decoration: Firestore bills a read
per document returned, so a query that names its limit names its price. A query without one returns
everything that matches, and pays for all of it.

## What the emulator did not ask for

**On Google Cloud, those three collection group queries would have failed the first time.** Firestore
maintains single-field indexes automatically for queries on one collection; for a **collection group**
scope, its documentation says the single-field index has to be enabled per field, and a query that
needs one is refused with a message that carries a link to create it. The emulator answered all three
without any of that. It is the first sign of what the next section finds: the emulator in its default
mode does not check indexes at all.

**And the two remaining queries need more than a single-field index anywhere.** `pending-biggest` is an
equality on `status` sorted by `total_cents`, and `lapa-late-october` an equality on `district` with a
range on `day`. Neither field's index alone holds the rows in the order the query needs, which is the
subject of the next section.

## When an automatic index is the wrong default

**Every field is indexed unless you say otherwise**, and two kinds of field are better without it. A
large text field, such as the courier's notes, makes index entries nobody will ever query, and they
are storage on the bill. And a field whose value grows with every write, a timestamp or a counter, is
lesson 9's hotspot again: Firestore's documentation puts a limit of about 500 writes per second on a
collection whose documents carry a sequentially increasing indexed value, because every new entry lands
at the end of that field's index.

**The way out is an index exemption**, a per-field setting that turns its automatic indexes off or
changes them. On Google Cloud it is one command, shown here and **not run**, because the index
commands go to Firestore's admin service, which has no emulator:

```sh
gcloud firestore indexes fields update notes --collection-group=orders --disable-indexes
```

**An exemption is a decision about queries you will not ask**: a field with its indexes disabled cannot
be filtered or sorted on at all, and Firestore will refuse the query rather than read every document.
That is the trade the whole section has been about. Firestore never scans, so every query costs what
it returns; the price is that a question nobody indexed for has no answer until somebody does.
