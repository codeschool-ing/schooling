---
title: INCLUDE: carrying columns the search does not use
version: 1
---

A **covering index** is one that holds every column a particular query needs, so the query can be
answered by an index-only scan. The columns a query uses do two different jobs, and a B-tree can
hold them in two different ways:

| job | example | where it goes in the index |
|---|---|---|
| searched or sorted on | `WHERE customer_id = …`, `ORDER BY placed_at` | **key columns**, in the parentheses |
| only returned | `status`, `total_cents` in the `SELECT` list | **`INCLUDE`**, after the key |

Key columns are what the tree is sorted by, so they are what a search can use. `INCLUDE` columns
are carried along in the entries at the bottom of the tree and in no other part of it. They cannot
be searched or sorted on; they are there to be **read**.

## The query: a customer's last ten orders

`customer-orders.sql` from lesson 2 is half of the workload's calls: a customer opens "my orders"
and sees the last ten.

```
market=# EXPLAIN (ANALYZE, BUFFERS) SELECT id, placed_at, status, total_cents FROM orders WHERE customer_id = 4242 ORDER BY placed_at DESC LIMIT 10;
                                                                 QUERY PLAN                                                                  
---------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=48.00..48.03 rows=10 width=29) (actual time=0.257..0.259 rows=10 loops=1)
   Buffers: shared hit=8 read=8
   ->  Sort  (cost=48.00..48.03 rows=11 width=29) (actual time=0.256..0.257 rows=10 loops=1)
         Sort Key: placed_at DESC
         Sort Method: quicksort  Memory: 25kB
         Buffers: shared hit=8 read=8
         ->  Bitmap Heap Scan on orders  (cost=4.51..47.81 rows=11 width=29) (actual time=0.095..0.192 rows=10 loops=1)
               Recheck Cond: (customer_id = 4242)
               Heap Blocks: exact=10
               Buffers: shared hit=5 read=8
               ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..4.51 rows=11 width=0) (actual time=0.053..0.053 rows=10 loops=1)
                     Index Cond: (customer_id = 4242)
                     Buffers: shared hit=3
 Planning:
   Buffers: shared hit=141
 Planning Time: 0.828 ms
 Execution Time: 0.318 ms
(17 rows)

Time: 2.639 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 10 -f customer-orders.sql market 2>&1 | grep -E "^(latency average|tps)"
latency average = 0.391 ms
tps = 20481.723645 (without initial connection time)
```

The plan has three steps. A `Bitmap Index Scan` on `orders_customer_id_idx` finds the customer's
ten orders, the `Bitmap Heap Scan` reads **10 table pages** to fetch their columns, and a `Sort`
puts them newest first. Sixteen pages in all, 0.32 milliseconds, and under load 0.39 milliseconds a
call at 20,482 calls a second. It is already fast; it is also the statement the application runs
most, and the ten table pages it reads per call are scattered across the table.

## An index that searches and sorts

The search is on `customer_id`, the order is `placed_at`, so those are the key columns. The query
returns `status` and `total_cents` too, so they go in `INCLUDE`:

```
market=# CREATE INDEX orders_customer_placed_idx ON orders (customer_id, placed_at) INCLUDE (status, total_cents);
CREATE INDEX
Time: 1922.594 ms (00:01.923)

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT id, placed_at, status, total_cents FROM orders WHERE customer_id = 4242 ORDER BY placed_at DESC LIMIT 10;
                                                                      QUERY PLAN                                                                      
------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.43..44.24 rows=10 width=29) (actual time=0.035..0.055 rows=10 loops=1)
   Buffers: shared hit=10 read=3
   ->  Index Scan Backward using orders_customer_placed_idx on orders  (cost=0.43..48.62 rows=11 width=29) (actual time=0.034..0.054 rows=10 loops=1)
         Index Cond: (customer_id = 4242)
         Buffers: shared hit=10 read=3
 Planning:
   Buffers: shared hit=107 read=23
 Planning Time: 1.112 ms
 Execution Time: 0.078 ms
(9 rows)

Time: 3.156 ms

market=# DROP INDEX orders_customer_placed_idx;
DROP INDEX
Time: 120.550 ms
```

The `Sort` is gone: the index hands over a customer's orders already in `placed_at` order, and
walking it **backward** gives the newest first. But the node says `Index Scan Backward`, not `Index
Only Scan`, and it still read the table. The query's `SELECT` list has **`id`**, and the index does
not. One forgotten column, and every row goes back to the heap.

## The covering index

```
market=# CREATE INDEX orders_customer_placed_idx ON orders (customer_id, placed_at) INCLUDE (id, status, total_cents);
CREATE INDEX
Time: 1813.095 ms (00:01.813)

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT id, placed_at, status, total_cents FROM orders WHERE customer_id = 4242 ORDER BY placed_at DESC LIMIT 10;
                                                                        QUERY PLAN                                                                        
----------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.43..4.24 rows=10 width=29) (actual time=0.042..0.045 rows=10 loops=1)
   Buffers: shared hit=1 read=3
   ->  Index Only Scan Backward using orders_customer_placed_idx on orders  (cost=0.43..4.62 rows=11 width=29) (actual time=0.041..0.043 rows=10 loops=1)
         Index Cond: (customer_id = 4242)
         Heap Fetches: 0
         Buffers: shared hit=1 read=3
 Planning:
   Buffers: shared hit=133 read=1
 Planning Time: 0.565 ms
 Execution Time: 0.070 ms
(10 rows)

Time: 1.388 ms
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 10 -f customer-orders.sql market 2>&1 | grep -E "^(latency average|tps)"
latency average = 0.251 ms
tps = 31855.189890 (without initial connection time)
```

**`Index Only Scan Backward`, `Heap Fetches: 0`, 4 pages.** The index carries everything: the key
finds the customer and supplies the order, and the `INCLUDE` columns supply the rest. Under load
the query went from **0.39 milliseconds to 0.25**, and from 20,482 calls a second to 31,855.

Pages are the cleaner measure: **16 to 4**, every one of them in the index, none in the table.

## Why not make them all key columns?

`CREATE INDEX … ON orders (customer_id, placed_at, id, status, total_cents)` would cover the same
query. `INCLUDE` is still the better way to write it, for three reasons:

- **the upper levels of the tree stay small.** Key columns are copied into the internal pages that
  guide a search; `INCLUDE` columns live only in the leaf entries. On a wide included column, that
  keeps the part of the tree every search walks small.
- **a `UNIQUE` index can carry extra columns without changing what is unique.** `CREATE UNIQUE
  INDEX … ON customers (email) INCLUDE (name)` keeps the email unique and still answers "name by
  email" from the index; with `name` as a key column, only the pair would be unique.
- **any type can be included**, even one with no B-tree ordering, because nothing compares
  included values.

And the reason to keep a column in the key: if a query **filters or sorts** on it, it must be a key
column, in the right position. `placed_at` had to be in the key here, second, after the equality on
`customer_id`; in `INCLUDE` the index would find the customer's rows and then need a sort.

## What it replaced

`orders_customer_id_idx` is still there, and the new index starts with the same column, so every
query the old one served, the new one can serve. Keeping both is paying twice for the same search.
Lesson 11 is about finding pairs like that and dropping one safely. Before that, the next section
measures what the new index costs.
