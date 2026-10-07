---
title: Hashes, lists, sets and sorted sets
version: 1
---

The other four types are what make Redis more than a cache of strings: each one answers a question in
the server that would otherwise mean reading a whole value into the application, changing it and writing
it back.

**A hash** is a small record: named fields inside one key.

```
ana@web:~$ redis-cli HSET book:2 title "Grande Sertão: Veredas" price_cents 8990 stock 4
3
ana@web:~$ redis-cli HGET book:2 price_cents; redis-cli HINCRBY book:2 stock -1; redis-cli HGETALL book:2
8990
3
title
Grande Sertão: Veredas
price_cents
8990
stock
3
```

One field can be read or changed without touching the others, and `HINCRBY` takes one copy off the stock
atomically, like `INCR` on a string. A whole book stored as JSON in a string would need a read, a
change in the application and a write, with a race in between.

**A list** keeps order, and with `LTRIM` it keeps a fixed number of the most recent items:

```
ana@web:~$ for b in 3 7 2 9 3; do redis-cli LPUSH recent:ana book:$b > /dev/null; done; redis-cli LTRIM recent:ana 0 2; redis-cli LRANGE recent:ana 0 -1
OK
book:3
book:9
book:2
```

Five views pushed on the left, `book:3` twice; trimmed to three, the list is the last three in order of
recency. "Recently viewed" on a shop's page is this, one `LPUSH` and one `LTRIM` per view.

**A set** holds members without order or duplicates, and sets can be intersected in the server:

```
ana@web:~$ redis-cli SADD tag:classic book:4 book:11 book:2; redis-cli SADD tag:sertao book:2 book:12 book:1; redis-cli SINTER tag:classic tag:sertao
3
3
book:2
```

**A sorted set** gives every member a score and keeps them ordered by it:

```
ana@web:~$ redis-cli ZINCRBY bestsellers 5 book:9; redis-cli ZINCRBY bestsellers 3 book:2; redis-cli ZINCRBY bestsellers 4 book:4; redis-cli ZINCRBY bestsellers 2 book:2
5
3
4
5
ana@web:~$ redis-cli ZREVRANGE bestsellers 0 2 WITHSCORES
book:9
5
book:2
5
book:4
4
```

`ZINCRBY` added to `book:2` twice, 3 then 2, and the ranking is computed by Redis, not by the
application. A tie at 5 is broken by name, in reverse, which is why `book:9` came first. Bestsellers, leaderboards
and "most viewed this hour" are all a sorted set.

```
ana@web:~$ redis-cli --scan --pattern "book:*"; redis-cli DBSIZE
book:2
8
```

`--scan` walks the keys in small batches without blocking the server, the safe replacement for `KEYS *`
that the first section warned about, and `DBSIZE` counts them all.

| type | holds | a typical use |
|---|---|---|
| string | bytes, or an integer | a cached JSON document, a counter, a lock |
| hash | named fields | a record whose fields change separately |
| list | an ordered sequence | recent items, a simple queue |
| set | unique members | tags, who is online |
| sorted set | members with scores | rankings, things ordered by time |
