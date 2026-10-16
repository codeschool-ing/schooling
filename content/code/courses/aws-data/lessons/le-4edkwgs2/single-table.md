---
title: Single-table design for Quitanda
version: 1
---

**The relational instinct gives Quitanda three tables, `customers`, `orders` and `order_lines`, and
in DynamoDB that is three round trips for one screen.** There is no join, so "an order with its lines"
becomes a read of the order, then a read of its lines, and the application stitches them together.
Single-table design does the stitching once, when the data is written: every kind of item that is
read together goes into one table, under keys built so that the read is one `query`.

**The keys are overloaded.** `pk` and `sk` hold different kinds of value for different kinds of item,
and a prefix in the value says which: `CUSTOMER#`, `ORDER#`, `LINE#`. That is why the attributes are
called `pk` and `sk` and not `customer_id` and `order_date`, which would be false for half the items.
Quitanda's three kinds:

| item | `pk` | `sk` | its own attributes |
|---|---|---|---|
| profile | `CUSTOMER#c-17` | `PROFILE` | `name`, `district` |
| order | `CUSTOMER#c-17` | `ORDER#2026-10-05#o-10002` | `order_id`, `order_day`, `total_cents`, `line_count` |
| order line | `CUSTOMER#c-17` | `ORDER#2026-10-05#o-10002#LINE#1` | `product`, `qty`, `price_cents` |

All three share the customer's partition key, so **a customer, every order and every line are one item
collection**, sorted by `sk`. And each access pattern of the previous section turns into one read:

| | the read |
|---|---|
| A1, the profile | `get-item` with `pk = CUSTOMER#c-17` and `sk = PROFILE` |
| A2, orders in a date range | `query` with `pk = CUSTOMER#c-17` and `sk BETWEEN ORDER#2026-10-01 AND ORDER#2026-10-08` |
| A3, one order and its lines | `query` with `pk = CUSTOMER#c-17` and `begins_with(sk, ORDER#2026-10-05#o-10002)` |
| A4, the latest order | `query` on `begins_with(sk, ORDER#)`, newest first, one item |
| A5, one day across customers | none: a scan, until lesson 10 |

## Loading it

**The data comes from a short program**, written with boto3, the Python library for AWS. Save it as
`~/aws/seed.py` the way lesson 1 saved `prices.py`: the copy button on the block, then `nano seed.py`,
paste, Ctrl+O, Enter and Ctrl+X.

