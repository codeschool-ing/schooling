---
title: Memcached from Python
version: 1
---

Python's client is `pymemcache`, packaged as `python3-pymemcache`. Memcached stores bytes and a flags
number, so **the client decides how an object becomes bytes**, and the flags are where it notes what it
did. This program caches books as JSON and refuses to read back anything it did not write:

```schooling-example
{"language": "python", "file": "memcache_books.py", "parts": [{"code": "import json\n\nfrom pymemcache.client.base import Client\n\nimport catalogue\n\n", "note": "`catalogue` is the course's slow database, from `~/work`."}, {"code": "JSON = 1\n\n\nclass JsonSerde:\n    def serialize(self, key, value):\n        return json.dumps(value).encode(), JSON\n\n    def deserialize(self, key, value, flags):\n        if flags != JSON:\n            raise ValueError(f\"{key}: flags {flags}, not JSON\")\n        return json.loads(value)\n\n\n", "note": "**A serde turns a value into bytes and a flags number, and back.** The flags record that the bytes are JSON, and reading refuses anything else rather than guess."}, {"code": "mc = Client((\"127.0.0.1\", 11211), serde=JsonSerde(), default_noreply=False)\n\n", "note": "`default_noreply=False` makes every store wait for Memcached's answer; the end of this section explains why."}, {"code": "mc.set(\"book:2\", catalogue.get_book(2), expire=60)\nprint(mc.get(\"book:2\")[\"title\"])\n\n", "note": "One slow read from the database, stored with a lifetime of sixty seconds, then read back from Memcached."}, {"code": "print(\"add again:\", mc.add(\"book:2\", {}))\n\n", "note": "`add` on a key that exists: Memcached answers `NOT_STORED`, which arrives here as `False`."}, {"code": "mc.set_many({f\"book:{i}\": catalogue.get_book(i) for i in (3, 4, 5)}, expire=60)\nfound = mc.get_many([\"book:3\", \"book:4\", \"book:99\"])\nprint(sorted(found), \"queries:\", catalogue.queries)\n", "note": "**Several keys in one round trip**, both ways. `book:99` was never stored."}], "output": "Grande Sertão: Veredas\nadd again: False\n['book:3', 'book:4'] queries: 4\n"}
```

```
ana@web:~/work$ python3 memcache_books.py
Grande Sertão: Veredas
add again: False
['book:3', 'book:4'] queries: 4
ana@web:~/work$ printf 'get book:2\r\n' | nc -q1 127.0.0.1 11211 | cut -c1-70
VALUE book:2 1 151
{"id": 2, "title": "Grande Sert\u00e3o: Veredas", "author": "Jo\u00e3o
END
```

In `VALUE book:2 1 151`, the `1` is the flags the serde chose and 151 is the length of the JSON.
`book:99` is not in the result at all, because **`get_many` returns only what it found**: a miss is a
missing dictionary key, not a `None`. `queries: 4` counts the trips to the database, one for book 2 and
three for the others.

The client was built with `default_noreply=False`, and that matters more than it looks:

```
ana@web:~/work$ python3 -c 'from pymemcache.client.base import Client; mc = Client(("127.0.0.1", 11211)); print(mc.add("book:2", b"{}"), mc.add("book:2", b"{}", noreply=False))'
True False
```

**`pymemcache` sends its stores with `noreply` unless told otherwise.** It does not wait for the answer,
so `add` returned `True` whether or not anything was stored; the same `add` waiting for the reply said
`False`. Not waiting saves a round trip per write, and it hides `NOT_STORED`, `object too large for
cache` and every other refusal along with it. For a cache that is only ever filled, that may be a fair
trade. For `add` used as a lock, or for `cas`, it is wrong every time, because the answer is the whole
point of those commands.
