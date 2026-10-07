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

```python
import json
import threading
import time

import redis

import catalogue

r = redis.Redis(decode_responses=True)
FRESH, STALE = 300, 3600
REFRESH_MS = 2000


def load(book_id):
    book = catalogue.get_book(book_id)
    entry = {"book": book, "fresh_until": time.time() + FRESH}
    r.set(f"book:{book_id}", json.dumps(entry), ex=FRESH + STALE)
    return book


def get_book(book_id):
    cached = r.get(f"book:{book_id}")
    if cached is None:
        return load(book_id)
    entry = json.loads(cached)
    if entry["fresh_until"] < time.time():
        if r.set(f"refresh:book:{book_id}", 1, nx=True, px=REFRESH_MS):
            threading.Thread(target=load, args=(book_id,)).start()
    return entry["book"]
```

The refresh flag is a lock with nobody to release it: **it simply expires after two seconds**, which also
limits refreshes of one book to one every two seconds even if a refresh fails.

To see it, this program plants a copy that went stale a minute ago, holding the old price, then changes
the price in the database and sends fifty readers:

```python
import json
import threading
import time

import catalogue
import swrcache

book = catalogue.get_book(2)
stale = {"book": dict(book, price_cents=8990), "fresh_until": time.time() - 60}
swrcache.r.set("book:2", json.dumps(stale), ex=3600)
catalogue.set_price(2, 7990)

prices, slowest = set(), 0.0
before = catalogue.queries


def visitor():
    global slowest
    start = time.perf_counter()
    prices.add(swrcache.get_book(2)["price_cents"])
    slowest = max(slowest, (time.perf_counter() - start) * 1000)


threads = [threading.Thread(target=visitor) for _ in range(50)]
for t in threads:
    t.start()
for t in threads:
    t.join()
print(f"50 readers: prices {sorted(prices)}, slowest {slowest:.1f} ms")
time.sleep(0.3)
print(f"a moment later: {swrcache.get_book(2)['price_cents']}, queries {catalogue.queries - before}")
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
