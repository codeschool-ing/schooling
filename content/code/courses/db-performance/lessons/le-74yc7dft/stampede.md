---
title: The stampede, when a hot key goes missing
version: 1
---

A cache changes the shape of the load on a database. Without it, the load is proportional to the
traffic. With it, the load is the misses, and misses are not spread evenly: they arrive together,
**the moment a popular key expires**. The belief to correct is that a cache protects the database
from its busiest queries. It protects it between expiries, and at each expiry it can send all of
them at once.

## One key, fifty readers

Lesson 2's operations screen counts the pending orders, a sequential scan of `orders` that took 222
milliseconds a run under that lesson's workload, and everybody who has the screen open refreshes it. That is the ideal key to cache: one value, read by everyone,
changing slowly. Cached for thirty seconds, the database runs the count twice a minute instead of
several times a second.

Now follow the moment the key expires. Fifty requests arrive in the next few milliseconds. Each one
looks in the cache, finds nothing, and does what cache-aside says: runs the count. Fifty copies of the same sequential scan start together on a machine with four processors, and
each one runs far slower than it would alone, because of the other forty-nine. This is a **cache stampede**, or
thundering herd, and the program below stages it. Fifty threads wait at a barrier and are released
together into an empty key, either with plain cache-aside or with the fix described after it. Save
it as `stampede.py`:

```python
# stampede.py: fifty requests for one hot key, at the moment it is missing.
import statistics, sys, threading, time
import psycopg, redis

cache = redis.Redis()
KEY, LOCK = "pending-count", "lock:pending-count"
queries = 0
counted = threading.Lock()

def count_pending():
    global queries
    with counted:
        queries += 1
    with psycopg.connect("dbname=market") as db:
        return db.execute("SELECT count(*) FROM orders WHERE status = 'pending'").fetchone()[0]

def plain():
    value = cache.get(KEY)
    if value is None:
        value = count_pending()
        cache.set(KEY, value, ex=30)
    return int(value)

def single_flight():
    while True:
        value = cache.get(KEY)
        if value is not None:
            return int(value)
        if cache.set(LOCK, 1, nx=True, ex=10):  # only one caller gets the lock
            try:
                value = cache.get(KEY)  # filled while we were asking for the lock?
                if value is None:
                    value = count_pending()
                    cache.set(KEY, value, ex=30)
                return int(value)
            finally:
                cache.delete(LOCK)
        time.sleep(0.01)  # somebody else is computing it: wait and look again

read = single_flight if sys.argv[1:] == ["single-flight"] else plain
cache.delete(KEY, LOCK)
start, times = threading.Barrier(50), []

def request():
    start.wait()
    t = time.perf_counter()
    read()
    times.append(1000 * (time.perf_counter() - t))

threads = [threading.Thread(target=request) for _ in range(50)]
for t in threads: t.start()
for t in threads: t.join()
print(f"{read.__name__}: 50 requests, queries to the database: {queries}, "
      f"median {statistics.median(times):.0f} ms, slowest {max(times):.0f} ms")
```

Reset `pg_stat_statements` so that it counts only this, run the plain version, and ask the tally:

```
ana@vm:~$ psql -q market -c 'SELECT pg_stat_statements_reset()' > /dev/null
ana@vm:~$ python3 stampede.py
plain: 50 requests, queries to the database: 50, median 1546 ms, slowest 1712 ms
ana@vm:~$ psql market -c "SELECT calls, round(mean_exec_time) AS mean_ms FROM pg_stat_statements WHERE query LIKE '%FROM orders WHERE status%'"
 calls | mean_ms 
-------+---------
    50 |    1321
(1 row)

Time: 1.065 ms
```

**Fifty requests, fifty queries.** The median request waited **1546 milliseconds** and the slowest
**1712**, for a count that takes 55 on its own, as the next run shows, and the tally agrees from the server's side:
**50 calls**, at a mean of **1321 milliseconds** each. For a second and a half the database did
nothing but answer the same question fifty times, and every other query in the shop waited behind
it. On a real site, the slow responses make clients retry, which adds requests, which makes the
next expiry worse.

## Single flight

The fix is to let **one** request recompute the value while the others wait for it. `single_flight`
does it with a lock in Redis: `SET` with `nx=True` succeeds only if the key does not exist, so out of
fifty callers exactly one gets the lock. That one looks in the cache once more, because the value may
have arrived while it was asking for the lock, then runs the query, stores the result and releases
the lock. The other forty-nine sleep ten milliseconds and look in the cache again, where they find
the value. The lock has its own expiry, `ex=10`, so that a process which dies holding it cannot
block the key for ever.

The second look inside the lock is there because an earlier version of this program, without it,
made **two** queries in one run. One caller found the cache empty, the first lock holder stored the value and released the
lock, and the late caller then got the lock and ran the query again. A lock that is released lets the
next caller in, so the holder must check whether the work is still needed.

```
ana@vm:~$ psql -q market -c 'SELECT pg_stat_statements_reset()' > /dev/null
ana@vm:~$ python3 stampede.py single-flight
single_flight: 50 requests, queries to the database: 1, median 122 ms, slowest 130 ms
ana@vm:~$ psql market -c "SELECT calls, round(mean_exec_time) AS mean_ms FROM pg_stat_statements WHERE query LIKE '%FROM orders WHERE status%'"
 calls | mean_ms 
-------+---------
     1 |      55
(1 row)

Time: 1.720 ms
```

**Fifty requests, one query**, which the tally confirms: **1 call**, at **55 milliseconds**. The
median request now waits **122 milliseconds** and the slowest **130**: the one query, plus the
polling of the others. The database saw one count instead of fifty.

## Other ways round it

- **Refresh before expiry.** A background job recomputes hot keys every twenty seconds and stores
  them with a thirty-second TTL, so they never expire while anyone is reading. Readers never pay a
  miss; the price is a job that recomputes values nobody may be reading.
- **Serve the stale value while one request refreshes it.** Store the value with a longer TTL and a
  "fresh until" time inside it. A reader that finds it past its time serves it anyway and triggers a
  single refresh.
- **Jitter**, from section 03, for the related problem of many different keys stored at the same
  moment, after a deploy or a restart, and all expiring at the same moment as well.

A restart of Redis itself is the stampede at its largest: every key missing at once. A cache that
the site cannot live without has become part of the database's capacity, and lesson 23 counts it
that way.
