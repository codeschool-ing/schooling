---
title: Keys, lifetimes and versions
version: 1
---

Everything so far deleted one key at a time, because the writer knew which key it had made stale. Some
changes have no single key: a new tax applied to every price, a change to the shape of the JSON, a
deploy that renames a field. Redis can find keys by pattern, lesson 8 showed `--scan`, but walking a
large keyspace on every deploy is slow and races with the readers that refill it.

The cheaper answer is to **put a version in every key and change the version**:

```schooling-example
{"language": "python", "file": "versions.py", "parts": [{"code": "import json\n\nimport catalogue\nfrom bookcache import r\n\nr.set(\"catalogue:version\", 1, nx=True)\n\n\ndef key(book_id):\n    return f\"v{r.get('catalogue:version')}:book:{book_id}\"\n\n\ndef get_book(book_id):\n    cached = r.get(key(book_id))\n    if cached is not None:\n        return json.loads(cached)\n    book = catalogue.get_book(book_id)\n    r.set(key(book_id), json.dumps(book), ex=300)\n    return book\n\n\ndef read_three():\n    before = catalogue.queries\n    for book_id in (1, 2, 3):\n        get_book(book_id)\n    return catalogue.queries - before\n\n\nprint(\"first pass, queries:\", read_three())\nprint(\"second pass, queries:\", read_three())\nprint(\"version is now\", r.incr(\"catalogue:version\"))\nprint(\"third pass, queries:\", read_three())\n", "note": "Every key carries the catalogue's version, and one `INCR` retires them all."}]}
```

```
ana@web:~/work$ python3 versions.py
first pass, queries: 3
second pass, queries: 0
version is now 2
third pass, queries: 3
ana@web:~/work$ redis-cli --scan --pattern 'v*:book:*' | sort
v1:book:1
v1:book:2
v1:book:3
v2:book:1
v2:book:2
v2:book:3
```

**One `INCR` made every cached book a miss**, without deleting anything: readers simply stopped asking
for the `v1:` keys. Those are still in Redis and will leave on their own when their 300 seconds run
out, which is why **a lifetime on every key** is what makes this pattern safe. Without it, every
version change would leave a full copy of the cache behind, forever, until memory ran out.

The habits for keys that this lesson has used throughout are worth stating once:

| habit | example | why |
|---|---|---|
| a prefix naming the kind of thing | `book:2`, `price:2` | readable in `--scan`, and an ACL pattern can match it |
| the id from the database, never a title | `book:2`, not `book:grande-sertao` | a title changes and the key would not |
| a version where the shape may change | `v2:book:2` | one `INCR` retires all of them |
| a lifetime on every key | `ex=300` | every mistake expires |

**And the lifetime itself is a choice about how stale is acceptable**, made per kind of value: seconds
for a stock level, minutes for a price, hours for an author's biography. A longer lifetime saves more
queries and is wrong for longer; a shorter one does the opposite. There is no right number, only the
question of what a visitor who sees an old value loses.
