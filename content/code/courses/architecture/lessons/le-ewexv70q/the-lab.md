---
title: The lab: a database a millisecond away
version: 1
---

PostgreSQL, the latency proxy in front of it, and the shop's data-access code, with each page written
both ways. It lives in `~/lab/perf`:

```sh
mkdir -p ~/lab/perf && cd ~/lab/perf
```

`latency.py`, the proxy:

```schooling-example
{"language": "python", "file": "latency.py", "parts": [{"code": "\"\"\"Forward TCP to the database, one millisecond late each way.\"\"\"\nimport asyncio\n\nDELAY = 0.001\n\n\nasync def pipe(reader, writer):\n    try:\n        while data := await reader.read(65536):\n            await asyncio.sleep(DELAY)\n            writer.write(data)\n            await writer.drain()\n    finally:\n        writer.close()\n\n\nasync def handle(client_reader, client_writer):\n    db_reader, db_writer = await asyncio.open_connection(\"db\", 5432)\n    await asyncio.gather(pipe(client_reader, db_writer), pipe(db_reader, client_writer))\n\n\nasync def main():\n    server = await asyncio.start_server(handle, \"\", 5432)\n    await server.serve_forever()\n\n\nasyncio.run(main())", "note": "A TCP proxy that holds every chunk of data for one millisecond before passing it on, in both directions. Between the shop and the database it turns a round trip on one machine, a fraction of a millisecond, into about two, which is what a database in the next availability zone costs."}]}
```

`shop.py`, the pages:

```schooling-example
{"language": "python", "file": "shop.py", "parts": [{"code": "\"\"\"Quitanda's pages, each written the easy way and the fast way, measured.\"\"\"\nimport random, sys, time\nimport psycopg\n\ndb = psycopg.connect(\"host=latency user=postgres password=quitanda\", autocommit=True)\nstats = {\"queries\": 0, \"rows\": 0, \"bytes\": 0}\n\n\ndef q(sql, *args):\n    cur = db.execute(sql, args)\n    rows = cur.fetchall() if cur.description else []\n    stats[\"queries\"] += 1\n    stats[\"rows\"] += len(rows)\n    stats[\"bytes\"] += sum(len(str(v)) for r in rows for v in r)\n    return rows\n\n", "note": "Quitanda's data-access code, written three ways for each page: the way that is easy to write, and the way that is fast. Every command prints how many queries it sent, how many rows and bytes came back, and how long it took. It connects to the database through the latency proxy, as the shop would across a network."}, {"code": "def seed():\n    rng = random.Random(16)\n    db.execute(\"\"\"\n        CREATE EXTENSION pg_stat_statements;\n        CREATE TABLE products (id int PRIMARY KEY, name text, cents int, description text);\n        CREATE TABLE orders (id int PRIMARY KEY, customer text, placed date);\n        CREATE TABLE items (order_id int, product_id int, units int);\n    \"\"\")\n    with db.cursor() as cur:\n        cur.executemany(\"INSERT INTO products VALUES (%s, %s, %s, %s)\",\n                        [(p, f\"product {p}\", rng.randint(500, 5000), \"x\" * 20000) for p in range(1, 51)])\n        cur.executemany(\"INSERT INTO orders VALUES (%s, %s, date '2026-01-01' + %s)\",\n                        [(o, f\"c-{rng.randint(1, 200)}\", rng.randint(0, 270)) for o in range(1, 2001)])\n        cur.executemany(\"INSERT INTO items VALUES (%s, %s, %s)\",\n                        [(o, rng.randint(1, 50), rng.randint(1, 3)) for o in range(1, 2001) for _ in range(4)])\n    print(\"seeded\")\n\n", "note": "`seed` fills the database once: 200 customers, 2,000 orders of four items each, and 50 products, each with a 20 KB description, which is the size of a product page's text and a few small images' worth of metadata."}, {"code": "def history_n1(customer):\n    for (order,) in q(\"SELECT id FROM orders WHERE customer = %s\", customer):\n        q(\"SELECT product_id, units FROM items WHERE order_id = %s\", order)\n\n\ndef history_join(customer):\n    q(\"SELECT o.id, i.product_id, i.units FROM orders o JOIN items i ON i.order_id = o.id \"\n      \"WHERE o.customer = %s\", customer)\n\n", "note": "The order history, the easy way: one query for the customer's orders, then one per order for its items. This is the **N+1** pattern, and an ORM's lazy loading writes it for you without a line that looks like a loop over the database."}, {"code": "def catalogue_star():\n    q(\"SELECT * FROM products ORDER BY id\")\n\n\ndef catalogue_columns():\n    q(\"SELECT id, name, cents FROM products ORDER BY id\")\n\n", "note": "The catalogue list, which shows a name and a price. `SELECT *` brings each product's whole description along with them."}, {"code": "def best_sellers():\n    q(\"SELECT i.product_id, sum(i.units) FROM items i JOIN orders o ON o.id = i.order_id \"\n      \"WHERE o.placed > date '2026-09-28' - 30 GROUP BY 1 ORDER BY 2 DESC LIMIT 5\")\n\n", "note": "The best sellers of the last 30 days, which the shop's front page shows to every visitor. The query is correct; what matters is how often it runs and what it reads each time."}, {"code": "cache = {}\n\n\ndef front_page(*flags):\n    for _ in range(100):\n        if \"--cached\" in flags and time.time() - cache.get(\"at\", 0) < 60:\n            continue\n        best_sellers()\n        cache[\"at\"] = time.time()\n\n\nPAGES = {\"history-n1\": history_n1, \"history-join\": history_join, \"catalogue-star\": catalogue_star,\n         \"catalogue-columns\": catalogue_columns, \"best-sellers\": best_sellers, \"front-page\": front_page}\nname, *args = sys.argv[1:]\nif name == \"seed\":\n    seed()\nelse:\n    start = time.time()\n    PAGES[name](*args)\n    print(f\"{name}: {stats['queries']} queries, {stats['rows']} rows, {stats['bytes']:,} bytes, \"\n          f\"{(time.time() - start) * 1000:.0f} ms\")", "note": "A hundred visitors open the front page. Without `--cached`, each one runs the best-sellers query; with it, the answer is kept for a minute and the database is asked once."}]}
```

`Dockerfile`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM python:3.12-slim\nRUN pip install --no-cache-dir \"psycopg[binary]==3.3.6\"\nWORKDIR /app\nCOPY *.py .", "note": "Python and psycopg, as in lessons 10 and 13."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  db:\n    image: postgres:17\n    command: postgres -c shared_preload_libraries=pg_stat_statements\n    environment:\n      POSTGRES_PASSWORD: quitanda\n  latency:\n    build: .\n    command: python latency.py\n    depends_on:\n      - db\n  tools:\n    build: .\n    profiles: [\"tools\"]\n    entrypoint: [\"python\", \"shop.py\"]\n    depends_on:\n      - latency", "note": "PostgreSQL, started with `pg_stat_statements`, the extension that counts what every query costs the database; the latency proxy in front of it; and the image that runs the shop's pages."}]}
```

Start the database and the proxy, give them ten seconds, keep the command for the pages in a variable,
and fill the database:

```sh
docker compose up -d
P="docker compose --progress quiet run --rm tools"
```

```
ana@vm:~/lab/perf$ $P seed
seeded
```

The numbers each page prints are the lesson's measurements: queries sent, rows and bytes received, and
the time from the first query to the last answer, as the shop's code saw it.
