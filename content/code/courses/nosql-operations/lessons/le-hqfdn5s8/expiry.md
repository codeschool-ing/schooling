---
title: Expiry, and when an expired key really leaves
version: 1
---

Eviction removes keys because memory is full. Expiry removes them because their time is up, whatever
the memory, and the two are easily confused because both delete keys nobody asked to delete. **An
expired key does not leave memory at the second it expires.** Redis removes it in one of two ways,
and until one of them happens the key still takes up memory, and `DBSIZE` still counts it.

## What `TTL` answers

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> CONFIG SET maxmemory 0
OK
127.0.0.1:6379> FLUSHALL
OK
127.0.0.1:6379> SET cart:ana KB-101 EX 600
OK
127.0.0.1:6379> TTL cart:ana
(integer) 600
127.0.0.1:6379> SET product:KB-101 34990
OK
127.0.0.1:6379> TTL product:KB-101
(integer) -1
127.0.0.1:6379> TTL cart:nobody
(integer) -2
127.0.0.1:6379> EXPIRE cart:nobody 600
(integer) 0
127.0.0.1:6379> PERSIST cart:ana
(integer) 1
127.0.0.1:6379> TTL cart:ana
(integer) -1
```

`TTL` answers the seconds left, **`-1` for a key that exists with no expiry, and `-2` for a key that
does not exist at all.** Code that treats any negative answer as "no expiry" mistakes a missing key
for a permanent one. `EXPIRE` on a missing key answers `0` and creates nothing. `PERSIST` removes an
expiry, turning a cache key back into one that lives for ever, which under a `volatile-` policy also
makes it impossible to evict.

## Lazy and active expiry

Redis removes an expired key **lazily**, when a command touches it: the key is checked, found expired,
deleted, and the command answers as if it had never been there. And it removes keys **actively**: ten
times a second it samples keys that have an expiry and deletes the expired ones it finds, repeating
while it keeps finding many. Two hundred thousand sessions, each with one second to live, show both:

```
ana@vm:~$ docker exec redis redis-cli CONFIG RESETSTAT
OK
ana@vm:~$ docker exec redis redis-cli EVAL "for i = 1, 200000 do redis.call('SET', 'session:' .. i, 'x', 'EX', 1) end return redis.call('DBSIZE')" 0
200002
ana@vm:~$ for i in 1 2 3 4 5; do sleep 0.5; echo "$(docker exec redis redis-cli DBSIZE) keys, $(docker exec redis redis-cli INFO stats | grep ^expired_keys | tr -d "\r")"; done
152398 keys, expired_keys:65924
25505 keys, expired_keys:193771
2 keys, expired_keys:200000
2 keys, expired_keys:200000
2 keys, expired_keys:200000
```

The `EVAL` wrote 200,000 keys with `EX 1`, which took a moment, so the first keys were already close
to expiring when the last were written. Half a second at a time, `DBSIZE` fell from 152,398 to 25,505 and then to the 2 keys with no
expiry, while `expired_keys` in `INFO stats` climbed to 200,000. **The second line was taken more than a
second after the `EVAL` returned**, when every session had passed its expiry, and 25,505 of them were
still counted, and still in memory, until the active cycle got to them. A `GET` on any of them in the
meantime would have answered `(nil)` and deleted it on the spot.

## Why this matters to an operator

- **Memory lags expiry.** A burst of keys that all expire at once is released over the following
  seconds, not at once, and under a tight `maxmemory` that delay can push the instance into eviction
  or `OOM` errors while most of its keys are already dead.
- **The active cycle costs processor time**, `expire_cycle_cpu_milliseconds` in `INFO stats`, and
  millions of keys expiring together take a visible slice of a single thread that also serves every
  client. Spreading expiries, adding a few random seconds to each `EX`, avoids the spike.
- **A replica does not expire keys on its own.** It waits for the primary to send the deletion, so
  that every copy agrees. A replica answers reads of an expired key as missing all the same, but its memory is released only when the primary's deletion arrives.

`expired_keys` and `evicted_keys` are two different counters for two different reasons, and lesson 20
watches both: a cache whose `evicted_keys` climbs is too small for what it holds, while
`expired_keys` climbing is expiry doing its job.
