---
title: When memory runs out
version: 1
---

Everything Redis holds is in memory, and memory ends. What Redis does when it ends is a setting,
`maxmemory-policy`, and choosing it is the moment Redis is told whether it is a cache or a database. To
watch both behaviours, give it two megabytes and a small program that writes one-kilobyte values until
it is stopped:

```python
import sys

import redis

r = redis.Redis()
written = 0
try:
    for i in range(int(sys.argv[1])):
        r.set(f"filler:{i}", "x" * 1000)
        written += 1
except redis.exceptions.ResponseError as e:
    print("error after", written, "keys:", e)
print("written", written)
```

```
ana@web:~/work$ redis-cli CONFIG SET maxmemory 2mb; redis-cli CONFIG GET maxmemory-policy
OK
maxmemory-policy
noeviction
ana@web:~/work$ python3 fill.py 5000
error after 401 keys: OOM command not allowed when used memory > 'maxmemory'.
written 401
```

**`noeviction` is Ubuntu's default, and it means: refuse writes.** After 401 keys, every write fails with
`OOM command not allowed`, and reads keep working. For Redis used as a database, that is right: losing
data silently would be worse than failing loudly. For a cache it is wrong, because a cache that cannot
take new entries makes the application fail for want of a copy it could have fetched again.

```
ana@web:~/work$ redis-cli CONFIG SET maxmemory-policy allkeys-lru && python3 fill.py 5000
OK
written 5000
ana@web:~/work$ redis-cli INFO stats | grep -E '^evicted_keys'; redis-cli DBSIZE; redis-cli INFO memory | grep -E '^(used_memory_human|maxmemory_human|maxmemory_policy):'
evicted_keys:4608
402
used_memory_human:2.00M
maxmemory_human:2.00M
maxmemory_policy:allkeys-lru
ana@web:~/work$ redis-cli EXISTS bestsellers book:2
0
```

With **`allkeys-lru`**, Redis makes room by evicting the keys least recently used, from all keys, and
every one of the five thousand writes succeeded. 4,608 keys were evicted to make room, memory sits at
its limit, and the bestsellers and the book hash from earlier sections are gone too, because nothing had
read them recently. That is what a cache is allowed to do and a database is not.

| policy | when memory is full | for |
|---|---|---|
| `noeviction` | refuses writes with an error | Redis as a database or a queue |
| `allkeys-lru` | evicts the least recently used key | a cache where any key may go |
| `allkeys-lfu` | evicts the least frequently used key | a cache with a stable set of popular keys |
| `volatile-lru` / `volatile-ttl` | evicts only keys that have a lifetime | one Redis holding both cache and data |

**One Redis for both cache and data is the trap in the last row.** It works only if every cache key has a
lifetime and no data key does, and the first cached value written without `ex=` is one that can never
be evicted. Two Redis instances, one per role, each with the right policy, cost a few megabytes and remove
the question.
