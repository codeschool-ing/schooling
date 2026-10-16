---
title: One wrong number, and everything built on it
version: 1
---

A misestimate on a scan that reads the whole table anyway costs nothing by itself. What it costs is
**everything above it**: the join method chosen for the rows that scan returns, the side a hash
table is built on, whether a sort is planned in memory, how groups are counted. Each of those is a
decision made for the estimate, and lesson 5 showed how differently the three join methods behave
when the number of rows changes.

The query for this section is a screen the operations team uses: which seller has the most pending
orders, and in which state, so deliveries can be planned. It joins `orders` to `sellers` and to
`customers`.

## Before the import

Run on the database as lesson 3 starts, with its 7319 pending orders and statistics that describe
them correctly:

```
market=# EXPLAIN ANALYZE SELECT s.name, c.state, count(*) AS pending FROM orders o JOIN sellers s ON s.id = o.seller_id JOIN customers c ON c.id = o.customer_id WHERE o.status = 'pending' GROUP BY s.name, c.state ORDER BY pending DESC LIMIT 5;
                                                                        QUERY PLAN                                                                        
----------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=50054.74..50054.75 rows=5 width=21) (actual time=212.504..212.510 rows=5 loops=1)
   ->  Sort  (cost=50054.74..50071.24 rows=6600 width=21) (actual time=212.502..212.507 rows=5 loops=1)
         Sort Key: (count(*)) DESC
         Sort Method: top-N heapsort  Memory: 25kB
         ->  GroupAggregate  (cost=49813.12..49945.12 rows=6600 width=21) (actual time=210.647..212.077 rows=3435 loops=1)
               Group Key: s.name, c.state
               ->  Sort  (cost=49813.12..49829.62 rows=6600 width=13) (actual time=210.624..210.935 rows=7319 loops=1)
                     Sort Key: s.name, c.state
                     Sort Method: quicksort  Memory: 493kB
                     ->  Hash Join  (cost=41778.00..49394.40 rows=6600 width=13) (actual time=161.481..205.961 rows=7319 loops=1)
                           Hash Cond: (o.seller_id = s.id)
                           ->  Hash Join  (cost=41749.50..49348.50 rows=6600 width=7) (actual time=161.106..204.167 rows=7319 loops=1)
                                 Hash Cond: (c.id = o.customer_id)
                                 ->  Seq Scan on customers c  (cost=0.00..4283.00 rows=200000 width=7) (actual time=0.002..22.685 rows=200000 loops=1)
                                 ->  Hash  (cost=41667.00..41667.00 rows=6600 width=8) (actual time=161.021..161.022 rows=7319 loops=1)
                                       Buckets: 8192  Batches: 1  Memory Usage: 350kB
                                       ->  Seq Scan on orders o  (cost=0.00..41667.00 rows=6600 width=8) (actual time=159.386..160.109 rows=7319 loops=1)
                                             Filter: (status = 'pending'::text)
                                             Rows Removed by Filter: 1992681
                           ->  Hash  (cost=16.00..16.00 rows=1000 width=14) (actual time=0.358..0.359 rows=1000 loops=1)
                                 Buckets: 1024  Batches: 1  Memory Usage: 55kB
                                 ->  Seq Scan on sellers s  (cost=0.00..16.00 rows=1000 width=14) (actual time=0.015..0.147 rows=1000 loops=1)
 Planning Time: 1.278 ms
 Execution Time: 212.766 ms
(24 rows)

Time: 234.594 ms
```

Every node below the grouping agrees with its estimate within 10%: 6600 expected pending
orders, 7319 found. The plan
is two hash joins. The small side of each, the 7319 orders and the 1000 sellers, is the one turned
into a hash table, which is the right way round. Then a sort in memory, 493 kB, and the groups
counted in order: **213 milliseconds**, most of it reading `orders`.

## After the import, before `ANALYZE`

The same query, after section 03's import, with the statistics still saying 0.0033:

