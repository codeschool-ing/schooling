---
title: A cache, a database, and the instance that is both
version: 1
---

The policies are easy to tell apart on paper. The trouble starts with one Redis that holds two kinds
of key: copies the application can rebuild, such as rendered pages, and records it cannot, such as
the stock counter or the idempotency keys of lesson 12. **Every policy is wrong for one of the two
kinds**, and the most popular attempt to fit both is the one that fails in the most confusing way.

## `volatile-lru`, when nobody set a TTL

The idea behind `volatile-` is sound: give every cache key an expiry, leave the records without one,
and only the cache keys can be evicted. The load from the previous section, under `volatile-lru`:

```
ana@vm:~$ sh fill.sh volatile-lru
volatile-lru: refused 22334, evicted_keys:0, keys left 17670, products left 4 of 4
```

**22,334 writes refused and nothing evicted, under a policy whose name says it evicts.** No page
had an expiry, so no key was a candidate, and Redis fell back to refusing writes exactly as
`noeviction` would. The team that chose this policy believes it runs a cache; the application sees
`OOM` errors on a full instance that has never evicted a key. It happens the day one code path writes a cache key with a plain `SET` and no `EX`. Lesson 12
showed that an ordinary `SET` also removes the expiry of a key that had one.

The same load with every page written with a one-hour expiry:

```
ana@vm:~$ sh fill.sh volatile-lru 3600
volatile-lru (pages with TTL): refused 0, evicted_keys:25306, keys left 14586, products left 4 of 4
ana@vm:~$ sh fill.sh volatile-ttl 3600
volatile-ttl (pages with TTL): refused 0, evicted_keys:25305, keys left 14570, products left 4 of 4
```

Now the policy works as intended. Pages were evicted, nothing was refused, and **all four products
stayed, under both `volatile-lru` and `volatile-ttl`**, because a key without an expiry is never a
candidate. That is the arrangement working, and it depends on every cache write in every service,
for the life of the system, remembering its `EX`.

## The other two ways to get it wrong

```
ana@vm:~$ sh fill.sh allkeys-lru 3600
allkeys-lru (pages with TTL): refused 0, evicted_keys:25306, keys left 14570, products left 4 of 4
ana@vm:~$ sh fill.sh noeviction
noeviction: refused 22334, evicted_keys:0, keys left 17670, products left 4 of 4
```

`allkeys-lru` with the same pages: nothing refused, but the products are candidates like everything
else. They survived this run because they were read constantly; a product nobody looked at for an
hour is a record the shop has lost, silently, with no error anywhere. `noeviction` keeps every
record, and refuses 22,334 writes of cache pages that should simply have pushed out older ones.

## Two instances

The arrangement that does not depend on anybody remembering anything is two Redis servers:

| | a cache | a database |
| --- | --- | --- |
| what it holds | copies the application can rebuild from elsewhere | records that exist nowhere else |
| `maxmemory-policy` | `allkeys-lru` or `allkeys-lfu` | `noeviction` |
| when it is full | evicts, and the application rebuilds what it misses | refuses writes, and somebody is paged |
| persistence (lesson 13) | none: `--save ""`, no append-only file | snapshots and the append-only file |
| a restart | starts empty, which is fine | must come back with everything |
| `maxmemory` | the memory it may use | the memory it may use, with an alert well before it |

Two small Redis servers cost little more than one large one, since each uses only the memory it
holds. **One instance with `volatile-*` is a database that also caches**, and is safe only while
every write to it is disciplined; it is worth choosing only when a second instance is truly not
available.
