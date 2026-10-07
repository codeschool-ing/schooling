---
title: How a join is actually done
version: 1
---

Lesson 5 said what a join means. It said nothing about how one is computed, because there was no
way to see it then. There are three algorithms, the planner picks one per join, and each has a
shape in the plan that tells you whether it was the right pick.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 242\" role=\"img\" aria-label=\"Three panels side by side. Nested Loop: three rows on the left, each with an arrow into an index lookup block on the right, labelled one lookup per row. Hash Join: a build side feeding a hash table, and a probe side with an arrow back into it, labelled in memory or it spills. Merge Join: two sorted columns of four values each, with arrows pairing them across, labelled walked once together. Under each panel, when it is the right choice and the sign in the plan that it was the wrong one.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Three ways to do the same join. The planner picks by the shape of the two inputs, not by which is faster in general.</text><rect x=\"14\" y=\"34\" width=\"224\" height=\"176\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"126\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">Nested Loop</text><text x=\"26\" y=\"188\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">good: one side small, the other indexed</text><text x=\"26\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">wrong: inner Seq Scan, or millions of loops</text><rect x=\"28\" y=\"72\" width=\"62\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"59\" y=\"82\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">row 1</text><path d=\"M94 82 L144 82\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M144 82 L137 78 L137 86 Z\" fill=\"var(--phosphor)\"></path><rect x=\"28\" y=\"98\" width=\"62\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"59\" y=\"108\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">row 2</text><path d=\"M94 108 L144 108\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M144 108 L137 104 L137 112 Z\" fill=\"var(--phosphor)\"></path><rect x=\"28\" y=\"124\" width=\"62\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"59\" y=\"134\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">row 3</text><path d=\"M94 134 L144 134\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M144 134 L137 130 L137 138 Z\" fill=\"var(--phosphor)\"></path><rect x=\"148\" y=\"72\" width=\"76\" height=\"72\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"186\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">index</text><text x=\"186\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">lookup</text><text x=\"28\" y=\"162\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one lookup per row</text><rect x=\"248\" y=\"34\" width=\"224\" height=\"176\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">Hash Join</text><text x=\"260\" y=\"188\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">good: both large, one fits in memory</text><text x=\"260\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">wrong: Batches well above 1</text><rect x=\"262\" y=\"72\" width=\"84\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"304\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">build</text><path d=\"M304 118 L304 134\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><rect x=\"262\" y=\"136\" width=\"84\" height=\"26\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"304\" y=\"149\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">hash table</text><rect x=\"374\" y=\"72\" width=\"84\" height=\"90\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"416\" y=\"100\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">probe</text><path d=\"M374 149 L348 149\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M348 149 L355 145 L355 153 Z\" fill=\"var(--phosphor)\"></path><text x=\"262\" y=\"176\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in memory, or it spills</text><rect x=\"482\" y=\"34\" width=\"224\" height=\"176\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"594\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">Merge Join</text><text x=\"494\" y=\"188\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">good: both sides already sorted</text><text x=\"494\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">wrong: a Sort under each child, at size</text><text x=\"536\" y=\"66\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">sorted</text><rect x=\"496\" y=\"76\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"536\" y=\"85\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">10</text><rect x=\"496\" y=\"98\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"536\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">17</text><rect x=\"496\" y=\"120\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"536\" y=\"129\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">24</text><rect x=\"496\" y=\"142\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"536\" y=\"151\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">31</text><text x=\"652\" y=\"66\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">sorted</text><rect x=\"612\" y=\"76\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"652\" y=\"85\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">10</text><rect x=\"612\" y=\"98\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"652\" y=\"107\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">17</text><rect x=\"612\" y=\"120\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"652\" y=\"129\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">24</text><rect x=\"612\" y=\"142\" width=\"80\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"652\" y=\"151\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">31</text><path d=\"M578 85 L608 85\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M608 85 L601 81 L601 89 Z\" fill=\"var(--phosphor)\"></path><path d=\"M578 107 L608 107\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M608 107 L601 103 L601 111 Z\" fill=\"var(--phosphor)\"></path><path d=\"M578 129 L608 129\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M608 129 L601 125 L601 133 Z\" fill=\"var(--phosphor)\"></path><path d=\"M578 151 L608 151\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M608 151 L601 147 L601 155 Z\" fill=\"var(--phosphor)\"></path><text x=\"496\" y=\"176\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">walked once, together</text><text x=\"14\" y=\"230\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Join ORDER is the other decision, and on a five-table query it is worth reading before the methods are.</text></svg>", "caption": "The node name is a description of the shape of the inputs. Reading it that way turns \"why a nested loop here\" into a question about the row counts underneath it."}
```

## Nested Loop: for each row on one side, look up the other

```
shop=# EXPLAIN ANALYZE SELECT c.name, o.id, o.total FROM customers c JOIN orders o ON o.customer_id = c.id WHERE c.email = 'user42@example.com';
                                                               QUERY PLAN                                                               
