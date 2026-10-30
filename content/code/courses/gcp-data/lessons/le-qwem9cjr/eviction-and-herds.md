---
title: A full cache, and a herd at the door
version: 1
---

**A cache has a memory limit, and what it does on reaching it is a setting called the eviction
policy.** It either refuses new writes or throws old keys away to make room, and which keys it may
throw away is the rest of the setting. Getting it wrong does not look like an error in the cache.
It looks like users logged out at random, or a cache that suddenly refuses every write.

The local Redis has no limit until you give it one. Give it 2 MB, small enough to fill in a second:

```
ana@laptop:~/gcp$ redis-cli CONFIG GET maxmemory-policy
1) "maxmemory-policy"
2) "noeviction"
ana@laptop:~/gcp$ redis-cli CONFIG SET maxmemory 2mb
OK
```

**`noeviction` is Redis's own default**, and it means what it says: when memory is full, a write
fails. To fill the cache, here is a program that writes keys of 1,000 bytes each and counts the
writes Redis refuses. Save it in `~/gcp` as `fill.py`:

```python
import sys

import redis

cache = redis.Redis(host='127.0.0.1', port=6379)
first, count = int(sys.argv[1]), int(sys.argv[2])
written = refused = 0
for i in range(first, first + count):
    try:
        cache.set(f'filler:{i}', 'x' * 1000)
        written += 1
    except redis.exceptions.OutOfMemoryError:
        refused += 1
print(f'written {written}, refused {refused}')
```

```
ana@laptop:~/gcp$ python3 fill.py 1 3000
written 866, refused 2134
ana@laptop:~/gcp$ redis-cli DBSIZE
(integer) 869
ana@laptop:~/gcp$ redis-cli SET product:p-102 990
(error) OOM command not allowed when used memory > 'maxmemory'.
```

**Redis took 866 keys and refused the other 2,134**, and then refused a write that mattered, the
price of a product, with the error `redis-cli` printed. `DBSIZE` counts 869 because three keys were
there from the earlier sections. Nothing was lost, and nothing more can be written either. For a
cache that is the wrong behaviour: the program has to treat every write as one that may fail, and
the cache stops caching.

```
ana@laptop:~/gcp$ redis-cli CONFIG SET maxmemory-policy volatile-lru
OK
ana@laptop:~/gcp$ python3 fill.py 3001 1000
written 0, refused 1000
```

**`volatile-lru` evicts only keys that have a time to live**, the least recently used first. None of
the filler keys has one, so there was nothing it was allowed to evict, and all 1,000 writes were
refused exactly as under `noeviction`. That matters on Google Cloud, because **Memorystore for Redis
documents `volatile-lru` as its default policy**. A program that writes keys with no expiry into a
Memorystore instance left at its defaults meets this refusal, and the previous section's rule, a TTL
on every key, is what keeps it away. The policy is one of the Redis settings Memorystore lets you
change, and the change is one command, not run here:

```sh
gcloud redis instances update quitanda-cache --region=southamerica-east1 \
  --update-redis-config maxmemory-policy=allkeys-lru
```

```
ana@laptop:~/gcp$ redis-cli CONFIG SET maxmemory-policy allkeys-lru
OK
ana@laptop:~/gcp$ python3 fill.py 3001 3000
written 3000, refused 0
ana@laptop:~/gcp$ redis-cli DBSIZE
(integer) 830
ana@laptop:~/gcp$ redis-cli INFO stats | grep evicted_keys
evicted_keys:3039
ana@laptop:~/gcp$ redis-cli EXISTS filler:1
(integer) 0
```

**`allkeys-lru` evicts any key, least recently used first**, and every one of the 3,000 writes
succeeded. The cache stayed at its limit by throwing away 3,039 keys, and holds 830 now; `filler:1`,
one of the oldest, is gone. This is the policy for a cache that holds only copies: whatever it
forgets, the database still has. Redis finds "least recently used" by sampling a few keys at a time
rather than keeping every key in order, so the key it evicts is old but not always the oldest.

