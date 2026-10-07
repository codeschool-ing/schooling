---
title: Serving the old copy while one refreshes
version: 1
---

A lock makes readers wait for a fresh copy. For a book's page, a copy a few seconds old would have done
just as well, and nobody would have waited. **Serving stale while revalidating** keeps the copy past its
freshness, hands it out, and lets one reader refresh it in the background. Lesson 6 did this in Nginx
with `proxy_cache_use_stale updating`; this is the same idea in the application.

The trick is two lifetimes. The value carries its own `fresh_until`, five minutes, and the key lives an
hour longer than that, so a stale copy is still there to serve:

```schooling-example
{"language": "python", "file": "swrcache.py", "parts": [{"code": "import json\nimport threading\nimport time\n\nimport redis\n\nimport catalogue\n\nr = redis.Redis(decode_responses=True)\nFRESH, STALE = 300, 3600\nREFRESH_MS = 2000\n\n\ndef load(book_id):\n    book = catalogue.get_book(book_id)\n    entry = {\"book\": book, \"fresh_until\": time.time() + FRESH}\n    r.set(f\"book:{book_id}\", json.dumps(entry), ex=FRESH + STALE)\n    return book\n\n\ndef get_book(book_id):\n    cached = r.get(f\"book:{book_id}\")\n    if cached is None:\n        return load(book_id)\n    entry = json.loads(cached)\n    if entry[\"fresh_until\"] < time.time():\n        if r.set(f\"refresh:book:{book_id}\", 1, nx=True, px=REFRESH_MS):\n            threading.Thread(target=load, args=(book_id,)).start()\n    return entry[\"book\"]\n", "note": "Serves a stale copy at once and refreshes it in the background, at most once every two seconds."}]}
```

The refresh flag is a lock with nobody to release it: **it simply expires after two seconds**, which also
limits refreshes of one book to one every two seconds even if a refresh fails.

To see it, this program plants a copy that went stale a minute ago, holding the old price, then changes
the price in the database and sends fifty readers:

```schooling-example
{"language": "python", "file": "stale_demo.py", "parts": [{"code": "import json\nimport threading\nimport time\n\nimport catalogue\nimport swrcache\n\nbook = catalogue.get_book(2)\nstale = {\"book\": dict(book, price_cents=8990), \"fresh_until\": time.time() - 60}\nswrcache.r.set(\"book:2\", json.dumps(stale), ex=3600)\ncatalogue.set_price(2, 7990)\n\nprices, slowest = set(), 0.0\nbefore = catalogue.queries\n\n\ndef visitor():\n    global slowest\n    start = time.perf_counter()\n    prices.add(swrcache.get_book(2)[\"price_cents\"])\n    slowest = max(slowest, (time.perf_counter() - start) * 1000)\n\n\nthreads = [threading.Thread(target=visitor) for _ in range(50)]\nfor t in threads:\n    t.start()\nfor t in threads:\n    t.join()\nprint(f\"50 readers: prices {sorted(prices)}, slowest {slowest:.1f} ms\")\ntime.sleep(0.3)\nprint(f\"a moment later: {swrcache.get_book(2)['price_cents']}, queries {catalogue.queries - before}\")\n", "note": "Plants a copy that went stale a minute ago, changes the price, and sends fifty readers."}]}
```

```
ana@web:~/work$ python3 stale_demo.py
50 readers: prices [8990], slowest 3.7 ms
a moment later: 7990, queries 1
```

**All fifty readers got an answer in under four milliseconds**, none of them waited for the database, and
all of them got the old price, 8,990. One of them started the refresh, and a moment later the cache held
7,990, at a cost of one query.

That last part is the price: **for a moment, everybody sees the old value**. For a price that is the
same trade lesson 10's lifetime already made; for stock that has just reached zero, it is a sale of a
book the shop no longer has. Serve stale where an old answer is an acceptable answer, and lock where it
is not.
