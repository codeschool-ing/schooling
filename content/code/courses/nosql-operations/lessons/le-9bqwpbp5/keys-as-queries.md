---
title: The key is the query, in Redis
version: 1
---

Redis takes the method to its end. There is no partition to name and no field to search: **the only
question Redis answers is "what is under this key", so designing for Redis is designing key names.**
Row 2 of the list, the basket, is the shop's busiest write, and the application knows one thing when
it asks: who the customer is.

## A name built from what the application knows

So the basket's key is built from that: `cart:` and the customer's e-mail. A hash holds it, one
field per product code and the quantity as the value:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> HSET cart:ana@example.com CB-012 2 MS-204 1
(integer) 2
127.0.0.1:6379> HINCRBY cart:ana@example.com CB-012 1
(integer) 3
127.0.0.1:6379> HGETALL cart:ana@example.com
1) "CB-012"
2) "3"
3) "MS-204"
4) "1"
127.0.0.1:6379> exit
```

Adding a third cable was `HINCRBY` on one field, done inside the server in one step, with no read of
the basket first. Reading the basket was `HGETALL` on a key the application assembled from the
session; nothing was searched. **That is a query, in Redis's terms**: the application writes the
question into the name, and the server only has to look it up.

The colon means nothing to Redis. It is a convention, `type:id`, that lets people read a key and
lets tools group keys by their prefix, and it is worth keeping to strictly, because the prefix is
the only structure a key space has. `cart:ana@example.com`, `order:1001` and `product:MS-204` say
what they are; `ana`, `1001` and `MS-204` would collide on the day two kinds of thing share an id.

## Finding keys by pattern, and the command not to use

Sometimes an operator does need to find keys rather than name one: every basket, say, to count them
or clean them up. A real shop's Redis is not holding one basket. Here it also holds a million session
keys, written by a one-line generator piped into `redis-cli --pipe`, which sends commands without
waiting for each answer:

```
ana@vm:~$ seq 1 1000000 | awk '{print "SET session:" $1 " x"}' | docker exec -i redis redis-cli --pipe
All data transferred. Waiting for the last reply...
Last reply received from server.
errors: 0, replies: 1000000
ana@vm:~$ docker exec redis redis-cli DBSIZE
1000001
```

There are two ways to ask for every key that starts with `cart:`:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> CONFIG RESETSTAT
OK
127.0.0.1:6379> KEYS cart:*
1) "cart:ana@example.com"
127.0.0.1:6379> SCAN 0 MATCH cart:* COUNT 1000
1) "512"
2) (empty array)
127.0.0.1:6379> exit
ana@vm:~$ docker exec redis redis-cli --scan --pattern 'cart:*' --count 1000
cart:ana@example.com
ana@vm:~$ docker exec redis redis-cli INFO commandstats | grep -E "keys|scan"
cmdstat_scan:calls=1001,usec=273243,usec_per_call=272.97,rejected_calls=0,failed_calls=0
cmdstat_keys:calls=1,usec=138837,usec_per_call=138837.00,rejected_calls=0,failed_calls=0
```

Both found the one basket. What they cost is in the last two lines, the server's own count of time
spent in each command since `CONFIG RESETSTAT`:

- **`KEYS cart:*` was one call of 138,837 microseconds**, about 139 ms, to walk all 1,000,001 keys.
  Redis runs commands one at a time, so for those 139 ms every other client waited: every basket
  update and every page that reads a session.
- **`SCAN` was 1,001 calls averaging 273 microseconds.** Each call walks a slice of the key space
  and returns a cursor to continue from; the manual call shows one, `512`, and an empty list,
  because that slice held no basket. `redis-cli --scan` follows the cursor until it comes back to `0`.

`SCAN` did more work in total, about 273 ms against 139, and that is fine. What matters to the
other clients is the **longest single pause**, and SCAN's was a few hundred microseconds between
calls that let everybody else in. A million keys is a small Redis; at a hundred million, `KEYS` stops
the server for many seconds, long enough for a health check to declare it dead.

So `KEYS` belongs on a laptop. In production it is commonly renamed or disabled in the configuration,
and every tool that needs to walk keys uses `SCAN`. Neither is a query in the sense of the rest of
this lesson: both are scans, and a design that needs one on every page view has a key missing. If the
shop needed "every basket" often, it would keep **a set of basket keys** beside them, updated with
each basket, so that the question has a key of its own. Lesson 12 has the structures for that.
