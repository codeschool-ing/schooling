---
title: GIN: looking inside a value
version: 1
---

Lesson 2 ran the workload and sorted the tally by total time, and the statement at the top was
`tag-search.sql`: twenty products carrying a tag, cheapest first. It is this lesson's first fix,
and it needs an index that looks **inside** a value. `tags` is a `text[]`, and the question
`tags @> ARRAY['kitchen']`, "does the array contain this element?", is about one element of a
list, which a B-tree over whole arrays cannot find.

## An inverted index

GIN stands for Generalized Inverted Index, and "inverted" is the word that matters. A B-tree maps
each row's value to the row. GIN turns that round: it breaks each value into its **elements** and
keeps, for every element, the list of rows that contain it. For `tags`, it holds eleven entries,
one per tag, each with the list of products wearing it. "Which products have `kitchen`?" becomes
one lookup and one list.

The same shape works for anything made of parts: the elements of an array, the keys and values of
a `jsonb` document, the words of a text searched with full-text search. Each kind of value has its
own GIN operator class that knows how to take it apart.

## Before: the tag search as it is

Measure the statement the way lesson 2 measured the workload, with `pgbench` running only this
file, eight clients for fifteen seconds, and keep the two summary lines:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 15 -f tag-search.sql market 2>&1 | grep -E "^(latency average|tps)"
latency average = 58.704 ms
tps = 136.276697 (without initial connection time)
market=# EXPLAIN ANALYZE SELECT id, title, price_cents FROM products WHERE tags @> ARRAY['kitchen'] ORDER BY price_cents LIMIT 20;
                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=1540.89..1540.94 rows=20 width=28) (actual time=24.522..24.526 rows=20 loops=1)
   ->  Sort  (cost=1540.89..1565.97 rows=10030 width=28) (actual time=24.521..24.522 rows=20 loops=1)
         Sort Key: price_cents
         Sort Method: top-N heapsort  Memory: 27kB
         ->  Seq Scan on products  (cost=0.00..1274.00 rows=10030 width=28) (actual time=0.043..19.675 rows=9917 loops=1)
               Filter: (tags @> '{kitchen}'::text[])
               Rows Removed by Filter: 40083
 Planning Time: 0.569 ms
 Execution Time: 24.566 ms
(9 rows)

Time: 26.837 ms
```

**58.7 milliseconds** per search under load and 24.6 for a single run with nobody else on the
server: eight clients share four processors, and each one waits its turn. The plan reads all
50,000 products, throws away 40,083 that lack the tag, and sorts the 9917 left to keep the
cheapest twenty.

## The GIN index

```
market=# CREATE INDEX products_tags_idx ON products USING gin (tags);
CREATE INDEX
Time: 67.516 ms

market=# EXPLAIN ANALYZE SELECT id, title, price_cents FROM products WHERE tags @> ARRAY['kitchen'] ORDER BY price_cents LIMIT 20;
                                                                  QUERY PLAN                                                                  
----------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=1114.82..1114.87 rows=20 width=28) (actual time=16.976..16.982 rows=20 loops=1)
   ->  Sort  (cost=1114.82..1139.90 rows=10030 width=28) (actual time=16.973..16.977 rows=20 loops=1)
         Sort Key: price_cents
         Sort Method: top-N heapsort  Memory: 27kB
         ->  Bitmap Heap Scan on products  (cost=73.55..847.93 rows=10030 width=28) (actual time=1.474..14.795 rows=9917 loops=1)
               Recheck Cond: (tags @> '{kitchen}'::text[])
               Heap Blocks: exact=649
               ->  Bitmap Index Scan on products_tags_idx  (cost=0.00..71.05 rows=10030 width=0) (actual time=1.374..1.375 rows=9917 loops=1)
                     Index Cond: (tags @> '{kitchen}'::text[])
 Planning Time: 0.630 ms
 Execution Time: 17.052 ms
(11 rows)

