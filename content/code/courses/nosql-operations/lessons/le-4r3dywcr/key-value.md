---
title: A key-value store, Redis
version: 1
---

A key-value store is the shape most people assume a document store has: a name, and something
filed under it. **The server keeps the value and hands it back when asked by name, and the name is
the only way in.** Redis gives the value a type, which is more than the simplest stores do, and the
rule still holds: there is no query, only keys.

## The order as one string

Store order 1001 the way an application caching it would, as the JSON it already has:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> SET order:1001 '{"customer":"ana@example.com","lines":[{"sku":"CB-012","qty":2,"unit_price":"39.90"},{"sku":"MS-204","qty":1,"unit_price":"189.00"}],"total":"268.80"}'
OK
127.0.0.1:6379> GET order:1001
"{\"customer\":\"ana@example.com\",\"lines\":[{\"sku\":\"CB-012\",\"qty\":2,\"unit_price\":\"39.90\"},{\"sku\":\"MS-204\",\"qty\":1,\"unit_price\":\"189.00\"}],\"total\":\"268.80\"}"
127.0.0.1:6379> TYPE order:1001
string
127.0.0.1:6379> HGET order:1001 total
(error) WRONGTYPE Operation against a key holding the wrong kind of value
127.0.0.1:6379> exit
```

`SET` filed the text under `order:1001` and `GET` gave it back, with the quotes inside it escaped by
`redis-cli` so that you can see where the string ends. **To Redis this is a string of bytes**:
`TYPE` says `string`, and the server has no idea it contains JSON, a customer or a total. Asking for
the field `total` is refused with `WRONGTYPE`, because a field is something a hash has and a string
does not.

## The order as a hash

A hash is a key whose value is a set of named fields, and the server can read and write one field
without touching the others:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> DEL order:1001
(integer) 1
127.0.0.1:6379> HSET order:1001 customer ana@example.com ordered_at 2026-09-14T10:22:00-03:00 total 268.80
(integer) 3
127.0.0.1:6379> HGET order:1001 total
"268.80"
127.0.0.1:6379> HGETALL order:1001
1) "customer"
2) "ana@example.com"
3) "ordered_at"
4) "2026-09-14T10:22:00-03:00"
5) "total"
6) "268.80"
127.0.0.1:6379> HSET order:1001 lines '[{"sku":"CB-012","qty":2},{"sku":"MS-204","qty":1}]'
(integer) 1
127.0.0.1:6379> TYPE order:1001
hash
127.0.0.1:6379> exit
```

`HSET` answered `3`, the number of fields it created, and `HGET` returned one of them alone.
**A hash is one level deep.** The order lines are a list of records, and a field holds a string, so
the lines go in as JSON text inside the field `lines`, opaque again. Every value Redis returned is a
string too, `"268.80"` included: the server stores text and has no decimal type, so arithmetic on
money belongs either in the application or in integer cents, which Redis can add exactly with
`HINCRBY`.

## The question it cannot answer

Ask Redis for **every order over 500 reais** and there is no command to type. No command takes a
condition on a value. The application would have to know every order key, fetch each value, parse
it and compare the total itself, which is a full scan carried out over the network one key at a time.

So a key-value design answers other questions by **writing a second structure that already holds
the answer**: a sorted set of order ids scored by their total, for example, from which Redis returns
a range by score in one command. Lesson 12 builds that structure, and lesson 4 is about the cost of
keeping two copies of a fact in step.

What the shape buys is speed and simplicity. A `GET` by key is the cheapest thing a database can
do, and Redis does it from memory. It is why Redis so often sits in front of another database as a
cache, holding answers that something else computed, and lesson 14 is about running it that way.

Redis is the key-value store this course operates. Memcached is the older and simpler cache-only
one. Valkey started in 2024 as a fork of Redis, made when Redis changed its licence, and answers the
same commands; lesson 21 has more on why that matters to an operator.
