---
title: Invalidation, and the stale value written back
version: 1
---

The obvious fix for the stale minute is to delete the key when the data changes: the writer commits
the order, then deletes `dashboard:7`, and the next read misses and fetches the truth. This is
**invalidation**, and it is what nearly every application with a cache does. It is also the source
of the most famous line about caches, that invalidation is one of the two hard things in computing.
The belief to correct is that delete-on-write closes the window. **It narrows it, and leaves a race
that writes a stale value back after the delete.**

## The race

Three things happen, in this order, in two different processes:

1. A reader misses the cache and runs the dashboard query. The database answers with the orders as
   they are now.
2. Before the reader stores that answer, a writer places an order, commits, and deletes the key.
3. The reader, which knows nothing of the write, stores the answer it read in step 1.

The delete in step 2 removed a key that was not there yet. The value stored in step 3 was read
before the write, and it now sits in the cache, looking fresh, for a whole TTL. Nothing failed, no
error was raised, and the writer did everything right.

In production this needs the reader to be slow between its query and its `SET`, a pause of a few
milliseconds at the wrong moment, which under load happens every day. To see it on purpose, the
program below plays all three parts in one process, **in the order that loses**. The interleaving is
forced; everything else, the database, the commit and Redis, is real. Save it as `race.py` beside
`dashboard.py`, from which it borrows the connections and the query:

```python
# race.py: two readers and a writer, interleaved by hand in the order that loses.
import json, sys
import psycopg, redis
from dashboard import TTL, cache, db, from_database

SELLER, KEY, VERSION = 7, "dashboard:7", "dashboard:7:version"
guarded = len(sys.argv) > 1 and sys.argv[1] == "guarded"
count = lambda rows: sum(n for _, n, _ in rows)
cache.delete(KEY)

# A: a reader misses, and reads the database.
version_seen = cache.get(VERSION)
rows = from_database(SELLER)
print(f"A  missed, read {count(rows)} orders from the database")

# B: a writer places an order, commits, and invalidates the key.
db.execute("INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents)"
           " VALUES (42, %s, now(), 'pending', 1990)", (SELLER,))
cache.incr(VERSION)
cache.delete(KEY)
print(f"B  placed an order and deleted {KEY}")

# A: the reader finishes, and stores what it read.
if not guarded:
    cache.set(KEY, json.dumps(rows), ex=TTL)
    print(f"A  stored {count(rows)} orders, for {TTL} s")
else:
    with cache.pipeline() as p:
        p.watch(VERSION)
        if p.get(VERSION) != version_seen:
            print("A  did not store: the key was invalidated while it was reading")
        else:
            p.multi()
            p.set(KEY, json.dumps(rows), ex=TTL)
            p.execute()
            print(f"A  stored {count(rows)} orders, for {TTL} s")

# C: the next reader.
cached = cache.get(KEY)
print(f"C  cache says {count(json.loads(cached)) if cached else 'nothing'},"
      f" database says {count(from_database(SELLER))}")
```

Run it as it is, then with `guarded`:

```
ana@vm:~$ python3 race.py
A  missed, read 92 orders from the database
B  placed an order and deleted dashboard:7
A  stored 92 orders, for 60 s
C  cache says 92, database says 93
ana@vm:~$ python3 race.py guarded
A  missed, read 93 orders from the database
B  placed an order and deleted dashboard:7
A  did not store: the key was invalidated while it was reading
C  cache says nothing, database says 94
```

The first run is the race. The reader read **92**, the writer placed order 93 and deleted the key,
the reader stored its 92 anyway, and the next reader, C, was served 92 while the database said
**93**. That 92 would have been served for sixty seconds, and it would have been served even if the
writer had deleted the key a second time, a moment too early.

## Closing it

The guarded run adds a **version** for each key. The writer increments `dashboard:7:version` before
it deletes, and the reader notes the version before its query. When it comes to store its answer, it
asks Redis to `WATCH` the version, compares it with the one it noted, and stores only inside a
`MULTI`/`EXEC` transaction, which Redis refuses if the watched key changed in between. In the
guarded run the version had moved, so the reader **did not store**, and C found nothing in the cache
and went to the database for **94**. A missed store costs one extra query; a wrong store costs a TTL
of wrong answers.

Other answers to the same race, each with its own cost:

- **Delete twice**: the writer deletes, waits a little longer than a read takes, and deletes again.
  Simple, and only as good as the guess about how long a read takes.
- **Write-through**: the writer computes the new value and stores it itself. It removes the miss,
  and replaces the race with another one, between two writers storing in the wrong order.
- **A short TTL** and accepting the race. For a dashboard that is often the right call: the window
  is rare, and a minute bounds it.

## Who has to invalidate

The hard part in a real application is not the four lines in `race.py`. It is knowing **every key a
write affects**. One order changes the seller's dashboard, the customer's order list, the pending
count, a product's sales figure and any page that shows any of them. Every code path that writes
orders has to delete all of those keys, including the nightly job, the admin screen and the bulk
import somebody writes next year. Each missed one is a stale screen that no test notices, because
the test that writes and then reads usually runs before the cache has anything in it.

That cost grows with the number of things cached and the number of places that write. It is one of
the reasons section 06 looks at a cache that the database maintains itself.
