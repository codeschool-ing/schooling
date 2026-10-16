---
title: The scan that never reads the table
version: 1
---

An ordinary index scan does two things for every row it returns. It finds the entry in the index,
and then it follows the entry's pointer to the table, the **heap**, to read the row. Lesson 4 showed
what that second step costs when the rows are scattered: one page read per row, in no useful order.
An **index-only scan** skips the second step. If the index already holds every column the query
needs, the answer can come from the index alone.

The wrong picture to drop first is that an index-only scan is a special kind of index. It is not.
Any B-tree can do one; what decides it is the **query**, and whether all the columns it touches
are in the index.

## One index, two queries

`orders_placed_at_idx` holds `placed_at` and nothing else. Ask it two questions about December
2025:

```
market=# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE placed_at >= '2025-12-01';
                                                                      QUERY PLAN                                                                      
------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=3290.29..3290.30 rows=1 width=8) (actual time=19.599..19.600 rows=1 loops=1)
   Buffers: shared hit=1 read=298
   ->  Index Only Scan using orders_placed_at_idx on orders  (cost=0.43..3025.05 rows=106093 width=0) (actual time=0.078..14.296 rows=107780 loops=1)
         Index Cond: (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone)
         Heap Fetches: 0
         Buffers: shared hit=1 read=298
 Planning:
   Buffers: shared hit=110 read=6
 Planning Time: 0.816 ms
 Execution Time: 19.696 ms
(10 rows)

Time: 21.948 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT sum(total_cents) FROM orders WHERE placed_at >= '2025-12-01';
                                                                   QUERY PLAN                                                                    
-------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=4178.29..4178.30 rows=1 width=8) (actual time=50.919..50.921 rows=1 loops=1)
   Buffers: shared hit=1197
   ->  Index Scan using orders_placed_at_idx on orders  (cost=0.43..3913.06 rows=106093 width=4) (actual time=0.046..34.855 rows=107780 loops=1)
         Index Cond: (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone)
         Buffers: shared hit=1197
 Planning:
   Buffers: shared hit=6
 Planning Time: 0.129 ms
 Execution Time: 50.960 ms
(9 rows)

Time: 51.932 ms
```

Both queries filter on `placed_at` and both read the same 107,780 orders, and the plans differ.

- **`count(*)`** needs no column at all, only the number of rows that pass the condition, so the
  index has everything. The plan is an `Index Only Scan`, `Heap Fetches: 0`, and **299 pages** read
  in all, the index's own pages for that stretch of dates.
- **`sum(total_cents)`** needs `total_cents`, which is not in the index. The plan is an ordinary
  `Index Scan`, and it touched **1197 pages**: the same index pages, plus the table's. It took 51
  milliseconds against 20.

The `Buffers` lines are lesson 3's: `hit` counts pages found in memory and `read` pages fetched from
outside it. The first query read from outside because it ran first, on a cold cache; what matters
here is the total, which counts pages either way.

## The two lines to read

Two lines in a plan say whether an index-only scan is really one:

- **the node's name**, `Index Only Scan` rather than `Index Scan`. The planner chooses it only when
  every column the query uses, in the `SELECT` list, the `WHERE`, the `ORDER BY` and anywhere else,
  is stored in the index.
- **`Heap Fetches`**, the number of rows for which the scan had to go to the table after all. The
  name promises zero; the number says what happened.

The second line is the one people skip, and it is the subject of the next section. An index-only
scan with a large `Heap Fetches` is an ordinary index scan wearing the other name, and lesson 3's
`BUFFERS` will show it reading as many pages as one.

## Why the table is needed at all

If every column is in the index, why would the scan ever go to the table? Because the index does
not know **whether a row is visible** to your transaction. PostgreSQL keeps old and new versions of
rows side by side, and which version a transaction may see is written in the row's header in the
table, not in the index. An index entry can point at a row that was deleted a second ago, or
inserted by a transaction that has not committed. Lesson 15 is about those versions and what they
cost; here the point is narrower. Before answering from the index, the scan must know that the row
behind the entry is visible, and the cheap way to know is a map the table keeps of pages where every
row is visible to everybody. That map, and what wipes it, is section 03.
