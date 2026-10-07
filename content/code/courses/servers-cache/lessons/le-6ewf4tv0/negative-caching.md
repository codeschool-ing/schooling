---
title: Caching what is not there
version: 1
---

Cache-aside stores what the database returned. When it returned nothing, a book that does not exist,
the code above stores nothing, and **every request for that book goes to the database**. A broken link,
a crawler guessing ids, or a client looping on a deleted item becomes a steady load that the cache
never absorbs.

The fix is to cache the absence, with a marker that cannot be confused with a real value and a short
lifetime of its own:

```schooling-example
{"language": "python", "file": "missing.py", "parts": [{"code": "import json\n\nimport catalogue\nfrom bookcache import r\n\nMISSING = \"missing\"\n\n\ndef get_book(book_id, negative_ttl=None):\n    key = f\"book:{book_id}\"\n    cached = r.get(key)\n    if cached == MISSING:\n        return None\n    if cached is not None:\n        return json.loads(cached)\n    book = catalogue.get_book(book_id)\n    if book is None:\n        if negative_ttl:\n            r.set(key, MISSING, ex=negative_ttl)\n        return None\n    r.set(key, json.dumps(book), ex=300)\n    return book\n\n\nfor negative_ttl in (None, 30):\n    r.delete(\"book:99\")\n    before = catalogue.queries\n    for _ in range(10):\n        get_book(99, negative_ttl)\n    print(f\"negative_ttl={negative_ttl}: 10 reads of book 99, queries: {catalogue.queries - before}\")\n", "note": "Ten reads of a book that does not exist, without a marker for its absence and then with one."}]}
```

```
ana@web:~/work$ python3 missing.py
negative_ttl=None: 10 reads of book 99, queries: 10
negative_ttl=30: 10 reads of book 99, queries: 1
ana@web:~/work$ redis-cli GET book:99; redis-cli TTL book:99
missing
30
```

**Ten reads of a book that does not exist cost ten queries without the marker and one with it.** The
marker's lifetime is shorter than a real value's, 30 seconds against 300, because the cost of being
wrong is different: a book added a minute after somebody asked for it should not stay invisible for
five. And whatever code creates book 99 deletes `book:99`, exactly as `update_price` does, so the
marker never has to wait out its lifetime.
