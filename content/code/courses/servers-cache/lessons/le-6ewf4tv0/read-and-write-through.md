---
title: Read-through and write-through
version: 1
---

In cache-aside the application does the cache's work: it checks, it loads, it stores. **Read-through**
moves that work into one place, a cache layer the application calls instead of the database. **Write-through** does the same for writes: every write goes through the layer, which writes the
database and then the cache.

```schooling-example
{"language": "python", "file": "through.py", "parts": [{"code": "import json\n\nimport redis\n\nimport catalogue\n\n\nclass BookCache:\n    \"\"\"Read-through and write-through: the application talks only to this.\"\"\"\n\n    def __init__(self, client, ttl=300):\n        self.r, self.ttl = client, ttl\n\n    def get(self, book_id):\n        cached = self.r.get(f\"book:{book_id}\")\n        if cached is not None:\n            return json.loads(cached)\n        book = catalogue.get_book(book_id)\n        self.r.set(f\"book:{book_id}\", json.dumps(book), ex=self.ttl)\n        return book\n\n    def set_price(self, book_id, price_cents):\n        catalogue.set_price(book_id, price_cents)\n        book = catalogue.get_book(book_id)\n        self.r.set(f\"book:{book_id}\", json.dumps(book), ex=self.ttl)\n\n\nbooks = BookCache(redis.Redis(decode_responses=True))\nbooks.r.delete(\"book:2\")\nbooks.set_price(2, 5990)\nprint(\"after the write: ttl\", books.r.ttl(\"book:2\"), \"queries\", catalogue.queries)\nprint(\"read:\", books.get(2)[\"price_cents\"], \"queries\", catalogue.queries)\n", "note": "A cache layer that loads on a miss and writes through on a change."}]}
```

```
ana@web:~/work$ python3 through.py
after the write: ttl 300 queries 1
read: 5990 queries 1
```

**The write left a fresh copy behind, so the first read after it was a hit.** That is what
write-through buys: no miss after a change. What it costs is a database read on every write, here
the one query counted, and a cache full of values written but perhaps never read.

The `get` method is cache-aside, line for line. **Read-through is the same logic in a different place**,
and the place is the point: one class that every part of the application goes through can be fixed once,
measured once and swapped once. Nginx and Varnish, in lessons 5 to 7, were read-through caches of
their own: on a miss they fetched from the origin themselves. Redis and Memcached only store what they
are given.

Write-through also brings back the problem of the last section but one: `set_price` ends with a `set`,
so two writers through two copies of the application can still leave the older price in the cache.
**Write-through is safe with one writer at a time**, or with a lock around the write, which lesson 11
builds.
