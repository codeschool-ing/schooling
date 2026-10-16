---
title: GiST: near, similar and overlapping
version: 1
---

A B-tree needs an order, and GIN needs a value made of parts. GiST, the Generalized Search Tree,
needs neither. It is a tree in which each entry higher up **summarises** everything below it: a
bounding box around some points, a range covering some ranges, a set of trigrams covering some
strings. A search can skip every branch whose summary rules it out. That is enough to answer
questions no sorted list can: **is it near**, **is it similar**, **does it overlap**.

Two of those fit `market`: finding product titles by a fragment or a misspelling, and refusing two
time ranges that overlap.

## Titles by fragment: `pg_trgm`

Section 02 ended with a query no B-tree can help, a pattern with a wildcard at the front. The search
box of a shop is full of them: somebody types `chair 4242` and expects to find "Wooden chair 4242".
`pg_trgm` is an extension that comes with PostgreSQL. It cuts a string into **trigrams**, every run
of three characters, and offers index support for comparing strings by the trigrams they share.

```
market=# CREATE EXTENSION pg_trgm;
CREATE EXTENSION
Time: 12.155 ms

market=# EXPLAIN ANALYZE SELECT id, title FROM products WHERE title ILIKE '%chair 4242%';
                                               QUERY PLAN                                               
--------------------------------------------------------------------------------------------------------
 Seq Scan on products  (cost=0.00..1274.00 rows=5 width=24) (actual time=41.850..50.085 rows=1 loops=1)
   Filter: (title ~~* '%chair 4242%'::text)
   Rows Removed by Filter: 49999
 Planning Time: 0.956 ms
 Execution Time: 50.131 ms
(5 rows)

Time: 51.969 ms

market=# CREATE INDEX products_title_trgm_idx ON products USING gist (title gist_trgm_ops);
CREATE INDEX
Time: 683.224 ms

market=# EXPLAIN ANALYZE SELECT id, title FROM products WHERE title ILIKE '%chair 4242%';
                                                           QUERY PLAN                                                           
--------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on products  (cost=4.32..23.06 rows=5 width=24) (actual time=1.642..1.643 rows=1 loops=1)
   Recheck Cond: (title ~~* '%chair 4242%'::text)
   Heap Blocks: exact=1
   ->  Bitmap Index Scan on products_title_trgm_idx  (cost=0.00..4.31 rows=5 width=0) (actual time=1.619..1.619 rows=1 loops=1)
         Index Cond: (title ~~* '%chair 4242%'::text)
 Planning Time: 0.307 ms
 Execution Time: 1.745 ms
(7 rows)

Time: 2.654 ms
```

**50 milliseconds to 1.7.** Without an index, `ILIKE '%chair 4242%'` checks every one of 50,000
titles. With the trigram index, the planner looks up the trigrams of `chair 4242`, finds the few
titles that contain all of them, and checks only those: one row, from one page.

`CREATE EXTENSION pg_trgm` needs nothing installed, since it is part of the `postgresql` package
from lesson 1; it adds the functions and the operator classes to the database you run it in.

## Similar, and nearest first

The second thing trigrams give is a **distance** between two strings, the `<->` operator: 0 for
identical, 1 for nothing in common. With it, a query can ask for the titles closest to what was
typed, misspellings and all:

```
market=# SELECT id, title, round((title <-> 'wodden chiar 4242')::numeric, 3) AS distance FROM products ORDER BY title <-> 'wodden chiar 4242' LIMIT 5;
  id   |       title        | distance 
-------+--------------------+----------
 42493 | Wooden chair 42493 |    0.679
 42437 | Wooden chair 42437 |    0.679
 42432 | Wooden chair 42432 |    0.679
 42404 | Wooden chair 42404 |    0.679
  4265 | Wooden chair 4265  |    0.714
(5 rows)

Time: 23.000 ms

market=# EXPLAIN SELECT id, title FROM products ORDER BY title <-> 'wodden chiar 4242' LIMIT 5;
                                              QUERY PLAN                                              
------------------------------------------------------------------------------------------------------
 Limit  (cost=0.28..0.92 rows=5 width=28)
   ->  Index Scan using products_title_trgm_idx on products  (cost=0.28..6384.28 rows=50000 width=28)
         Order By: (title <-> 'wodden chiar 4242'::text)
(3 rows)

Time: 0.641 ms
```

`wodden chiar 4242`, two typos, and the closest titles are wooden chairs whose numbers share the most characters with 4242. The second query shows how: an `Index Scan` with an **`Order By`** line, which means the index
itself hands rows over nearest first and the `Limit` stops after five. That is called a
nearest-neighbour search, and it is the thing GiST does that GIN cannot. A GIN trigram index, built
with `gin_trgm_ops`, also serves `ILIKE` and is usually faster for it, but it cannot order by
distance.

## Ranges that must not overlap

The other classic use of GiST is a constraint. Suppose sellers can mark themselves away, and a
seller must never have two absences that overlap. A `UNIQUE` constraint cannot say that: two
different ranges are not equal, they overlap. An **exclusion constraint** can. It says "no two rows
may have *this* operator true between them", and it needs an index that can answer the operator,
which for `&&`, overlaps, is GiST:

```
market=# CREATE EXTENSION btree_gist;
CREATE EXTENSION
Time: 197.678 ms

market=# CREATE TABLE seller_away (seller_id integer NOT NULL, during tstzrange NOT NULL, EXCLUDE USING gist (seller_id WITH =, during WITH &&));
CREATE TABLE
Time: 7.054 ms

market=# INSERT INTO seller_away VALUES (42, '[2025-12-20, 2026-01-05)');
INSERT 0 1
Time: 2.725 ms

market=# INSERT INTO seller_away VALUES (42, '[2026-01-02, 2026-01-10)');
ERROR:  conflicting key value violates exclusion constraint "seller_away_seller_id_during_excl"
DETAIL:  Key (seller_id, during)=(42, ["2026-01-02 00:00:00-03","2026-01-10 00:00:00-03")) conflicts with existing key (seller_id, during)=(42, ["2025-12-20 00:00:00-03","2026-01-05 00:00:00-03")).
Time: 1.486 ms

market=# INSERT INTO seller_away VALUES (43, '[2026-01-02, 2026-01-10)');
INSERT 0 1
Time: 1.272 ms
```

The constraint reads: no two rows where `seller_id` is equal **and** `during` overlaps. Seller 42's
second absence starts on 2 January, inside the first one, and the database refuses it with both
rows named in the error. Seller 43's identical range goes in, because the seller differs.

`btree_gist` is the other half of the trick. The `=` on `seller_id` is a B-tree question, and an
exclusion constraint needs one index for all its columns; this extension, also part of the
package, teaches GiST to handle the ordinary types with `=`. Without it the `CREATE TABLE` fails.

This is the sort of rule an application tries to enforce with a `SELECT` before the `INSERT`, and
gets wrong the day two requests arrive together. Lesson 14 is about races like that one between two sessions; an exclusion constraint closes this one, because the index checks every insert against every committed
and in-progress row.

None of lesson 2's workload searches titles or ranges, so GiST fixes nothing on that list. The
search box and the away calendar are the questions it is for, and `~/reset-market.sh` at the end of
the lesson removes both extensions, the index and `seller_away`.
