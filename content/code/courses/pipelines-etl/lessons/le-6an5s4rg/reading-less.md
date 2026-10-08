---
title: Reading less
version: 1
---

Writing is one half of a pipeline's cost. The other is reading — by the models that build the marts,
and by every report that queries them — and in a warehouse rented by the query, reading is usually
the half on the bill. `BUFFERS` counts what was read, in pages of eight kilobytes:

```
-- Revenue for one month, and the pages of the table each query had to read.
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT sum(line_cents) FROM big.fact_sales WHERE order_date BETWEEN DATE '2026-03-01' AND DATE '2026-03-31';
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT sum(line_cents) FROM big.fact_sales;
```

```
ana@vm:~/etl$ psql -q -d wh -f read.sql
                                           QUERY PLAN                                            
-------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1 loops=1)
   Buffers: shared hit=220
   ->  Index Scan using fact_sales_order_date_idx on fact_sales (actual rows=9030 loops=1)
         Index Cond: ((order_date >= '2026-03-01'::date) AND (order_date <= '2026-03-31'::date))
         Buffers: shared hit=220
 Planning:
   Buffers: shared hit=91
(7 rows)

                                   QUERY PLAN                                    
---------------------------------------------------------------------------------
 Finalize Aggregate (actual rows=1 loops=1)
   Buffers: shared hit=2539 read=23417
   ->  Gather (actual rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=2539 read=23417
         ->  Partial Aggregate (actual rows=1 loops=3)
               Buffers: shared hit=2539 read=23417
               ->  Parallel Seq Scan on fact_sales (actual rows=1170700 loops=3)
                     Buffers: shared hit=2539 read=23417
(10 rows)

done
```

Revenue for March: **220 pages**, about 1.7 MB, through the index. Revenue for all six years:
**25,956 pages** — 2,539 already in memory and 23,417 read from disk — about 200 MB, which is the
whole table, read by three processes in parallel. The second query is not badly written; it asks for
everything, and everything is what it costs.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 150\" role=\"img\" data-fig=\"l19-pages\" aria-label=\"Pages read to answer for one month against six years of the large table. One month through the index: 220 pages, about 1.7 MB. All six years: 25,956 pages, about 200 MB, the whole table.\"><text x=\"208.0\" y=\"43.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">March, by the index</text><rect x=\"220.0\" y=\"30.0\" width=\"3.6\" height=\"26.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"231.6\" y=\"43.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">220 pages</text><text x=\"208.0\" y=\"93.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">six years, the whole table</text><rect x=\"220.0\" y=\"80.0\" width=\"420.0\" height=\"26.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"632.0\" y=\"93.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">25,956 pages</text></svg>", "caption": "The cheapest page is the one the query never reads."}
```

The habits that keep reading cheap follow from that. **Filter on the column the table is organised
by** — here the date, which has the index — so that the database can skip what it does not need. Ask
for the columns a report uses rather than every column, which in PostgreSQL saves little but in a
columnar warehouse, where each column is stored apart, saves most of the bill. Build marts so that
reports read the small summary rather than the large fact table: `daily_sales` has a few thousand
rows where `fact_sales` has tens of thousands, and that ratio is the point of a mart.

Cloud warehouses price this in different ways — by the bytes a query scans, by the seconds of
compute it uses, or by a reserved size of machine — and none is reachable from the lab. Each of them
charges for one of the two things measured here: how much was read, or how long it took.