```schooling-example
{"language": "python", "file": "seed.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Load Quitanda's customers, orders and order lines into the table `quitanda`.\n\n    python3 seed.py         # three customers, c-17 to c-19\n    python3 seed.py 4000    # four thousand\n\nThe same number always writes the same items. The table must exist.\n\"\"\"\nimport random\nimport sys\n\nimport boto3\n\n", "note": "The docstring says how to run it. With no argument it writes three customers, small enough to read every item; lesson 10 runs it with a larger number to have a table worth scanning."}, {"code": "NAMES = ['Ana', 'Bruno', 'Carla', 'Diego', 'Elisa', 'Fábio', 'Gabi', 'Heitor']\nDISTRICTS = ['Pinheiros', 'Mooca', 'Lapa', 'Tatuapé', 'Santana', 'Butantã']\nPRODUCTS = [('banana', 690), ('tomato', 899), ('rice-5kg', 2790),\n            ('coffee-500g', 3450), ('eggs-12', 1590), ('milk-1l', 549)]\n\n", "note": "The material the generator draws from. Prices are integer cents, as money is everywhere in this course."}, {"code": "customers = int(sys.argv[1]) if len(sys.argv) > 1 else 3\nrnd = random.Random(17)\ntable = boto3.resource('dynamodb').Table('quitanda')\norder_no, written = 10000, {'PROFILE': 0, 'ORDER': 0, 'LINE': 0}\n\n", "note": "**boto3 came with moto**, so there is nothing to install, and it reads the same variables as the command line: `AWS_ENDPOINT_URL` sends it to moto. A seeded `Random` makes every run write the same items, which is what lets this lesson print them."}, {"code": "with table.batch_writer() as batch:\n    for n in range(customers):\n        cid = f'c-{17 + n}'\n        pk = f'CUSTOMER#{cid}'\n        batch.put_item(Item={'pk': pk, 'sk': 'PROFILE', 'customer_id': cid,\n                             'name': rnd.choice(NAMES), 'district': rnd.choice(DISTRICTS)})\n        written['PROFILE'] += 1\n", "note": "`batch_writer` collects puts and sends them 25 at a time, in `BatchWriteItem` requests, which is the most the API takes in one. The profile is the first item of each customer's collection: partition key `CUSTOMER#<id>`, sort key `PROFILE`."}, {"code": "        days = sorted(rnd.sample(range(1, 15), rnd.randint(1, 4)))\n        for day in days:\n            order_no += 1\n            oid, date = f'o-{order_no}', f'2026-10-{day:02d}'\n            order_sk = f'ORDER#{date}#{oid}'\n", "note": "One to four orders per customer, on days of October 2026. **The order's sort key starts with its date**, `ORDER#2026-10-05#o-10002`, so a customer's orders sort by date, and the order id after it keeps two orders of one day apart. Order ids have five digits from the start, so that one id is never the beginning of another."}, {"code": "            lines = rnd.sample(PRODUCTS, rnd.randint(1, 3))\n            total = 0\n            for i, (product, price) in enumerate(lines, start=1):\n                qty = rnd.randint(1, 3)\n                total += qty * price\n                batch.put_item(Item={'pk': pk, 'sk': f'{order_sk}#LINE#{i}',\n                                     'product': product, 'qty': qty, 'price_cents': price})\n                written['LINE'] += 1\n", "note": "**A line's sort key is its order's, plus `#LINE#` and a number**, so the lines sort immediately after their order and a query for the order's prefix returns both."}, {"code": "            order = {'pk': pk, 'sk': order_sk, 'order_id': oid, 'order_day': date,\n                     'total_cents': total, 'line_count': len(lines)}\n            if day == 14:\n                order['pending_since'] = date\n            batch.put_item(Item=order)\n            written['ORDER'] += 1\n\n", "note": "The order itself carries its total, its day and its id as plain attributes as well as inside the key, because lesson 10 builds indexes on them. An order of 14 October is not delivered yet and carries `pending_since`; the last section of this lesson uses it."}, {"code": "print(f\"{customers} customers: {written['PROFILE']} profiles, {written['ORDER']} orders, \"\n      f\"{written['LINE']} order lines, {sum(written.values())} items\")\n", "note": "A count of what was written, by kind, so a run says what it did."}]}
```

```
ana@laptop:~/aws$ python3 seed.py
3 customers: 3 profiles, 9 orders, 18 order lines, 30 items
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda --query 'Items[].[pk.S,sk.S]' --output text
CUSTOMER#c-17	ORDER#2026-10-03#o-10001
CUSTOMER#c-17	ORDER#2026-10-03#o-10001#LINE#1
CUSTOMER#c-17	ORDER#2026-10-03#o-10001#LINE#2
CUSTOMER#c-17	ORDER#2026-10-03#o-10001#LINE#3
CUSTOMER#c-17	ORDER#2026-10-05#o-10002
CUSTOMER#c-17	ORDER#2026-10-05#o-10002#LINE#1
CUSTOMER#c-17	ORDER#2026-10-05#o-10002#LINE#2
CUSTOMER#c-17	ORDER#2026-10-05#o-10002#LINE#3
CUSTOMER#c-17	ORDER#2026-10-12#o-10003
CUSTOMER#c-17	ORDER#2026-10-12#o-10003#LINE#1
CUSTOMER#c-17	ORDER#2026-10-12#o-10003#LINE#2
CUSTOMER#c-17	PROFILE
CUSTOMER#c-18	ORDER#2026-10-06#o-10004
CUSTOMER#c-18	ORDER#2026-10-06#o-10004#LINE#1
CUSTOMER#c-18	ORDER#2026-10-09#o-10005
CUSTOMER#c-18	ORDER#2026-10-09#o-10005#LINE#1
CUSTOMER#c-18	PROFILE
CUSTOMER#c-19	ORDER#2026-10-03#o-10006
CUSTOMER#c-19	ORDER#2026-10-03#o-10006#LINE#1
CUSTOMER#c-19	ORDER#2026-10-03#o-10006#LINE#2
CUSTOMER#c-19	ORDER#2026-10-10#o-10007
CUSTOMER#c-19	ORDER#2026-10-10#o-10007#LINE#1
CUSTOMER#c-19	ORDER#2026-10-10#o-10007#LINE#2
CUSTOMER#c-19	ORDER#2026-10-11#o-10008
CUSTOMER#c-19	ORDER#2026-10-11#o-10008#LINE#1
CUSTOMER#c-19	ORDER#2026-10-14#o-10009
CUSTOMER#c-19	ORDER#2026-10-14#o-10009#LINE#1
CUSTOMER#c-19	ORDER#2026-10-14#o-10009#LINE#2
CUSTOMER#c-19	ORDER#2026-10-14#o-10009#LINE#3
CUSTOMER#c-19	PROFILE
```

**Thirty items, and the first twelve are one customer.** moto lists the whole table in key order,
which is a convenience of its dictionary; AWS would return the three collections in the order of
their hashes, each still sorted inside. The order inside the collection is the sort
key's, byte by byte. Each order is followed at once by its own lines, because `ORDER#2026-10-03#o-10001`
is a prefix of `ORDER#2026-10-03#o-10001#LINE#1` and a prefix sorts before everything that extends
it. The orders run by date because the date comes first in the key. And `PROFILE` comes last, after
every order, because `P` is a later letter than `O`. Nothing about a profile makes it first;
if it had to be, its sort key would need to begin with a character that sorts before `O`.

**The design is in the strings, and the strings are permanent.** Nothing in DynamoDB knows that `#`
separates fields, that the date is year-month-day, or that the order id has five digits. Those are
conventions of this table, enforced by the one program that writes it, and changing one later means
rewriting every item that follows the old one. It is lesson 1's rule about S3 keys, for the same
reason: a key is the only handle the reads have.

**One table does not mean one kind of item per screen.** Single-table design is a choice made for
the patterns that read different kinds of item together. Data that is never read with anything else
gains nothing from sharing a table, and some teams keep it apart for exactly the reasons a relational
designer would: separate backups, separate permissions, separate capacity.