Time: 19.301 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 15 -f tag-search.sql market 2>&1 | grep -E "^(latency average|tps)"
latency average = 19.761 ms
tps = 404.835676 (without initial connection time)
```

The plan changed shape. A `Bitmap Index Scan` on the new index finds the 9917 products with the
tag in about a millisecond, then the table is read for those rows and sorted as before. **58.7
milliseconds became 19.8**, three times faster, and the server got through 405 searches a second
instead of 136.

That is the textbook fix and it is a real one. But look where the time went: the index part took
1.4 milliseconds, and the remaining 15 went into reading 649 pages of the table, every one of
them, and sorting ten thousand rows to keep twenty. A fifth of all products wear `kitchen`, so a
fifth of the table had to be read. GIN answered the `WHERE` well, and the `WHERE` was not the
expensive half of the question.

## The other half: `ORDER BY price_cents LIMIT 20`

Section 02 showed a B-tree serving an `ORDER BY` with a `LIMIT`: it hands over rows already in
order and stops when it has enough. Here that means walking products from the cheapest up and
keeping the ones that wear the tag until there are twenty. With one product in five wearing it,
that should take about a hundred rows.

```
market=# CREATE INDEX products_price_cents_idx ON products (price_cents);
CREATE INDEX
Time: 51.995 ms

market=# EXPLAIN ANALYZE SELECT id, title, price_cents FROM products WHERE tags @> ARRAY['kitchen'] ORDER BY price_cents LIMIT 20;
                                                                    QUERY PLAN                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.29..7.58 rows=20 width=28) (actual time=0.067..0.157 rows=20 loops=1)
   ->  Index Scan using products_price_cents_idx on products  (cost=0.29..3655.24 rows=10030 width=28) (actual time=0.066..0.155 rows=20 loops=1)
         Filter: (tags @> '{kitchen}'::text[])
         Rows Removed by Filter: 54
 Planning Time: 0.685 ms
 Execution Time: 0.185 ms
(6 rows)

Time: 2.271 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 15 -f tag-search.sql market 2>&1 | grep -E "^(latency average|tps)"
latency average = 0.706 ms
tps = 11334.248681 (without initial connection time)
```

The planner chose the new B-tree over GIN: it read **74 rows**, 20 kept and 54 removed, and
finished in 0.19 milliseconds. Under load the search went from 19.8 milliseconds to **0.7**, and
the server went from 405 searches a second to 11,334. From the start, 58.7 to 0.7 is about eighty
times.

So the index that fixed lesson 2's most expensive query was a plain B-tree, on a column the
`WHERE` clause does not mention. **The question a query asks is its whole text, not its `WHERE`**,
and here the `LIMIT` made the order the selective part.

## Where the B-tree plan breaks

It works because a tag is common. Ask for a tag nobody wears, say a typo:

```
market=# EXPLAIN ANALYZE SELECT id, title, price_cents FROM products WHERE tags @> ARRAY['kitchn'] ORDER BY price_cents LIMIT 20;
                                                                   QUERY PLAN                                                                    
-------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.29..292.69 rows=20 width=28) (actual time=41.095..41.096 rows=0 loops=1)
   ->  Index Scan using products_price_cents_idx on products  (cost=0.29..3655.24 rows=250 width=28) (actual time=41.093..41.094 rows=0 loops=1)
         Filter: (tags @> '{kitchn}'::text[])
         Rows Removed by Filter: 50000
 Planning Time: 0.722 ms
 Execution Time: 41.130 ms
(6 rows)

Time: 43.273 ms

market=# SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('products', 'products_tags_idx', 'products_price_cents_idx');
         relname          |  size   
--------------------------+---------
 products                 | 5192 kB
 products_tags_idx        | 264 kB
 products_price_cents_idx | 368 kB
(3 rows)

Time: 2.350 ms
```

**41 milliseconds and no rows**: the walk went through all 50,000 products in price order looking
for twenty that never came, slower than the sequential scan it replaced. The GIN index would have
answered "nobody" in a fraction of a millisecond, and the planner did not pick it because it
expected 250 matches, a guess for an element its statistics do not list, and at 250 the walk
looked cheap. It is lesson 7's subject again: a wrong estimate, choosing between two good indexes.

The sizes are the last line: both indexes together are 632 kB against a 5 MB table. Keeping both is
cheap, and it leaves the planner the right tool for a common tag and for a rare one. Whether it
picks well depends on its estimate, which is why the search screen should never send a tag that
does not exist.

## GIN on `jsonb`

`events.payload` holds `{"product": …, "ms": …}`, and finding the events about one product is a
containment question too:

```
market=# EXPLAIN ANALYZE SELECT count(*) FROM events WHERE payload @> '{"product": 4242}';
                                                             QUERY PLAN                                                              
