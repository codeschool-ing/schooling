---
title: Splitting the orders by customer
version: 1
---

Sharding starts with one decision, and it is the one that is hardest to change later: **the shard
key**, the value that decides which shard a row lives on. Every query that includes the key goes to one
shard. Every query that does not has to go to all of them.

For Quitanda's orders the candidates are the customer, the order's date and the order's id. The customer
is usually right for orders, because most questions are about one customer's orders: their history,
their basket, their latest delivery. The date is tempting and almost always wrong for writes: every new
order goes to the shard for today, so one shard takes all the writes while the others sit idle, which is
a **hot spot**.

There are two ways to turn a key into a shard:

- **By range**: customers A to H on shard 0, I to Q on shard 1. Ranges keep neighbours together, so
  "every customer whose name starts with B" is one shard, but they need to be chosen and moved as the
  data grows unevenly.
- **By hash**: a hash of the key, modulo the number of shards. A good hash spreads keys evenly, which is
  why it is the default, at the cost of scattering neighbours across every shard.

## The lab: two databases and a router

Two PostgreSQL servers that know nothing about each other, and a program that decides where each order
goes. Real systems put this logic in a library, a proxy, or the database itself, but it is the same
function. It lives in `~/lab/shards`:

```sh
mkdir -p ~/lab/shards && cd ~/lab/shards
```

`schema.sql`:

```schooling-example
{"language": "sql", "file": "schema.sql", "parts": [{"code": "CREATE TABLE orders (\n    id       bigint PRIMARY KEY,\n    customer text NOT NULL,\n    product  text NOT NULL,\n    units    int NOT NULL\n);\nCREATE INDEX ON orders (customer);", "note": "The same table on both shards. Each shard holds only its own customers' orders, and neither knows the other exists."}]}
```

`shard.py`:

```schooling-example
{"language": "python", "file": "shard.py", "parts": [{"code": "\"\"\"Quitanda's orders, split across two databases by customer.\"\"\"\nimport random, sys, zlib\nimport psycopg\n\nSHARDS = [psycopg.connect(f\"host=shard-{i} user=postgres password=quitanda\", autocommit=True)\n          for i in range(2)]\nPRODUCTS = [\"coffee\", \"tea\", \"rice\", \"beans\", \"flour\", \"sugar\", \"oil\", \"salt\"]\n\n\ndef shard_of(customer, count=len(SHARDS)):\n    return zlib.crc32(customer.encode()) % count\n\n", "note": "The router. Every order belongs to a customer, and the customer decides the shard: a hash of the customer's id, modulo the number of shards. That one function is the whole of what makes two databases look like one."}, {"code": "def load():\n    rng = random.Random(59)\n    for n in range(1, 2001):\n        c = rng.randint(1, 40)\n        product = rng.choice(PRODUCTS[c % 5:c % 5 + 4])\n        SHARDS[shard_of(f\"c-{c}\")].execute(\n            \"INSERT INTO orders VALUES (%s, %s, %s, %s)\", (n, f\"c-{c}\", product, rng.randint(1, 4)))\n    for i, db in enumerate(SHARDS):\n        print(f\"shard-{i}: {db.execute('SELECT count(*) FROM orders').fetchone()[0]} orders\")\n\n", "note": "The same 2,000 orders every time, from a random generator with a fixed seed: 40 customers, and each customer buys from four of the eight products."}, {"code": "def customer(c):\n    i = shard_of(c)\n    n, units = SHARDS[i].execute(\n        \"SELECT count(*), sum(units) FROM orders WHERE customer = %s\", (c,)).fetchone()\n    print(f\"{c} is on shard-{i}: {n} orders, {units} units\")\n\n", "note": "A question about one customer goes to one shard, and the shard answers it alone, with its index."}, {"code": "def order(n):\n    for i, db in enumerate(SHARDS):\n        row = db.execute(\"SELECT customer, product, units FROM orders WHERE id = %s\", (n,)).fetchone()\n        print(f\"asked shard-{i}: {row or 'not here'}\")\n\n", "note": "A question about an order by its id has no customer in it, so every shard has to be asked."}, {"code": "def top(naive):\n    limit = \"LIMIT 3\" if naive else \"\"\n    totals = {}\n    for db in SHARDS:\n        for product, units in db.execute(\n                f\"SELECT product, sum(units) FROM orders GROUP BY product ORDER BY 2 DESC {limit}\"):\n            totals[product] = totals.get(product, 0) + units\n    for product, units in sorted(totals.items(), key=lambda kv: -kv[1])[:3]:\n        print(f\"{product:8} {units}\")\n\n", "note": "The best-selling products need every shard. `--naive` asks each shard for its own top three and merges those; the default asks each for the totals of every product and adds them up here."}, {"code": "def moves(count):\n    moved = sum(shard_of(f\"c-{c}\") != shard_of(f\"c-{c}\", count) for c in range(1, 41))\n    print(f\"{moved} of 40 customers change shard going from 2 shards to {count}\")\n\n\ncmd, *args = sys.argv[1:]\nif cmd == \"load\":\n    load()\nelif cmd == \"customer\":\n    customer(args[0])\nelif cmd == \"order\":\n    order(int(args[0]))\nelif cmd == \"top\":\n    top(\"--naive\" in args)\nelif cmd == \"moves\":\n    moves(int(args[0]))", "note": "How many of the 40 customers would live on a different shard if there were three shards instead of two."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nRUN pip install --no-cache-dir \"psycopg[binary]==3.3.6\"\nWORKDIR /app\nCOPY shard.py .", "note": "Python and psycopg, the PostgreSQL driver."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "x-shard: &shard\n  image: postgres:17\n  environment:\n    POSTGRES_PASSWORD: quitanda\n  volumes:\n    - ./schema.sql:/docker-entrypoint-initdb.d/schema.sql:ro\nservices:\n  shard-0:\n    <<: *shard\n  shard-1:\n    <<: *shard\n  tools:\n    build: .\n    profiles: [\"tools\"]\n    depends_on:\n      - shard-0\n      - shard-1", "note": "Two PostgreSQL servers that know nothing about each other, each creating the `orders` table on its first start, and the image that runs `shard.py` against them."}]}
```

Start the two shards, give them about ten seconds, and save typing with a variable for the router:

```sh
docker compose up -d
R="docker compose --progress quiet run --rm tools python shard.py"
```

Load the orders, and ask about one customer:

```
ana@vm:~/lab/shards$ $R load
shard-0: 1054 orders
shard-1: 946 orders
ana@vm:~/lab/shards$ $R customer c-7
c-7 is on shard-1: 55 orders, 147 units
```

The hash put 21 customers on shard 0 and 19 on shard 1, so the orders split roughly in half: 1,054 and
946. A question about `c-7` went to shard 1 only, which answered it with its own index, exactly as a
single database would have. **That is the case sharding is designed for**, and with the right key it is
most of the traffic.

Now look an order up by its id, which is not the shard key:

```
ana@vm:~/lab/shards$ $R order 1234
asked shard-0: ('c-1', 'flour', 4)
asked shard-1: not here
```

The router has no way to know where order 1234 lives, so it asked both shards. With two shards that is
one wasted query. With forty, every lookup by id is forty queries, and the slowest of the forty decides
how long the page takes. That is the first sign of a query that no longer fits.
