---
title: Hashes, and when a JSON string is the better choice
version: 1
---

A product has a name, a price and a stock figure. The first instinct is to store it the way the
application already holds it, as a JSON document in one string. **A hash stores the same record as
named fields inside one key**, and the difference is which operations Redis can do for you without
the application reading the whole thing.

## A product as a hash

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> HSET product:KB-101 name "Mechanical keyboard" price_cents 34990 stock 12
(integer) 3
127.0.0.1:6379> HGETALL product:KB-101
1) "name"
2) "Mechanical keyboard"
3) "price_cents"
4) "34990"
5) "stock"
6) "12"
127.0.0.1:6379> HINCRBY product:KB-101 stock -1
(integer) 11
127.0.0.1:6379> HMGET product:KB-101 price_cents stock
1) "34990"
2) "11"
```

`HSET` wrote three fields and answered how many were new. `HINCRBY` took one keyboard off the stock
in the server, atomically, exactly like `INCR` on a counter, and `HMGET` read two fields without
transferring the third. With the JSON string, the same sale is a `GET`, a parse, a change and a `SET`,
and two sales at once are the lost update of the previous section, with a product record in place of
a page counter.

## What it costs in memory

The same product, both ways:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> SET product:KB-101:json '{"name":"Mechanical keyboard","price_cents":34990,"stock":12}'
OK
127.0.0.1:6379> MEMORY USAGE product:KB-101
(integer) 120
127.0.0.1:6379> MEMORY USAGE product:KB-101:json
(integer) 144
127.0.0.1:6379> OBJECT ENCODING product:KB-101
"listpack"
```

**The hash is 120 bytes and the JSON string 144**, because the hash does not store the braces, the
quotes and the colons. The saving comes from the encoding: a small hash is stored as a `listpack`, one
compact block of memory with the fields laid end to end. Redis keeps it that way while the hash stays
small, and converts it to a real hash table, faster to search and much larger, the moment it is not:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> CONFIG GET hash-max-listpack-*
1) "hash-max-listpack-value"
2) "64"
3) "hash-max-listpack-entries"
4) "512"
127.0.0.1:6379> HSET product:KB-101 description "Full-size mechanical keyboard with brown switches, ABNT2 layout and a detachable USB-C cable"
(integer) 1
127.0.0.1:6379> OBJECT ENCODING product:KB-101
"hashtable"
127.0.0.1:6379> MEMORY USAGE product:KB-101
(integer) 424
```

The two limits are `hash-max-listpack-entries`, 512 fields, and `hash-max-listpack-value`, 64 bytes.
**One description longer than 64 bytes turned the product into a `hashtable`, and its size went from
120 bytes to 424**, much more than the 92 characters that were added. On one key it is nothing. On a
million products, each pushed over the limit by one long field, it is the difference between a
machine that fits the catalogue and one that does not. Long text that is only ever displayed is often
better in a key of its own, beside the hash.

## Which one to choose

The choice follows the access pattern, which is the argument of lesson 3 applied to one key:

| | a hash wins | a JSON string wins |
| --- | --- | --- |
| how it is read | one or two fields at a time: the price on a listing, the stock on a basket | always whole, by code that parses it anyway |
| how it is written | one field changes on its own: stock goes down, a price is corrected | the whole value is replaced at once |
| its shape | flat: a field holds a string or a number | nested: lists inside objects, which a hash cannot hold |
| counters inside it | `HINCRBY` on a field, atomic | read, parse, add, write, and a race |
| what it is | the system's own record, changed in place | a copy of something else, such as an API response cached for a minute |

**A cached copy of another system's answer belongs in a string**: nobody updates one field of a
cached response, and the string is exactly what the application will send on. **A record that the
shop changes a field at a time belongs in a hash.** The shop's product, with its stock going down
one sale at a time, is the second kind.
