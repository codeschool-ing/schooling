---
title: Cache-aside, the pattern almost everybody uses
version: 1
---

A **cache** keeps the answer to a question somewhere faster to reach than the place that computes
it, so that the next person who asks gets the stored answer instead of the work. For a database the
"somewhere" is usually a separate in-memory store, and the commonest one is **Redis**: a server
that keeps keys and values in memory and answers a lookup in a fraction of a millisecond.

The wrong belief to clear first is that a cache makes the database faster. It does not touch the
database. It makes **some answers** arrive without the database being asked, and every one of those
answers is a copy that can be out of date. The rest of this lesson is about that copy: how old it
may be (section 03), how to throw it away when it changes (section 04), and what happens the moment
it is missing (section 05). Lessons 3 to 11 made the question cheaper to answer; a cache avoids
asking it, which is worth doing only for questions that are asked far more often than their answers
change.

## Redis and a Python client

Install the server and the two Python libraries the program uses, all from Ubuntu's archive:

```sh
sudo apt install -y redis-server python3-redis python3-psycopg
```

`apt` starts Redis and enables it at boot. It listens only on the machine itself, port 6379. Check
that it answers:

```
ana@vm:~$ systemctl is-active redis-server
active
ana@vm:~$ redis-cli ping
PONG
```

`psycopg` is the PostgreSQL driver for Python, and `redis` the Redis one. The program below talks to
both, as an application would.

## The program

Lesson 2's seller dashboard is a good candidate. Sellers keep it open and refresh it, December's
numbers change a few times an hour per seller, and every refresh runs the same query. Save this as
`dashboard.py` in your home directory; the copy button takes the whole file without the notes:

```schooling-example
{"language": "python", "file": "dashboard.py", "parts": [{"code": "# dashboard.py: a seller's December dashboard, read through a cache.\nimport json, random, sys, time\nimport psycopg, redis\n\ndb = psycopg.connect(\"dbname=market\", autocommit=True)\ncache = redis.Redis()\nTTL = 60\nseen = {\"cache\": 0, \"database\": 0}\n", "note": "One connection to the database and one to Redis, both opened once, as an application holds them. `TTL` is how long a cached answer lives, sixty seconds here; section 03 is about choosing it. `seen` counts where answers came from."}, {"code": "QUERY = \"\"\"\n    SELECT date_trunc('day', placed_at)::date, count(*), sum(total_cents)::bigint\n    FROM orders\n    WHERE seller_id = %s AND placed_at >= '2025-12-01'\n    GROUP BY 1 ORDER BY 1\"\"\"\n\ndef from_database(seller):\n    rows = db.execute(QUERY, (seller,)).fetchall()\n    return [[str(day), n, total] for day, n, total in rows]\n", "note": "The dashboard's query from lesson 2, unchanged apart from two casts. The rows become plain lists so that they can be stored as JSON, and `::bigint` keeps the sum an integer: PostgreSQL's `sum` of integers is a `numeric`, which arrives in Python as a `Decimal` that JSON cannot hold."}, {"code": "def dashboard(seller):\n    key = f\"dashboard:{seller}\"\n    cached = cache.get(key)\n    if cached is not None:\n        seen[\"cache\"] += 1\n        return json.loads(cached), \"cache\"\n    rows = from_database(seller)\n    cache.set(key, json.dumps(rows), ex=TTL)\n    seen[\"database\"] += 1\n    return rows, \"database\"\n", "note": "**Cache-aside** in eight lines. Look in the cache under a key that names the question; on a hit, return what is there; on a miss, ask the database, store the answer with its TTL and return it. The database never knows the cache exists, and that is both the pattern's strength and, in section 04, its weakness."}, {"code": "def run(label, read, requests=5000):\n    random.seed(21)\n    start = time.perf_counter()\n    for _ in range(requests):\n        read(random.randint(2, 201))\n    ms = 1000 * (time.perf_counter() - start) / requests\n    print(f\"{label:<12} {requests} requests, {ms:.3f} ms each\")\n", "note": "The same 5000 requests, for sellers 2 to 201 in the same order every time (`random.seed`), timed once straight from the database and once through the cache. Two hundred sellers stand for the ones who keep their dashboard open."}, {"code": "if __name__ == \"__main__\":\n    if len(sys.argv) > 1:\n        seller = int(sys.argv[1])\n        rows, source = dashboard(seller)\n        orders = sum(n for _, n, _ in rows)\n        print(f\"seller {seller}: {orders} orders since 2025-12-01, \"\n              f\"from the {source}; expires in {cache.ttl(f'dashboard:{seller}')} s\")\n    else:\n        cache.flushdb()  # start cold; this Redis holds nothing else\n        run(\"database\", from_database)\n        run(\"cache-aside\", dashboard)\n        print(f\"cache-aside: {seen['cache']} hits, {seen['database']} misses\")", "note": "With a seller's number, it reads that one dashboard and says where the answer came from and how long it has left. Without, it empties the cache, which in this lab holds nothing else, and runs both timings."}]}
```

The shape in `dashboard()` is **cache-aside**, also called lazy loading: the application looks
aside, at the cache, before going to the database, and fills the cache only with answers somebody
actually asked for. The cache holds no rule about the data. It holds whatever the last miss put
there, under a key the application chose, for as long as the TTL says.

## Measured

Run it without arguments. It times 5000 dashboard requests straight from the database, then the
same 5000 through the cache:

```
ana@vm:~$ python3 dashboard.py
database     5000 requests, 3.757 ms each
cache-aside  5000 requests, 0.281 ms each
cache-aside: 4800 hits, 200 misses
```

**3.757 milliseconds a request from the database, and 0.281 through the cache**, about thirteen
times less. The cache answered **4800** of the 5000 requests and the database answered the **200**
misses, one for each seller the first time it was asked. Seen from the database, the dashboard's load fell by 96%: of 5000 requests it ran the query 200
times.

Two details keep this honest. Both timings include Python and a round trip to a server on the same
machine, so the cache's number is mostly the cost of asking Redis anything at all. And the database
side was already fast, because lesson 2 gave `orders` the index on `seller_id`; a cache in front of
a query that is slow for want of an index hides the problem instead of fixing it, and it comes back
on every miss.

## What makes a good thing to cache

- **Read often, changed rarely.** The ratio is what the 4800 to 200 above measures. A value read
  once per change is a cache that is always missing.
- **The same question, asked by many.** A key per seller works because each seller asks
  repeatedly. A key per arbitrary search string mostly holds answers nobody asks for again.
- **Expensive enough to be worth a second system.** Redis is another server to run, watch and
  restart. Saving 3.5 milliseconds on a page nobody waits for is not worth that.
- **Allowed to be a little old.** Everything else in this lesson follows from this one.