```
market=# EXPLAIN ANALYZE SELECT s.name, c.state, count(*) AS pending FROM orders o JOIN sellers s ON s.id = o.seller_id JOIN customers c ON c.id = o.customer_id WHERE o.status = 'pending' GROUP BY s.name, c.state ORDER BY pending DESC LIMIT 5;
                                                                           QUERY PLAN                                                                           
----------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=57599.04..57599.06 rows=5 width=21) (actual time=661.501..661.511 rows=5 loops=1)
   ->  Sort  (cost=57599.04..57618.02 rows=7590 width=21) (actual time=661.500..661.508 rows=5 loops=1)
         Sort Key: (count(*)) DESC
         Sort Method: top-N heapsort  Memory: 25kB
         ->  GroupAggregate  (cost=57321.18..57472.98 rows=7590 width=21) (actual time=605.205..660.587 rows=9000 loops=1)
               Group Key: s.name, c.state
               ->  Sort  (cost=57321.18..57340.15 rows=7590 width=13) (actual time=605.177..640.593 rows=307319 loops=1)
                     Sort Key: s.name, c.state
                     Sort Method: external merge  Disk: 7216kB
                     ->  Nested Loop  (cost=7565.28..56832.01 rows=7590 width=13) (actual time=163.166..415.153 rows=307319 loops=1)
                           ->  Hash Join  (cost=7565.00..56343.85 rows=7590 width=7) (actual time=161.908..335.908 rows=307319 loops=1)
                                 Hash Cond: (o.customer_id = c.id)
                                 ->  Seq Scan on orders o  (cost=0.00..47916.93 rows=7590 width=8) (actual time=107.107..148.260 rows=307319 loops=1)
                                       Filter: (status = 'pending'::text)
                                       Rows Removed by Filter: 1992681
                                 ->  Hash  (cost=4283.00..4283.00 rows=200000 width=7) (actual time=53.694..53.696 rows=200000 loops=1)
                                       Buckets: 262144  Batches: 2  Memory Usage: 5966kB
                                       ->  Seq Scan on customers c  (cost=0.00..4283.00 rows=200000 width=7) (actual time=0.018..20.372 rows=200000 loops=1)
                           ->  Memoize  (cost=0.29..0.31 rows=1 width=14) (actual time=0.000..0.000 rows=1 loops=307319)
                                 Cache Key: o.seller_id
                                 Cache Mode: logical
                                 Hits: 306319  Misses: 1000  Evictions: 0  Overflows: 0  Memory Usage: 114kB
                                 ->  Index Scan using sellers_pkey on sellers s  (cost=0.28..0.30 rows=1 width=14) (actual time=0.001..0.001 rows=1 loops=1000)
                                       Index Cond: (id = o.seller_id)
 Planning Time: 1.035 ms
 Execution Time: 662.895 ms
(26 rows)

Time: 665.444 ms
```

**663 milliseconds.** Read it from the bottom, as section 02 said.

- **`Seq Scan on orders`**: 7590 estimated, **307,319** actual. This is the lowest node where the
  two part, and the cause.
- **`Hash Join`**: the same 7590 against 307,319, inherited. Here the planner did make one choice
  that held up, building the hash on `customers` rather than on orders.
- **`Nested Loop` with `Memoize` into `sellers`**: chosen because a loop of seven thousand lookups,
  with a cache in front of the sellers' index, is cheaper than building another hash table. It ran
  **307,319 times**. The cache saved it, 306,319 hits and 1000 misses, but every one of those 307,319
  rows still went through the loop. This is the nested loop lesson 5 warned about: right for a
  few thousand rows from the outer side, wrong for three hundred thousand.
- **`Sort`**: planned for 7590 rows in memory, it received 307,319 and **spilled 7216 kB to disk**,
  `external merge`. Planned memory for an estimate is spent on the actual.
- **`GroupAggregate`** expected 7590 groups and found 9000, which is the one estimate here that was
  roughly right, by accident.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"The stale plan as a tree, read from the bottom. At the bottom, Seq Scan on orders estimated 7,590 rows and returned 307,319: the lowest node where estimate and actual part. Every node above it inherits the error: the Hash Join, estimated 7,590 against 307,319; the Nested Loop with Memoize into sellers, chosen for a few thousand lookups and run 307,319 times; the Sort planned in memory, which spilled 7,216 kB to disk; and the GroupAggregate. Customers, on the other side of the hash join, was estimated correctly at 200,000.\"><rect x=\"230\" y=\"20\" width=\"250\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"240\" y=\"35\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GroupAggregate</text><text x=\"240\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">estimated</text><text x=\"305\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">7,590</text><text x=\"365\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">actual</text><text x=\"405\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">9,000</text><rect x=\"230\" y=\"78\" width=\"250\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"240\" y=\"93\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Sort</text><text x=\"240\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">estimated</text><text x=\"305\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">7,590</text><text x=\"365\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">actual</text><text x=\"405\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">307,319</text><rect x=\"230\" y=\"136\" width=\"250\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"240\" y=\"151\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Nested Loop + Memoize</text><text x=\"240\" y=\"168\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">estimated</text><text x=\"305\" y=\"168\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">7,590</text><text x=\"365\" y=\"168\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">actual</text><text x=\"405\" y=\"168\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">307,319</text><rect x=\"100\" y=\"194\" width=\"250\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"209\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Hash Join</text><text x=\"110\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">estimated</text><text x=\"175\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">7,590</text><text x=\"235\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">actual</text><text x=\"275\" y=\"226\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">307,319</text><rect x=\"14\" y=\"252\" width=\"250\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"267\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Seq Scan on orders</text><text x=\"24\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">estimated</text><text x=\"89\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">7,590</text><text x=\"149\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">actual</text><text x=\"189\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">307,319</text><rect x=\"330\" y=\"252\" width=\"250\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"340\" y=\"267\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Seq Scan on customers</text><text x=\"340\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">estimated</text><text x=\"405\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">200,000</text><text x=\"465\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">actual</text><text x=\"505\" y=\"284\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">200,000</text><path d=\"M355 64 L355 78\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M355 122 L355 136\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M355 180 L225 194\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M225 238 L139 252\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M225 238 L455 252\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"500\" y=\"100\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">Sort: 7,216 kB</text><text x=\"500\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">spilled to disk</text><text x=\"500\" y=\"158\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">307,319 loops</text><text x=\"14\" y=\"316\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the lowest node where the two part: start reading here</text></svg>", "caption": "Where the stale plan went wrong, and what it dragged along. One wrong number at the bottom; every choice above it was made for that number."}
