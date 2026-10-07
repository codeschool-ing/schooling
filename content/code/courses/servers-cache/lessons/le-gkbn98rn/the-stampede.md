---
title: The stampede
version: 1
---

Every pattern in lesson 10 had the same quiet assumption: **one reader misses at a time**. On a quiet
book that holds. On the shop's busiest page it fails the moment the key expires, because every request
that arrives before the first one has refilled the cache misses too, and each of them goes to the
database for the same row. That is a **cache stampede**, also called a thundering herd or a dog-pile,
and it is the failure a reader of this course is most likely to meet in production.

This program sends a number of readers at `bookcache.get_book(2)` at once, each in its own thread, after
deleting the key so that the first of them finds nothing:

```python
import importlib
import sys
import threading
import time

import catalogue

readers, module = int(sys.argv[1]), importlib.import_module(sys.argv[2])
if "--keep" not in sys.argv:
    module.r.delete("book:2")

before = catalogue.queries
start = time.perf_counter()
threads = [threading.Thread(target=module.get_book, args=(2,)) for _ in range(readers)]
for t in threads:
    t.start()
for t in threads:
    t.join()
ms = (time.perf_counter() - start) * 1000
print(f"{sys.argv[2]}, readers at once: {readers}, database queries: {catalogue.queries - before}, {ms:.0f} ms")
```

```
ana@web:~/work$ python3 stampede.py 1 bookcache
bookcache, readers at once: 1, database queries: 1, 122 ms
ana@web:~/work$ python3 stampede.py 50 bookcache
bookcache, readers at once: 50, database queries: 50, 158 ms
ana@web:~/work$ python3 stampede.py 50 bookcache --keep
bookcache, readers at once: 50, database queries: 0, 15 ms
```

**One reader cost one query. Fifty readers at once cost fifty**, all for the same row, and the whole burst
took little more than one query's time because they ran side by side. The third run kept the cached copy
and cost nothing. Nothing in `bookcache.py` is wrong; it simply has no idea that forty-nine other copies
of itself are doing the same thing at the same moment.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Two charts of database queries per tenth of a second around the moment a popular key expires. Left, without protection: nothing, then a single bar of 50 queries at the moment of expiry, then nothing. Right, with a lock: a single bar of 1 query at the same moment.\"><defs><marker id=\"fsp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">no protection</text><line x1=\"40\" y1=\"200\" x2=\"330\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><line x1=\"40\" y1=\"200\" x2=\"40\" y2=\"35\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"208\" y=\"50.0\" width=\"14\" height=\"150.0\" fill=\"var(--amber)\" stroke=\"none\" fill-opacity=\"0.8\"></rect><text x=\"215\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">50 queries</text><line x1=\"215\" y1=\"225\" x2=\"215\" y2=\"205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fsp-ah)\"></line><text x=\"215\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the key expires</text><text x=\"520\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">with a lock</text><line x1=\"380\" y1=\"200\" x2=\"670\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><line x1=\"380\" y1=\"200\" x2=\"380\" y2=\"35\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"548\" y=\"196\" width=\"14\" height=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" fill-opacity=\"0.8\"></rect><text x=\"555\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 query</text><line x1=\"555\" y1=\"225\" x2=\"555\" y2=\"205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fsp-ah)\"></line><text x=\"555\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the key expires</text></svg>", "caption": "Fifty readers arriving in the same tenth of a second. Without protection each of them asks the database; with a lock one does."}
```

The arithmetic is what makes it dangerous. A page read 500 times a second, whose database query takes
120 milliseconds, sends about 60 identical queries the instant its key expires: every request in those
120 milliseconds. If the database slows down under that load, the window widens, more requests fall into
it, and the database slows further. **A cache that was saving the database becomes the thing that knocks
it over**, on a schedule set by the lifetime of one key.

The rest of this lesson is four ways to stop it, each with a different cost: make the readers wait for
one of them, serve the old copy while one refreshes, refresh before the key expires, and keep keys from
expiring together. Then the same problems one layer up, in Nginx, and the cold start that no lifetime
can prevent.
