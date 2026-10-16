---
title: The hash join, and the memory it needs
version: 1
---

A hash join works in two phases. First it reads one input whole — the **build** side, the child
under the `Hash` node — and puts every row into a hash table in memory, keyed on the join column.
Then it reads the other input — the **probe** side — once, and looks each row's key up in the hash
table. Each lookup takes about the same time however big the table, and no index is involved at
all.

That makes it the join for **two large inputs**, or a large one against a medium one: the cost is
one pass over each side, not one lookup per row. Its price is memory, and the plan says exactly how
much.

## Orders per state

Every order joined to its customer, counted by state. Each statement in this section was run once
before the one printed, so the timings are warm:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.498 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT c.state, count(*) FROM orders AS o JOIN customers AS c ON c.id = o.customer_id GROUP BY c.state;
                                                             QUERY PLAN                                                              
-------------------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=75890.11..75890.20 rows=9 width=11) (actual time=1331.942..1331.949 rows=9 loops=1)
   Group Key: c.state
   Batches: 1  Memory Usage: 24kB
   Buffers: shared hit=4531 read=14419, temp read=3262 written=3262
   ->  Hash Join  (cost=7565.00..65890.11 rows=2000000 width=3) (actual time=55.542..1082.460 rows=2000000 loops=1)
         Hash Cond: (o.customer_id = c.id)
         Buffers: shared hit=4531 read=14419, temp read=3262 written=3262
         ->  Seq Scan on orders o  (cost=0.00..36667.00 rows=2000000 width=4) (actual time=0.068..187.424 rows=2000000 loops=1)
               Buffers: shared hit=2248 read=14419
         ->  Hash  (cost=4283.00..4283.00 rows=200000 width=7) (actual time=54.364..54.367 rows=200000 loops=1)
               Buckets: 262144  Batches: 2  Memory Usage: 5966kB
               Buffers: shared hit=2283, temp written=340
               ->  Seq Scan on customers c  (cost=0.00..4283.00 rows=200000 width=7) (actual time=0.014..20.245 rows=200000 loops=1)
                     Buffers: shared hit=2283
 Planning:
   Buffers: shared hit=16
 Planning Time: 0.274 ms
 Execution Time: 1332.031 ms
(18 rows)

Time: 1337.217 ms (00:01.337)
```

The `Hash` node built a table from `customers`, all 200000 of them; the `Seq Scan on orders` above
it streamed two million orders past it, and each found its customer by `Hash Cond: (o.customer_id =
c.id)`. **The planner hashed the smaller side**: 200000 customers rather than two million orders.
That is the first thing to check in any hash join, and it is decided by the row estimates of the two
children. A hash join that builds on the side the planner thought was small, and was not, is
lesson 6's subject.

Now the line under `Hash`:

```
Buckets: 262144  Batches: 2  Memory Usage: 5966kB
```

`Buckets` is the size of the hash table. **`Batches: 2` means the table did not fit in the memory
the join was allowed.** So the build side was split into two parts, one kept in memory and one
written to a temporary file, and the probe side was split the same way. Every probe row whose
partner is in the second part is written to disk and read back later. The `temp read=3262
written=3262` on the `Hash Join` line is that traffic: 3262 pages of 8 kB, about 25 MB, written
and read again.

The memory allowed is `work_mem` times `hash_mem_multiplier`: 4 MB times 2 by default. The
customers' table needed a little more than that, so it went to two batches.

## Changing the memory

The same join with `work_mem` at 1 MB and then at 32 MB, both for the session only:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.484 ms

market=# SET work_mem = '1MB';
SET
Time: 0.392 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT c.state, count(*) FROM orders AS o JOIN customers AS c ON c.id = o.customer_id GROUP BY c.state;
                                                             QUERY PLAN                                                              
-------------------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=75890.11..75890.20 rows=9 width=11) (actual time=942.778..942.786 rows=9 loops=1)
   Group Key: c.state
   Batches: 1  Memory Usage: 24kB
   Buffers: shared hit=4595 read=14355, temp read=5729 written=5729
   ->  Hash Join  (cost=7565.00..65890.11 rows=2000000 width=3) (actual time=44.818..712.901 rows=2000000 loops=1)
         Hash Cond: (o.customer_id = c.id)
         Buffers: shared hit=4595 read=14355, temp read=5729 written=5729
         ->  Seq Scan on orders o  (cost=0.00..36667.00 rows=2000000 width=4) (actual time=0.075..171.397 rows=2000000 loops=1)
               Buffers: shared hit=2312 read=14355
         ->  Hash  (cost=4283.00..4283.00 rows=200000 width=7) (actual time=43.786..43.789 rows=200000 loops=1)
               Buckets: 65536  Batches: 8  Memory Usage: 1491kB
               Buffers: shared hit=2283, temp written=594
               ->  Seq Scan on customers c  (cost=0.00..4283.00 rows=200000 width=7) (actual time=0.008..18.495 rows=200000 loops=1)
                     Buffers: shared hit=2283
 Planning:
   Buffers: shared hit=16
 Planning Time: 0.282 ms
 Execution Time: 942.935 ms
(18 rows)

Time: 943.912 ms

market=# SET work_mem = '32MB';
SET
Time: 0.350 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT c.state, count(*) FROM orders AS o JOIN customers AS c ON c.id = o.customer_id GROUP BY c.state;
                                                             QUERY PLAN                                                              
-------------------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=58700.11..58700.20 rows=9 width=11) (actual time=1401.331..1401.340 rows=9 loops=1)
   Group Key: c.state
   Batches: 1  Memory Usage: 24kB
   Buffers: shared hit=4659 read=14291
   ->  Hash Join  (cost=6783.00..48700.11 rows=2000000 width=3) (actual time=65.163..1157.497 rows=2000000 loops=1)
         Hash Cond: (o.customer_id = c.id)
         Buffers: shared hit=4659 read=14291
         ->  Seq Scan on orders o  (cost=0.00..36667.00 rows=2000000 width=4) (actual time=0.079..157.691 rows=2000000 loops=1)
               Buffers: shared hit=2376 read=14291
         ->  Hash  (cost=4283.00..4283.00 rows=200000 width=7) (actual time=63.939..63.943 rows=200000 loops=1)
               Buckets: 262144  Batches: 1  Memory Usage: 9861kB
               Buffers: shared hit=2283
               ->  Seq Scan on customers c  (cost=0.00..4283.00 rows=200000 width=7) (actual time=0.017..23.579 rows=200000 loops=1)
                     Buffers: shared hit=2283
 Planning:
   Buffers: shared hit=16
 Planning Time: 0.262 ms
 Execution Time: 1401.457 ms
(18 rows)

Time: 1403.509 ms (00:01.404)

market=# RESET work_mem;
RESET
Time: 0.405 ms

market=# SHOW hash_mem_multiplier;
 hash_mem_multiplier 
---------------------
 2
(1 row)

Time: 0.441 ms
```