----------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=4.93..55.93 rows=10 width=23) (actual time=0.057..0.066 rows=7 loops=1)
   ->  Index Scan using customers_email_key on customers c  (cost=0.42..8.44 rows=1 width=17) (actual time=0.037..0.037 rows=1 loops=1)
         Index Cond: (email = 'user42@example.com'::text)
   ->  Bitmap Heap Scan on orders o  (cost=4.51..47.38 rows=11 width=14) (actual time=0.017..0.024 rows=7 loops=1)
         Recheck Cond: (c.id = customer_id)
         Heap Blocks: exact=7
         ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..4.51 rows=11 width=0) (actual time=0.012..0.012 rows=7 loops=1)
               Index Cond: (customer_id = c.id)
 Planning Time: 0.858 ms
 Execution Time: 0.134 ms
(10 rows)
```

The outer child runs once and finds one customer. For each row it produces — one — the inner child
runs and finds that customer's orders through the index. `loops=1` on the inner node here, because
there was one outer row.

This is the right plan when the outer side is small and the inner side has an index. The shape
that is wrong is the same node with a sequential scan as the inner child: then the whole table is
read once per outer row, and the plan's cost is the product of the two sides. That shape means an
index is missing, and it is the single most common finding in a slow join.

Here is the loop count doing what the previous section warned about:

```
shop=# EXPLAIN ANALYZE SELECT count(*) FROM orders o JOIN order_lines l ON l.order_id = o.id WHERE o.status = 'pending';
                                                                     QUERY PLAN                                                                     
----------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=16715.95..16715.96 rows=1 width=8) (actual time=31.346..31.349 rows=1 loops=1)
   ->  Nested Loop  (cost=35.33..16697.82 rows=7250 width=0) (actual time=0.771..30.773 rows=7261 loops=1)
         ->  Bitmap Heap Scan on orders o  (cost=34.90..5631.57 rows=2900 width=4) (actual time=0.758..7.297 rows=2923 loops=1)
               Recheck Cond: (status = 'pending'::text)
               Heap Blocks: exact=2425
               ->  Bitmap Index Scan on orders_status_idx  (cost=0.00..34.17 rows=2900 width=0) (actual time=0.440..0.441 rows=2923 loops=1)
                     Index Cond: (status = 'pending'::text)
         ->  Index Only Scan using order_lines_pkey on order_lines l  (cost=0.43..3.79 rows=3 width=4) (actual time=0.007..0.007 rows=2 loops=2923)
               Index Cond: (order_id = o.id)
               Heap Fetches: 0
 Planning Time: 0.905 ms
 Execution Time: 31.494 ms