-------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=92473.50..92473.51 rows=1 width=8) (actual time=990.909..995.263 rows=1 loops=1)
   ->  Gather  (cost=92473.29..92473.50 rows=2 width=8) (actual time=990.512..995.251 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate  (cost=91473.29..91473.30 rows=1 width=8) (actual time=985.942..985.943 rows=1 loops=3)
               ->  Parallel Seq Scan on events  (cost=0.00..91472.77 rows=208 width=0) (actual time=14.957..985.814 rows=32 loops=3)
                     Filter: (payload @> '{"product": 4242}'::jsonb)
                     Rows Removed by Filter: 1666635
 Planning Time: 0.664 ms
 Execution Time: 995.468 ms
(10 rows)

Time: 997.462 ms

market=# CREATE INDEX events_payload_idx ON events USING gin (payload);
CREATE INDEX
Time: 20791.065 ms (00:20.791)

market=# CREATE INDEX events_payload_path_idx ON events USING gin (payload jsonb_path_ops);
CREATE INDEX
Time: 9646.656 ms (00:09.647)

market=# SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('events', 'events_payload_idx', 'events_payload_path_idx');
         relname         |  size  
-------------------------+--------
 events                  | 511 MB
 events_payload_idx      | 55 MB
 events_payload_path_idx | 42 MB
(3 rows)

Time: 1.255 ms

market=# EXPLAIN ANALYZE SELECT count(*) FROM events WHERE payload @> '{"product": 4242}';
                                                                QUERY PLAN                                                                
------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=1892.48..1892.49 rows=1 width=8) (actual time=1.026..1.028 rows=1 loops=1)
   ->  Bitmap Heap Scan on events  (cost=19.71..1891.23 rows=500 width=0) (actual time=0.059..1.012 rows=96 loops=1)
         Recheck Cond: (payload @> '{"product": 4242}'::jsonb)
         Heap Blocks: exact=96
         ->  Bitmap Index Scan on events_payload_path_idx  (cost=0.00..19.58 rows=500 width=0) (actual time=0.029..0.029 rows=96 loops=1)
               Index Cond: (payload @> '{"product": 4242}'::jsonb)
 Planning Time: 0.385 ms
 Execution Time: 1.071 ms
(8 rows)

Time: 1.916 ms

market=# DROP INDEX events_payload_idx;
DROP INDEX
Time: 12.118 ms

market=# DROP INDEX events_payload_path_idx;
DROP INDEX
Time: 13.695 ms
```

**995 milliseconds to 1.07.** The sequential scan read five million payloads in parallel to find
96 events; the index went to them directly. The block also built the index twice with two operator
classes, and the difference is worth knowing:

- the default, `jsonb_ops`, indexes every key and every value separately: **55 MB**, 20.8 seconds
  to build. It answers `@>` and also `?`, "does this key exist?", and its relatives.
- `jsonb_path_ops` indexes each path-and-value pair as one hash: **42 MB**, 9.6 seconds. It
  answers only `@>`, and the planner preferred it here.

If the application only ever asks "does the document contain this", `jsonb_path_ops` is the smaller
and faster one. No query in lesson 2's workload reads `events`, so this one is a fix for a
report nobody has written yet; the two indexes are dropped at the end of the block.

## What GIN costs

GIN is expensive to keep up to date, because one row adds one entry per element: an event inserted
into a table with `jsonb_ops` adds two keys and two values to the index. PostgreSQL softens that
with a **pending list**, a buffer where new entries wait to be merged in bulk, which makes inserts
cheaper and searches a little slower until the merge. On `products`, which changes rarely, none of
that matters. On `events`, which takes thousands of rows a minute, it is the first thing to measure,
and lesson 11 is about that tax.
