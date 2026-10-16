---
title: The visibility map, and what wipes it
version: 1
---

Every table has a small companion file called the **visibility map**: two bits per page of the
table. The one that matters here says "every row on this page is visible to every transaction".
When an index-only scan meets an entry, it looks up the entry's page in the map. If the bit is set,
the row must be visible and the index entry is the answer. If not, the scan reads the table page to
check, and that is one **heap fetch**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A flow for each index entry in an index-only scan. The entry points to a page of the table. The scan asks the visibility map whether that page is all-visible. If yes, the row is answered from the index entry alone. If no, the scan reads the table page to check the row, which counts as a heap fetch. VACUUM sets the bits in the map; any change to a row on a page clears that page&#x27;s bit.\"><rect x=\"14\" y=\"90\" width=\"150\" height=\"60\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"89\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">index entry</text><text x=\"89\" y=\"132\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">values + page number</text><path d=\"M164 120 L214 120\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M214.0 120.0 L208.0 124.0 L208.0 116.0 Z\" fill=\"var(--wire)\"></path><rect x=\"214\" y=\"80\" width=\"210\" height=\"80\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"319\" y=\"104\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">visibility map:</text><text x=\"319\" y=\"124\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">is that page</text><text x=\"319\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">all-visible?</text><path d=\"M424 104 L470 104 L470 50 L500 50\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M494 50 L500 50\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M500.0 50.0 L494.0 54.0 L494.0 46.0 Z\" fill=\"var(--phosphor)\"></path><text x=\"436\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">yes</text><rect x=\"500\" y=\"26\" width=\"206\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"603\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">answer from the index</text><text x=\"603\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">Heap Fetches +0</text><path d=\"M424 136 L470 136 L470 190 L500 190\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><path d=\"M494 190 L500 190\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><path d=\"M500.0 190.0 L494.0 194.0 L494.0 186.0 Z\" fill=\"var(--amber)\"></path><text x=\"436\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no</text><rect x=\"500\" y=\"166\" width=\"206\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"603\" y=\"184\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">read the table page</text><text x=\"603\" y=\"202\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--amber)\">Heap Fetches +1</text><text x=\"214\" y=\"196\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">VACUUM sets a page's bit;</text><text x=\"214\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">any change to a row clears it</text></svg>", "caption": "What an index-only scan does with each entry. The index is always read; the table is read only for pages the visibility map does not vouch for."}
```

Two rules decide the bits, and the whole section follows from them:

- **`VACUUM` sets them.** When it has cleaned a page and found every row on it visible to all, it
  marks the page all-visible.
- **any change to a row clears them.** An `UPDATE`, a `DELETE` or an `INSERT` on a page clears that
  page's bit at once, because the page now holds a row some transaction cannot see yet.

## How much of `orders` the map covers

`pg_class` keeps a count of the pages the map marks all-visible, `relallvisible`, beside the count
of pages, `relpages`:

```
market=# SELECT relpages, relallvisible FROM pg_class WHERE relname = 'orders';
 relpages | relallvisible 
----------+---------------
    16667 |         16667
(1 row)

Time: 1.473 ms
```

**16,667 pages, 16,667 all-visible.** `market.sql` ended with `VACUUM ANALYZE`, nothing has changed
`orders` since, and every page is marked. That is why both index-only scans so far showed `Heap
Fetches: 0`.

## One update

The orders shipped in late December get delivered. One statement marks them all, the kind of job
an application runs every night:

```
market=# UPDATE orders SET status = 'delivered' WHERE status = 'shipped';
UPDATE 43422
Time: 914.340 ms

market=# SELECT relpages, relallvisible FROM pg_class WHERE relname = 'orders';
 relpages | relallvisible 
----------+---------------
    16667 |         16667
(1 row)

Time: 1.232 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE placed_at >= '2025-12-01';
                                                                      QUERY PLAN                                                                      
------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=3383.39..3383.40 rows=1 width=8) (actual time=59.157..59.159 rows=1 loops=1)
   Buffers: shared hit=87265
   ->  Index Only Scan using orders_placed_at_idx on orders  (cost=0.43..3112.39 rows=108398 width=0) (actual time=0.051..53.396 rows=107780 loops=1)
         Index Cond: (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone)
         Heap Fetches: 87062
         Buffers: shared hit=87265
 Planning:
   Buffers: shared hit=20
 Planning Time: 0.212 ms
 Execution Time: 59.206 ms
(10 rows)

Time: 60.230 ms
```

The `UPDATE` changed 43,422 rows, all of them in the last weeks of December. Two things in the
output are worth reading slowly.

**`relallvisible` still says 16,667.** It is not wrong, it is old: `pg_class` is updated by `VACUUM`
and `ANALYZE`, not by every change, so it reports the map as the last `VACUUM` left it. The map
itself changed the moment the rows did. The column is a cheap way to watch a table between vacuums,
and a misleading one right after a burst of writes.

**`Heap Fetches: 87062`** where there were none, and **87,265 page accesses** instead of 299. The
same index, the same query, the same 107,780 rows, and the plan still says `Index Only Scan`. Every
page the update touched lost its bit: the pages where the old versions of the rows sat, and the new
pages at the end of the table where the new versions went. And the index now holds **two entries
for each updated order**, one per version, because an update that cannot stay on its page writes a
new version elsewhere and indexes it again. The scan has to check both against the table, the old
one to find it dead and the new one to find it visible: 43,422 × 2 is 86,844, nearly all of the
87,062. It took 59 milliseconds; the clean scan took 20.

## `VACUUM` puts it back

```
market=# VACUUM orders;
VACUUM
Time: 133.860 ms

market=# SELECT relpages, relallvisible FROM pg_class WHERE relname = 'orders';
 relpages | relallvisible 
----------+---------------
    17029 |         17029
(1 row)

Time: 1.110 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE placed_at >= '2025-12-01';
                                                                      QUERY PLAN                                                                      
------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=3314.25..3314.26 rows=1 width=8) (actual time=17.451..17.453 rows=1 loops=1)
   Buffers: shared hit=419
   ->  Index Only Scan using orders_placed_at_idx on orders  (cost=0.43..3049.02 rows=106091 width=0) (actual time=0.046..12.134 rows=107780 loops=1)
         Index Cond: (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone)
         Heap Fetches: 0
         Buffers: shared hit=419
 Planning:
   Buffers: shared hit=46
 Planning Time: 0.350 ms
 Execution Time: 17.513 ms
(10 rows)

Time: 18.833 ms
```

**Heap Fetches: 0** again, 419 pages, 17.5 milliseconds. `relpages` grew from 16,667 to 17,029: the
updated rows were written as new versions and the old ones left behind, which is how PostgreSQL
updates, and `VACUUM` marked the space they occupied free for reuse rather than giving it back.
Lesson 15 is about that growth; what matters here is that every page is all-visible again.

## What this means for a real table

An index-only scan is only as good as the visibility map behind it, and the map is only as fresh as
the last `VACUUM`. On a table that is written all day, the pages being written are exactly the pages
whose bits keep being cleared, and if the queries ask about recent rows, as most do, they ask about
exactly those pages.

Autovacuum is what keeps the map current in practice, and it runs on a table when enough rows have
changed. `db-administration` lesson 14 is how it decides when, and how to make it visit a busy table
more often. The plan's `Heap Fetches` is how you tell whether it is keeping up: a number near zero
means the map is current, and a number near the row count means your index-only scan is not
one.