## Sessions are not copies

**A login session stored in a cache with `allkeys-lru` is a session the cache may throw away**, and
the user it belongs to is logged out in the middle of a purchase for no reason they can see. A
session has no copy in a database to fall back on; it is the original. If Quitanda keeps its
sessions in Memorystore, they go in a Standard-tier instance of their own, sized so that it never
reaches its limit, with `noeviction` so that a full cache fails loudly instead of forgetting, and
with its replica in another zone. Or they go in Firestore, where a document stays until something
deletes it and Firestore's own time-to-live policies do the expiring.

## The herd

**When a popular key expires, every request that arrives before it is rebuilt misses at once**, and
every one of them runs the same query against the database. That is the thundering herd, and it
happens at the worst moment: the busier the page, the bigger the herd. The program below sends 50
requests for one page at the same instant, once the naive way and once with a lock. A 200 ms pause
stands for a slow query, so the requests overlap the way they do on a busy site. Save it as
`~/gcp/herd.py`:

```schooling-example
{"language": "python", "file": "herd.py", "parts": [{"code": "import sys\nimport threading\nimport time\n\nimport redis\n\ncache = redis.Redis(host='127.0.0.1', port=6379, decode_responses=True)\nreads = 0\ncounting = threading.Lock()\n\n\n", "note": "One client for all the threads; the `redis` package shares its connections safely between them. `reads` counts the queries, and `counting` keeps two threads from adding to it at once."}, {"code": "def slow_query():\n    global reads\n    with counting:\n        reads += 1\n    time.sleep(0.2)\n    return 'catalogue page 1'\n\n\n", "note": "The database, as far as this program is concerned: every call is counted, and the pause of 0.2 seconds stands for a query that takes 200 ms."}, {"code": "def naive():\n    page = cache.get('page:1')\n    if page is None:\n        page = slow_query()\n        cache.set('page:1', page, ex=300)\n    return page\n\n\n", "note": "Cache-aside exactly as in the previous section. Every request that finds the key missing runs the query."}, {"code": "def with_lock():\n    while True:\n        page = cache.get('page:1')\n        if page is not None:\n            return page\n        if cache.set('lock:page:1', 'mine', nx=True, ex=10):\n            page = slow_query()\n            cache.set('page:1', page, ex=300)\n            cache.delete('lock:page:1')\n            return page\n        time.sleep(0.05)\n\n\n", "note": "**The same, with a lock in front of the query.** `nx=True` writes the lock only if nobody holds it, so one request runs the query and the rest wait 50 ms and look in the cache again."}, {"code": "fetch = with_lock if sys.argv[1:] == ['lock'] else naive\ncache.delete('page:1')\nthreads = [threading.Thread(target=fetch) for _ in range(50)]\nfor t in threads:\n    t.start()\nfor t in threads:\n    t.join()\nprint(f'{len(threads)} requests, {reads} database reads')\n", "note": "The page starts missing, as it does the second after its key expires, and 50 threads ask for it at once. `python3 herd.py` is the naive way and `python3 herd.py lock` the other."}]}
```

```
ana@laptop:~/gcp$ python3 herd.py
50 requests, 50 database reads
ana@laptop:~/gcp$ python3 herd.py lock
50 requests, 1 database reads
```

**Fifty requests made fifty database reads, and with the lock they made one.** The lock is an
ordinary Redis key written with `nx=True`, which succeeds only if the key does not exist yet, so
exactly one request wins and rebuilds the page while the other 49 wait and read the copy it leaves.
The lock's own `ex=10` is what keeps a request that dies holding it from blocking everybody for
ever.

Two smaller habits help as well. **Give keys of the same kind slightly different lives**, 300
seconds plus a random few, so that a thousand keys written by the same import do not all expire in
the same second. And for the handful of pages that are always busy, refresh the copy shortly before
it expires rather than waiting for the miss.
