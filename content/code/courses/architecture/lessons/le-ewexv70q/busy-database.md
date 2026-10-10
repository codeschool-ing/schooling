---
title: The busy database
version: 1
---

The front page shows the five best sellers of the last thirty days. The query is correct and takes a
millisecond or two. The trouble is in how it is used: **every visitor runs it**, and the answer is the
same for all of them. A hundred visitors:

```
ana@vm:~/lab/perf$ docker compose exec -T db psql -U postgres -c 'SELECT pg_stat_statements_reset()'
   pg_stat_statements_reset    
-------------------------------
 2026-10-10 19:31:23.696846+00
(1 row)

ana@vm:~/lab/perf$ $P front-page
front-page: 100 queries, 500 rows, 1,900 bytes, 484 ms
ana@vm:~/lab/perf$ docker compose exec -T db psql -U postgres -c 'SELECT calls, round(total_exec_time) AS total_ms, rows, left(query, 50) AS query FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 3'
 calls | total_ms | rows |                       query                        
-------+----------+------+----------------------------------------------------
   100 |      153 |  500 | SELECT i.product_id, sum(i.units) FROM items i JOI
     1 |        1 |    1 | SELECT pg_stat_statements_reset()
(2 rows)
```

`pg_stat_statements` is the tool for seeing this from the database's side: for every distinct query, how
often it ran and how much time it took in total. The best-sellers query ran a hundred times and used 153
milliseconds of the database's time, to compute the same five rows a hundred times. Now the same
hundred visitors, with the answer kept for a minute:

```
ana@vm:~/lab/perf$ $P front-page --cached
front-page: 1 queries, 5 rows, 19 bytes, 9 ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"A hundred visitors open the front page. Without a cache, every visit sends the best-sellers query to the database: one hundred queries. With a cache kept for a minute, the first visit asks the database and the other ninety-nine are answered from the cache: one query.\"><defs><marker id=\"l16-busy-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l16-busy-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"220\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">no cache: 100 queries</text><rect x=\"40\" y=\"60\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">100 visits</text><rect x=\"210\" y=\"150\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">database</text><path d=\"M110 102 L230 148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M118 102 L248 148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M126 102 L266 148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M134 102 L284 148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M142 102 L302 148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l16-busy-ah-amber)\"></path><text x=\"535\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">cached: 1 query</text><rect x=\"400\" y=\"60\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">100 visits</text><rect x=\"560\" y=\"60\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">cache, 1 min</text><path d=\"M522 80 L558 80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16-busy-ah-phosphor)\"></path><rect x=\"560\" y=\"150\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">database</text><path d=\"M620 102 L620 148\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16-busy-ah-phosphor)\"></path><text x=\"632\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">once</text></svg>", "caption": "The busy database answers the same question for every visitor. A cache, or a read model, asks it once."}
```

**One query instead of a hundred.** The best sellers of the last thirty days do not change in a minute
in any way a visitor would notice, so a cache that is up to a minute old is free accuracy-wise and
removes 99% of that query's load. Where the answer must be fresher, lesson 13's read model is the same
idea kept up to date by events instead of by a timer.

The database is usually the hardest part of a system to scale, as lesson 10 showed: one primary takes
the writes, and adding capacity is a bigger machine or a sharding project. So work that does not need to
happen there should not. The **busy database** antipattern covers the whole family:

- **The same question for every request**, as above. Cache it, or keep a read model.
- **Logic that belongs in the application**, done in SQL because it was convenient: formatting text,
  building JSON or XML, complex calculations in stored procedures. The database's CPU is the scarcest
  CPU in the system.
- **Queries that read far more than they return**, usually for want of an index. The history page looks
  up items by `order_id`, and there is no index on it:

```
ana@vm:~/lab/perf$ docker compose exec -T db psql -U postgres -c 'EXPLAIN ANALYZE SELECT product_id, units FROM items WHERE order_id = 42'
                                            QUERY PLAN                                            
--------------------------------------------------------------------------------------------------
 Seq Scan on items  (cost=0.00..156.20 rows=45 width=8) (actual time=0.030..0.861 rows=4 loops=1)
   Filter: (order_id = 42)
   Rows Removed by Filter: 7996
 Planning Time: 0.308 ms
 Execution Time: 0.897 ms
(5 rows)

ana@vm:~/lab/perf$ docker compose exec -T db psql -U postgres -c 'CREATE INDEX ON items (order_id)' -c 'EXPLAIN ANALYZE SELECT product_id, units FROM items WHERE order_id = 42'
CREATE INDEX
                                                         QUERY PLAN                                                         
----------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on items  (cost=4.59..50.08 rows=40 width=8) (actual time=0.034..0.036 rows=4 loops=1)
   Recheck Cond: (order_id = 42)
   Heap Blocks: exact=1
   ->  Bitmap Index Scan on items_order_id_idx  (cost=0.00..4.58 rows=40 width=0) (actual time=0.026..0.026 rows=4 loops=1)
         Index Cond: (order_id = 42)
 Planning Time: 0.363 ms
 Execution Time: 0.067 ms
(7 rows)
```

Without the index, PostgreSQL read all 8,000 items to find 4 (`Rows Removed by Filter: 7996`). With it,
it went straight to them, and the execution time fell from 0.9 milliseconds to 0.07. On 8,000 rows
nobody notices; on 80 million the first plan is a page that times out. `EXPLAIN ANALYZE` on the queries
`pg_stat_statements` ranks highest is the usual first hour of looking at a busy database.
