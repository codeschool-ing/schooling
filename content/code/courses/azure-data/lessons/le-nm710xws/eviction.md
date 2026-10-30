---
title: When the cache is full
version: 1
---

**A cache is smaller than the data behind it on purpose, and the eviction policy decides what happens
when it is full.** Redis has eight, named by two choices: which keys may go, all of them or only the
*volatile* ones that carry a time to live, and how to pick among them, least recently used, least
frequently used, random or soonest to expire. The ninth answer is `noeviction`, which keeps everything
and refuses new writes.

`fill.py` sets the local Redis to 4 MB, chooses a policy, and writes 10,000 values of 1,000 bytes, with
or without a time to live, then reports how many writes were refused, how many keys are left and how
many were evicted. It uses `resp.py` from the section before:

`fill.py`:

```python
import sys

from resp import Redis

policy, with_ttl = sys.argv[1], "--ttl" in sys.argv
r = Redis()
r("FLUSHALL")
r("CONFIG", "SET", "maxmemory", "4mb")
r("CONFIG", "SET", "maxmemory-policy", policy)
r("CONFIG", "RESETSTAT")

written, refused = 0, 0
for i in range(10_000):
    args = ["SET", f"product:{i:05d}", "x" * 1000] + (["EX", 3600] if with_ttl else [])
    try:
        r(*args)
        written += 1
    except RuntimeError as e:
        refused += 1
        first = first if refused > 1 else str(e)
stats = dict(l.split(":", 1) for l in r("INFO", "stats").splitlines() if ":" in l)
print(f"{policy:12} ttl={'yes' if with_ttl else 'no ':3} written {written:5}  refused {refused:5}  "
      f"kept {r('DBSIZE'):5}  evicted {stats['evicted_keys']}")
if refused:
    print("   first refusal:", first)
```

```
ana@laptop:~/azure$ python fill.py noeviction
noeviction   ttl=no  written  2987  refused  7013  kept  2987  evicted 0
   first refusal: OOM command not allowed when used memory > 'maxmemory'.
ana@laptop:~/azure$ python fill.py allkeys-lru
allkeys-lru  ttl=no  written 10000  refused     0  kept  2955  evicted 7022
ana@laptop:~/azure$ python fill.py volatile-lru
volatile-lru ttl=no  written  2987  refused  7013  kept  2987  evicted 0
   first refusal: OOM command not allowed when used memory > 'maxmemory'.
ana@laptop:~/azure$ python fill.py volatile-lru --ttl
volatile-lru ttl=yes written 10000  refused     0  kept  2881  evicted 7096
```

**`noeviction` refused 7,013 of the 10,000 writes** with an out-of-memory error, once 2,987 values
filled the 4 MB. For a cache that is the wrong answer: a program written as cache-aside now fails to
*cache* and, if it does not catch the error, fails the request.

**`allkeys-lru` took every write and evicted 7,022 keys**, the ones read least recently, keeping 2,955.
For a cache where every key is a copy of something in Cosmos DB, this is the policy that matches the
idea: anything may go, and the database still has it.

**`volatile-lru` without a time to live behaves exactly like `noeviction`**, the same 2,987 kept and
7,013 refused, because it may only evict keys that have one and none did. With `--ttl` it evicted
7,096 and refused nothing. This is the policy the documentation gives as Azure Cache for Redis's
default, and it is a trap for a program that writes keys without a time to live: the cache fills, evicts
nothing, and refuses writes. A cache used only as a cache wants `allkeys-lru`, or every key written with
an expiry.

The exact counts change by a few keys from run to run, because Redis samples candidates rather than
searching every key; the shape does not.
