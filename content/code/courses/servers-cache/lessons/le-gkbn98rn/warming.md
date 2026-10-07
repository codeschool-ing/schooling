---
title: Warming a cold cache
version: 1
---

Every fix so far assumed a copy existed, or had just existed. **A cache that starts empty**, a new
server, a Memcached restart, a `FLUSHALL` by mistake, has no stale copy to serve and nothing to refresh
early. Every popular page is a stampede at once, and the database meets all of them.

**Warming** fills the cache before visitors arrive, and the important part is the word *before*:

```python
import sys
import time

import catalogue
from bookcache import get_book

start = time.perf_counter()
for book_id in map(int, sys.argv[1:]):
    get_book(book_id)
ms = (time.perf_counter() - start) * 1000
print(f"warmed {len(sys.argv) - 1} books in {ms:.0f} ms, {catalogue.queries} queries, one at a time")
```

```
ana@web:~/work$ redis-cli FLUSHALL && redis-cli DBSIZE
OK
0
ana@web:~/work$ python3 warm.py $(seq 1 12)
warmed 12 books in 1455 ms, 12 queries, one at a time
ana@web:~/work$ python3 stampede.py 50 bookcache --keep
bookcache, readers at once: 50, database queries: 0, 15 ms
```

The cache started empty. `warm.py` fetched all twelve books, **one at a time**, in about a second and a
half; then fifty readers found book 2 waiting and the database answered none of them. One at a time is
the point: twelve queries in sequence is a load the database barely notices, and the same twelve as a
stampede of real visitors is the load this lesson has been preventing.

Which pages to warm is a question the shop's own history answers:

- **The most read pages**, from the access log: lesson 1's logs already name every URL and how often it
  was asked for.
- **What a deploy is about to invalidate**, when lesson 10's version number is about to change: warm the
  next version's keys, then move the version.
- **Not everything.** Warming a million rarely read items fills memory with values nobody wants, and an
  eviction policy will throw them out again.

And where warming is not possible, **let traffic in slowly**: a new server taken into the load balancer
with a low weight, lesson 2's `weight=`, fills its cache from a trickle rather than a flood.