With 1 MB the hash went to **8 batches** and the temporary traffic grew to 5729 pages. With 32 MB it
fitted in **1 batch, 9861 kB**, and the `temp` line disappeared. The planner's cost followed: the
estimate for the whole query fell from `75890.11` to `58700.11` when the batching went away.

The timings did not follow. 943 milliseconds with eight batches, 1332 with two, 1401 with one: the
one that wrote nothing to disk was the slowest of the three. The temporary files were small enough
for the operating system to keep in memory, so writing them cost little, and the time went on what
all three did alike, two million probes and two million rows counted. A likely reason the smaller
batches did better is that a 1.5 MB hash table sits in the processor's cache and a 10 MB one does
not, but nothing on this screen proves it. **What the screen does prove is that `Batches` above 1
is a cost the planner charges for, not a verdict**: measure before you raise `work_mem` to remove
it. `db-administration` lesson 6 is the arithmetic for raising it at all, because every hash and
sort in every connection may use that much at once.

## The best case: a small build side

Revenue per seller, from every order line joined to its product:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.676 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT p.seller_id, sum(l.quantity * l.price_cents) AS revenue FROM order_lines AS l JOIN products AS p ON p.id = l.product_id GROUP BY p.seller_id ORDER BY revenue DESC LIMIT 5;
                                                                    QUERY PLAN                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=134274.56..134274.57 rows=5 width=12) (actual time=2204.021..2204.029 rows=5 loops=1)
   Buffers: shared hit=2156 read=30344
   ->  Sort  (cost=134274.56..134277.06 rows=1000 width=12) (actual time=2189.217..2189.223 rows=5 loops=1)
         Sort Key: (sum((l.quantity * l.price_cents))) DESC
         Sort Method: top-N heapsort  Memory: 25kB
         Buffers: shared hit=2156 read=30344
         ->  HashAggregate  (cost=134247.95..134257.95 rows=1000 width=12) (actual time=2188.950..2189.040 rows=1000 loops=1)
               Group Key: p.seller_id
               Batches: 1  Memory Usage: 129kB
               Buffers: shared hit=2153 read=30344
               ->  Hash Join  (cost=1774.00..96748.01 rows=4999992 width=12) (actual time=26.427..1656.072 rows=5000000 loops=1)
                     Hash Cond: (l.product_id = p.id)
                     Buffers: shared hit=2153 read=30344
                     ->  Seq Scan on order_lines l  (cost=0.00..81847.92 rows=4999992 width=12) (actual time=0.057..382.860 rows=5000000 loops=1)
                           Buffers: shared hit=2153 read=29695
                     ->  Hash  (cost=1149.00..1149.00 rows=50000 width=8) (actual time=25.931..25.933 rows=50000 loops=1)
                           Buckets: 65536  Batches: 1  Memory Usage: 2466kB
                           Buffers: shared read=649
                           ->  Seq Scan on products p  (cost=0.00..1149.00 rows=50000 width=8) (actual time=0.107..11.866 rows=50000 loops=1)
                                 Buffers: shared read=649
 Planning:
   Buffers: shared hit=147 read=10
 Planning Time: 1.527 ms
 JIT:
   Functions: 16
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 0.900 ms, Inlining 0.000 ms, Optimization 0.843 ms, Emission 14.113 ms, Total 15.857 ms
 Execution Time: 2230.844 ms
(28 rows)

Time: 2235.224 ms (00:02.235)
```

Five million order lines against fifty thousand products. The hash of the products took **2466 kB
and one batch**, built in 26 milliseconds, and then five million probes streamed past it. This is
the shape a hash join is for: a small table, held in memory once, against a large one, read once.
A nested loop would have made five million index lookups into `products`.

The five sellers come out of a `Limit` above a `Sort` above a `HashAggregate` — the aggregate also
hashes, one entry per seller, `Memory Usage: 129kB`. Hashing is not only for joins; lesson 3's
`GroupAggregate` was the sorted alternative.

## What to look for

- **which side is hashed** — it should be the smaller one, by the actual rows, not only the estimate;
- **`Batches`** — 1 means it fitted; more means temporary files, with `temp` on the `Buffers` line;
- **the probe side's `rows`** — a hash join pays a full pass over it, so if that side has a selective
  filter and an index, a nested loop may have been the better plan, and section 05 shows where that
  line falls.
