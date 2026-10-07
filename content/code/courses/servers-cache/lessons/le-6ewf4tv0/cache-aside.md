---
title: Cache-aside, the pattern you already wrote
version: 1
---

Lessons 8 and 9 stored values and read them back. What turns that into a cache is a rule about **who
fills it and when**, and the rule most applications use is called **cache-aside**: the application asks
the cache first, and on a miss reads the database itself and leaves a copy for the next reader. The cache
sits beside the application's path rather than in it, which is where the name comes from.

```schooling-example
{"language": "python", "file": "bookcache.py", "parts": [{"code": "import json\nimport time\n\nimport redis\n\nimport catalogue\n\n", "note": "`catalogue` is the slow database, 120 ms a query."}, {"code": "r = redis.Redis(decode_responses=True)\nTTL = 300\n\n\n", "note": "One connection and one lifetime for every copy, five minutes."}, {"code": "def get_book(book_id):\n    key = f\"book:{book_id}\"\n    cached = r.get(key)\n    if cached is not None:\n        return json.loads(cached)\n    book = catalogue.get_book(book_id)\n    r.set(key, json.dumps(book), ex=TTL)\n    return book\n\n\n", "note": "**Cache-aside.** Ask the cache; on a miss, read the database and leave a copy with a lifetime."}, {"code": "def update_price(book_id, price_cents):\n    catalogue.set_price(book_id, price_cents)\n    r.delete(f\"book:{book_id}\")\n\n\n", "note": "**A write changes the database first, then deletes the copy.** The next section says why it deletes rather than writes."}, {"code": "if __name__ == \"__main__\":\n    r.delete(\"book:2\")\n    for attempt in (1, 2, 3):\n        start = time.perf_counter()\n        book = get_book(2)\n        ms = (time.perf_counter() - start) * 1000\n        print(f\"read {attempt}: {book['price_cents']} in {ms:.1f} ms, queries {catalogue.queries}\")\n", "note": "Run as a program, it reads book 2 three times and times each read."}], "output": "read 1: 8990 in 121.1 ms, queries 1\nread 2: 8990 in 0.2 ms, queries 1\nread 3: 8990 in 0.1 ms, queries 1\n"}
```

Three reads of book 2, from a clean start:

```
ana@web:~/work$ python3 bookcache.py
read 1: 8990 in 121.1 ms, queries 1
read 2: 8990 in 0.2 ms, queries 1
read 3: 8990 in 0.1 ms, queries 1
ana@web:~/work$ redis-cli TTL book:2
300
```

**The first read paid the database's 120 milliseconds and the next two paid a tenth of a millisecond**,
with the query count still at one. The copy now has 300 seconds to live. That number is the whole of
this pattern's honesty about change: whatever the database does in the next five minutes, the cache will
not hear about it on its own.

Cache-aside has two properties worth naming. **The cache holds only what somebody asked for**, so
memory goes to the books that are actually read. And **a cache that is down costs speed, not
correctness**: if Redis stops answering, an application written this way can fall back to reading the
database every time, slower but right. Both are why it is the default, and the rest of this lesson is
about the one thing it leaves open, what happens when the data changes.