(12 rows)
```

`loops=2923` on the inner `Index Only Scan`, with `rows=2`: two rows **per loop**, an average
rounded to a whole row, and 2923 loops, which is the 7261 the join returned. The `actual time`
on that node is per loop too — seven thousandths of a millisecond each, which adds up to twenty of
the 31 ms. A per-loop number
looks harmless on its own, and it is the multiplication that decides whether the plan is good.

## Hash Join: build a table from one side, probe it with the other

```
shop=# EXPLAIN ANALYZE SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;
                                                              QUERY PLAN                                                              
--------------------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=28331.11..28331.21 rows=10 width=18) (actual time=489.337..489.343 rows=10 loops=1)
   Group Key: c.city
   Batches: 1  Memory Usage: 24kB
   ->  Hash Join  (cost=3237.00..23331.11 rows=1000000 width=10) (actual time=38.425..344.566 rows=1000000 loops=1)
         Hash Cond: (o.customer_id = c.id)
         ->  Seq Scan on orders o  (cost=0.00..17469.00 rows=1000000 width=4) (actual time=0.014..68.051 rows=1000000 loops=1)
         ->  Hash  (cost=1987.00..1987.00 rows=100000 width=14) (actual time=37.790..37.792 rows=100000 loops=1)
               Buckets: 131072  Batches: 1  Memory Usage: 5712kB
               ->  Seq Scan on customers c  (cost=0.00..1987.00 rows=100000 width=14) (actual time=0.012..16.491 rows=100000 loops=1)
 Planning Time: 0.715 ms
 Execution Time: 489.557 ms
(11 rows)
```

Two children again, and the one under `Hash` is read first, in full, into a hash table keyed by
the join column — every customer, in memory, `Memory Usage: 5712kB`. Then the other child is
scanned once, and each row's `customer_id` is looked up in the hash. A million lookups, each
constant time, and no index involved.

This is the plan for joining two large sets, and it does not care whether an index exists. Its
cost is memory: the hashed side has to fit in `work_mem`, and when it does not, `Batches` goes
above one and the hash spills to disk in pieces. `Batches: 1` here is the good case. The join of
`orders` to `order_lines`, a million rows against two and a half million, comes out as
`Batches: 8` on this machine's 4 MB of `work_mem` — still a hash join, still the cheapest plan, and
eight passes instead of one.

Which side is hashed is the planner's choice, and it hashes the smaller one. When a plan hashes the
wrong side — a million rows into memory to probe with a hundred — the estimate on one child is
wrong, and the estimates section is where to go.

## Merge Join: both sides sorted, walked together

The third algorithm needs both inputs in order on the join column, and then walks them once each,
like merging two sorted lists. The planner did not pick it for any query in this lesson on its own;
with hash joins switched off for one statement it shows the shape:

```
shop=# SET enable_hashjoin = off;
SET

shop=# EXPLAIN ANALYZE SELECT count(*) FROM orders o JOIN order_lines l ON l.order_id = o.id;
                                                                            QUERY PLAN                                                                             
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=130979.92..130979.93 rows=1 width=8) (actual time=857.013..857.014 rows=1 loops=1)
   ->  Merge Join  (cost=2.85..124729.92 rows=2500000 width=0) (actual time=3.308..734.858 rows=2500000 loops=1)
         Merge Cond: (o.id = l.order_id)
         ->  Index Only Scan using orders_pkey on orders o  (cost=0.42..25980.42 rows=1000000 width=4) (actual time=0.026..110.744 rows=1000000 loops=1)
               Heap Fetches: 0
         ->  Index Only Scan using order_lines_pkey on order_lines l  (cost=0.43..65004.43 rows=2500000 width=4) (actual time=0.030..266.332 rows=2500000 loops=1)
               Heap Fetches: 0
 Planning Time: 0.833 ms
 JIT:
   Functions: 5
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 0.157 ms, Inlining 0.000 ms, Optimization 0.188 ms, Emission 3.086 ms, Total 3.431 ms
 Execution Time: 874.100 ms
