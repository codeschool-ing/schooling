---
title: The TTL, which is a promise about staleness
version: 1
---

Every value in the cache was true when it was stored. The **TTL**, time to live, is how long it is
allowed to go on being served after that, whether it is still true or not. It is usually chosen as
a performance knob, "long enough to get a good hit rate", and that is the wrong way round. **A TTL
is the longest a user may see something that is no longer so**, and it should be chosen by asking
how old an answer the screen can afford to show.

## Watching the window

Throw away seller 7's cached dashboard, read it, place an order for seller 7, and read it again:

```
ana@vm:~$ redis-cli DEL dashboard:7
1
ana@vm:~$ python3 dashboard.py 7
seller 7: 91 orders since 2025-12-01, from the database; expires in 60 s
ana@vm:~$ psql market -c "INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents) VALUES (42, 7, now(), 'pending', 1990)"
INSERT 0 1
Time: 6.971 ms
ana@vm:~$ python3 dashboard.py 7
seller 7: 91 orders since 2025-12-01, from the cache; expires in 60 s
```

The first read went to the database and stored **91** orders for sixty seconds. The new order
committed. The second read came from the cache and said 91 again: correct a moment ago, wrong now,
and nothing in the output says so. Ask Redis how long the value has left, and the database what it
holds:

```
ana@vm:~$ redis-cli TTL dashboard:7
60
ana@vm:~$ psql market -c "SELECT count(*) FROM orders WHERE seller_id = 7 AND placed_at >= '2025-12-01'"
 count 
-------
    92
(1 row)

Time: 6.418 ms
```

`TTL` answers in seconds, **60**, because the value was stored less than a second earlier. The
database says **92**. For the next minute every dashboard request for seller 7 is served the 91,
quickly. A minute later the key has expired, the next read misses, and the dashboard catches up:

```
ana@vm:~$ python3 dashboard.py 7
seller 7: 92 orders since 2025-12-01, from the database; expires in 60 s
```

Nothing went wrong in this sequence. The cache did exactly what cache-aside promises, and the
promise includes this minute. The order was placed at the start of the TTL, which is the worst case. A value stored just before a change is wrong for the whole TTL, one stored just after is
never wrong, and on average a change stays invisible for half of it.

## Choosing it

Ask of each key how stale the screen can be, and in front of whom:

| what is cached | how stale can it be | a TTL that fits |
|---|---|---|
| a product's description and photos | hours: they change when a seller edits them | an hour, with invalidation on edit |
| a seller's dashboard | a minute: the seller refreshes to see new orders | 30 to 60 seconds |
| the operations screen's count | seconds: people act on it | a few seconds, or no cache |
| a customer's own order list, after they order | none: they just placed it | do not serve it from a cache that old |

The last row is lesson 20's read-your-own-write again, and it has the same answers: read from the
source for that user for a while, or invalidate the key when the user writes, which is the next
section.

## A TTL is the safety net, not the mechanism

A long TTL on its own is a cache that is often wrong. A short one is a cache that misses often, and
at two seconds the dashboard's hit rate would collapse. Production systems combine the two:
**invalidation** removes a key the moment its data changes, and a TTL bounds how long a value can
survive if an invalidation is ever lost. Lost is not hypothetical. The program that changes the data
may crash between the commit and the delete, a deploy may forget to delete a new key, or Redis may
be unreachable for the second that mattered. Without a TTL, any of those is a wrong value served
until somebody notices. With one, it is wrong for a minute.

Two cheap refinements are worth knowing. **Jitter**: add a few random seconds to each TTL, so that
keys stored together do not all expire together; section 05 is why. And Redis can be given a
**memory limit with an eviction policy**, `maxmemory` with `allkeys-lru`, so that a cache which grows
past its machine throws away the least recently used keys instead of refusing writes. Neither changes
the promise above: the TTL is still how old an answer you have agreed to serve.