```

## After `ANALYZE`

Take a new photograph of `orders`, and run the query again:

```
market=# ANALYZE orders;
ANALYZE
Time: 131.735 ms

market=# EXPLAIN ANALYZE SELECT s.name, c.state, count(*) AS pending FROM orders o JOIN sellers s ON s.id = o.seller_id JOIN customers c ON c.id = o.customer_id WHERE o.status = 'pending' GROUP BY s.name, c.state ORDER BY pending DESC LIMIT 5;
                                                                      QUERY PLAN                                                                       
-------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=62714.17..62714.19 rows=5 width=21) (actual time=463.852..463.873 rows=5 loops=1)
   ->  Sort  (cost=62714.17..62736.67 rows=9000 width=21) (actual time=463.850..463.869 rows=5 loops=1)
         Sort Key: (count(*)) DESC
         Sort Method: top-N heapsort  Memory: 25kB
         ->  HashAggregate  (cost=62474.69..62564.69 rows=9000 width=21) (actual time=461.940..462.854 rows=9000 loops=1)
               Group Key: s.name, c.state
               Batches: 1  Memory Usage: 1169kB
               ->  Hash Join  (cost=7593.50..60221.26 rows=300457 width=13) (actual time=186.243..397.733 rows=307319 loops=1)
                     Hash Cond: (o.seller_id = s.id)
                     ->  Hash Join  (cost=7565.00..59400.72 rows=300457 width=7) (actual time=185.889..355.253 rows=307319 loops=1)
                           Hash Cond: (o.customer_id = c.id)
                           ->  Seq Scan on orders o  (cost=0.00..47917.00 rows=300457 width=8) (actual time=127.722..165.349 rows=307319 loops=1)
                                 Filter: (status = 'pending'::text)
                                 Rows Removed by Filter: 1992681
                           ->  Hash  (cost=4283.00..4283.00 rows=200000 width=7) (actual time=57.098..57.099 rows=200000 loops=1)
                                 Buckets: 262144  Batches: 2  Memory Usage: 5966kB
                                 ->  Seq Scan on customers c  (cost=0.00..4283.00 rows=200000 width=7) (actual time=0.014..21.839 rows=200000 loops=1)
                     ->  Hash  (cost=16.00..16.00 rows=1000 width=14) (actual time=0.336..0.351 rows=1000 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 55kB
                           ->  Seq Scan on sellers s  (cost=0.00..16.00 rows=1000 width=14) (actual time=0.011..0.121 rows=1000 loops=1)
 Planning Time: 0.994 ms
 Execution Time: 464.233 ms
(22 rows)

Time: 466.854 ms
```

The estimate on the scan is now **300,457** against 307,319, and every node above it changed with
it. Both joins are hash joins. The sellers lookup is a 55 kB hash table instead of a loop running
307,319 times. The groups are counted in a `HashAggregate` in 1169 kB of memory, with no sort of
three hundred thousand rows and nothing written to disk. **464 milliseconds**, against 663 for the
same query and the same rows a minute earlier.

That is a 30% difference, and it is worth being honest about its size. On this machine, with all of
`market` in the operating system's cache, the worse plan was not a disaster; reading 2.3 million orders is most
of the time either way. The cascade gets expensive when the cheap-looking loop at the bottom fetches
from a table that is not in memory, or when the misestimated rows feed a second and third join that
each multiply them. What does not depend on the machine is the pattern: **a ratio of 40 at the
bottom, and every operator above it chosen for the wrong number**.

## The habit

When a plan is slow, before you look at which join method it chose, find the lowest node whose
actual rows are far from its estimate. Then ask why that estimate is wrong. Here it was stale, and
`ANALYZE` fixed it in 132 milliseconds. Lesson 7 is the other half of the answer: estimates that are
wrong although the statistics are fresh, and what to give the planner then.
