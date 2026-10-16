---
title: Hash: equality and nothing else
version: 1
---

A hash index is the B-tree with the order taken away. It runs each value through a hash function
and files the row under the resulting number, so it can answer exactly one question, **is this
column equal to this value?**, and nothing about less, greater, ranges, prefixes or order. In
exchange it stores a fixed-size hash code instead of the value itself, which makes it smaller
when the values are long.

It also carries an old reputation that is no longer true. Before PostgreSQL 10, hash indexes were
not written to the write-ahead log, so they were not crash-safe and were not copied to replicas,
and the documentation told people not to use them. Since version 10 they are **as safe as any other
index**. What is left is a narrow tool, and this section measures how narrow.

## The same column, three ways

`customers.email` already has a B-tree, the one behind `UNIQUE`. Section 02 added a second one
with `text_pattern_ops` for prefix searches. Add a hash index beside them and compare sizes:

```
market=# CREATE INDEX customers_email_hash_idx ON customers USING hash (email);
CREATE INDEX
Time: 476.519 ms

market=# SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('customers_email_key', 'customers_email_pattern_idx', 'customers_email_hash_idx');
           relname           |  size   
-----------------------------+---------
 customers_email_key         | 14 MB
 customers_email_pattern_idx | 7960 kB
 customers_email_hash_idx    | 6568 kB
(3 rows)

Time: 1.493 ms
```

**14 MB for the B-tree of the constraint, 6568 kB for the hash**, a little under half. The
addresses here are about twenty characters long, `user123456@example.com`, and the hash keeps a four-byte
code for each where the B-tree keeps all twenty. The pattern index comes out at 7960 kB, smaller
than the first B-tree although it holds the same values. The two were built differently: the
constraint's index was created with the empty table and grew one insert at a time, splitting pages
as it went, and the pattern index was built in one pass over the finished table, its pages packed
full.

## What the planner does with it

```
market=# EXPLAIN SELECT * FROM customers WHERE email = 'user42@example.com';
                                        QUERY PLAN                                         
-------------------------------------------------------------------------------------------
 Index Scan using customers_email_hash_idx on customers  (cost=0.00..8.02 rows=1 width=59)
   Index Cond: (email = 'user42@example.com'::text)
(2 rows)

Time: 1.202 ms

market=# EXPLAIN SELECT * FROM customers WHERE email > 'user99990';
                                      QUERY PLAN                                      
--------------------------------------------------------------------------------------
 Bitmap Heap Scan on customers  (cost=77.95..2334.22 rows=1746 width=59)
   Recheck Cond: (email > 'user99990'::text)
   ->  Bitmap Index Scan on customers_email_key  (cost=0.00..77.52 rows=1746 width=0)
         Index Cond: (email > 'user99990'::text)
(4 rows)

Time: 4.390 ms

market=# DROP INDEX customers_email_hash_idx;
DROP INDEX
Time: 4.030 ms

market=# DROP INDEX customers_email_pattern_idx;
DROP INDEX
Time: 16.947 ms
```

For equality the planner picks the hash index, the cheapest of the three to read. For `>`, a
range, it goes to the B-tree of the constraint, because a hash cannot even be asked. **The hash
index is invisible to every query that is not `=`.**

## When it is worth it

**Hardly ever as a replacement**, and that is the honest summary. The cases where a hash index earns
its place are narrow:

- **long values compared only for equality**: a URL, a token, a content digest, a long natural
  key that is looked up and never sorted or searched by prefix. The longer the value, the bigger
  the saving, since the hash stays four bytes.
- **a column you would never range-scan anyway**, where the B-tree's order buys nothing.

And the reasons to leave it alone:

- **it cannot enforce `UNIQUE`.** The constraint on `customers.email` needs its B-tree whatever
  else exists, so a hash index on that column is an extra index, not a cheaper one.
- **it cannot serve `ORDER BY`, a range or a prefix**, and the next requirement on a column is
  usually one of those.
- **it is one more index to keep up to date** on every insert and update, which lesson 11 puts a
  price on.

`customers.email` is a column where it does not pay: the B-tree has to stay, and the hash would be
a third index on one column. The two extra indexes come off again at the end of the block above,
and the tag search, the one lesson 2 put at the top of the tally, is next.