(13 rows)
```

Both children are `Index Only Scan`s on primary keys, so both arrive sorted for free, and the merge
walks them. It is the plan when the inputs are already ordered — two indexed keys, or an `ORDER BY`
that had to happen anyway — and it is the one that scales past memory, because nothing is hashed.
That it beat the hash join here, 874 ms against 1212, is the `Batches: 8` above: on a bigger
`work_mem` the hash would have won, and the planner's estimate of that is a setting, which is the
last section's subject.

Switching a join method off is a way to **see** a plan and never a way to ship one. The setting
is per session, and the section on fixing things says what to do instead.

## Which join is which

| node | good when | the sign it was wrong |
|---|---|---|
| `Nested Loop` | one side is small and the other is indexed | an inner `Seq Scan`, or `loops` in the millions |
| `Hash Join` | both sides are large and one fits in memory | `Batches` well above 1 |
| `Merge Join` | both sides are already sorted | a `Sort` node under each child, on large inputs |

**Join order is the other decision**, and it is why `EXPLAIN` on a five-table query is worth
reading before the join methods are. The planner chooses which pair to join first, and a plan that
joins two big tables and then filters the result — instead of filtering first and joining the
small remainder — is a plan whose estimate said the filter was not selective. Which, once again, is
the next section.

## Plans with workers

```
shop=# EXPLAIN ANALYZE SELECT c.city, count(*) FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.city;
                                                                       QUERY PLAN                                                                       
--------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=19050.09..19052.62 rows=10 width=18) (actual time=216.497..221.603 rows=10 loops=1)
   Group Key: c.city
   ->  Gather Merge  (cost=19050.09..19052.42 rows=20 width=18) (actual time=216.488..221.590 rows=30 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Sort  (cost=18050.06..18050.09 rows=10 width=18) (actual time=213.455..213.458 rows=10 loops=3)
               Sort Key: c.city
               Sort Method: quicksort  Memory: 25kB
               Worker 0:  Sort Method: quicksort  Memory: 25kB
               Worker 1:  Sort Method: quicksort  Memory: 25kB
               ->  Partial HashAggregate  (cost=18049.80..18049.90 rows=10 width=18) (actual time=213.416..213.420 rows=10 loops=3)
                     Group Key: c.city
                     Batches: 1  Memory Usage: 24kB
                     Worker 0:  Batches: 1  Memory Usage: 24kB
                     Worker 1:  Batches: 1  Memory Usage: 24kB
                     ->  Hash Join  (cost=3237.00..15966.46 rows=416667 width=10) (actual time=33.789..162.720 rows=333333 loops=3)
                           Hash Cond: (o.customer_id = c.id)
                           ->  Parallel Seq Scan on orders o  (cost=0.00..11635.67 rows=416667 width=4) (actual time=0.014..27.223 rows=333333 loops=3)
                           ->  Hash  (cost=1987.00..1987.00 rows=100000 width=14) (actual time=33.170..33.171 rows=100000 loops=3)
                                 Buckets: 131072  Batches: 1  Memory Usage: 5712kB
                                 ->  Seq Scan on customers c  (cost=0.00..1987.00 rows=100000 width=14) (actual time=0.019..11.714 rows=100000 loops=3)
 Planning Time: 0.749 ms
 Execution Time: 222.012 ms
(23 rows)
```

Every capture so far was taken in a session that began with
`SET max_parallel_workers_per_gather = 0`, the line from the start of the first section, so the
plans would read as one tree. This is the same city report in a new session, where parallel query
is on, which is the default: `Gather Merge` at the top, `Workers Launched: 2`, and `Parallel` in
front of the scan of `orders`. Three processes read a third of `orders` each —
`rows=333333 loops=3` — and each builds its own hash of all the customers, which is the `Hash`
with `loops=3` and `rows=100000`. Each aggregates its third, and the leader merges the partial
results. It took 222 ms against the single-process plan's 490.

Read it as the same tree with one rule added: **a node under a `Gather` reports per worker**, and
`loops=3` is the leader plus two workers. Nothing about the scans or the join has changed; there
are simply three of each.
