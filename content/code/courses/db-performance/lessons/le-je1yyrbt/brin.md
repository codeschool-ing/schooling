---
title: BRIN: a tiny index for a table in order
version: 1
---

Every index so far has had one entry per row, or more. BRIN, the Block Range INdex, has one entry
per **stretch of the table**: by default 128 pages, a megabyte. For each stretch it records the
smallest and the largest value of the column in it, and nothing else. A search for a value reads
those summaries, skips every stretch whose minimum and maximum rule the value out, and reads the
rest of the table page by page.

That only works on one kind of column, and lesson 7 gave you the number that says which:
`correlation`.

## The column it was made for

`events` is written in time order, so the events of any one stretch of pages are from a few hours
of one day. Its summary, and the two indexes:

```
market=# SELECT attname, correlation FROM pg_stats WHERE tablename = 'events' AND attname IN ('at', 'customer_id');
   attname   |  correlation  
-------------+---------------
 at          |             1
 customer_id | -0.0031879602
(2 rows)

Time: 4.506 ms

market=# CREATE INDEX events_at_brin_idx ON events USING brin (at);
CREATE INDEX
Time: 951.654 ms

market=# CREATE INDEX events_at_btree_idx ON events (at);
CREATE INDEX
Time: 2358.183 ms (00:02.358)

market=# SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS size FROM pg_class WHERE relname IN ('events', 'events_at_brin_idx', 'events_at_btree_idx');
       relname       |  size  
---------------------+--------
 events              | 511 MB
 events_at_brin_idx  | 32 kB
 events_at_btree_idx | 107 MB
(3 rows)

Time: 1.069 ms
```

`at` has a correlation of **1**, perfectly in table order; `customer_id` has **-0.0032**, none at
all. On `at`, the B-tree is **107 MB** and took 2.4 seconds to build. The BRIN index is **32 kB**,
about three thousand times smaller, and took under a second. It has a few hundred entries for five
million rows: 511 MB of table in ranges of 1 MB each.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two rows of eight boxes, each box a range of 128 pages of the events table with the smallest and largest value it holds. In the top row, for the column at, each box covers a short stretch of time, one after the other like stairs, and a query for a stretch of time touches only the boxes whose stretch contains it. In the bottom row, for customer_id, every box covers nearly the whole span from 1 to 200,000, so a query for customer 4242 matches every box and every page has to be read.\"><text x=\"14\" y=\"74\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">events.at</text><text x=\"14\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">in table order</text><rect x=\"150\" y=\"60\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"154.0\" y=\"90\" width=\"7.0\" height=\"6\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"220\" y=\"60\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"231.0\" y=\"90\" width=\"7.0\" height=\"6\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"290\" y=\"60\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"308.0\" y=\"90\" width=\"7.0\" height=\"6\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"360\" y=\"60\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"385.0\" y=\"90\" width=\"7.0\" height=\"6\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"430\" y=\"60\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"462.0\" y=\"90\" width=\"7.0\" height=\"6\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"500\" y=\"60\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"539.0\" y=\"90\" width=\"7.0\" height=\"6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"570\" y=\"60\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"616.0\" y=\"90\" width=\"7.0\" height=\"6\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"640\" y=\"60\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"693.0\" y=\"90\" width=\"7.0\" height=\"6\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"150\" y=\"120\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a query for a stretch of time reads only the ranges that hold it</text><text x=\"14\" y=\"174\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">events.customer_id</text><text x=\"14\" y=\"190\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">scattered</text><rect x=\"150\" y=\"160\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"154.5\" y=\"190\" width=\"54.4\" height=\"6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"220\" y=\"160\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"224.8\" y=\"190\" width=\"54.3\" height=\"6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"290\" y=\"160\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"295.4\" y=\"190\" width=\"52.5\" height=\"6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"360\" y=\"160\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"364.0\" y=\"190\" width=\"55.6\" height=\"6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"430\" y=\"160\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"434.6\" y=\"190\" width=\"53.7\" height=\"6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"500\" y=\"160\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"506.2\" y=\"190\" width=\"52.6\" height=\"6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"570\" y=\"160\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"575.9\" y=\"190\" width=\"53.0\" height=\"6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"640\" y=\"160\" width=\"64\" height=\"44\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"645.4\" y=\"190\" width=\"52.7\" height=\"6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"150\" y=\"220\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a query for customer 4242 matches every range, so reads every page</text><text x=\"150\" y=\"40\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">each box: 128 pages, with the smallest and largest value in them</text><text x=\"150\" y=\"276\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the bar inside a box: the stretch of values that range covers</text></svg>", "caption": "What a BRIN index keeps: the smallest and largest value of each range of 128 pages. On a column in table order the ranges are narrow and a search skips almost all of them; on a scattered column every range covers everything."}
```

Now a day's events, with only the BRIN index left:

```
market=# DROP INDEX events_at_btree_idx;
DROP INDEX
Time: 94.962 ms

market=# EXPLAIN ANALYZE SELECT count(*) FROM events WHERE at >= '2025-12-24' AND at < '2025-12-25';
                                                                      QUERY PLAN                                                                      
------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=69223.56..69223.57 rows=1 width=8) (actual time=17.858..17.861 rows=1 loops=1)
   ->  Bitmap Heap Scan on events  (cost=31.07..69075.15 rows=59364 width=0) (actual time=1.805..15.114 rows=55835 loops=1)
         Recheck Cond: ((at >= '2025-12-24 00:00:00-03'::timestamp with time zone) AND (at < '2025-12-25 00:00:00-03'::timestamp with time zone))
         Rows Removed by Index Recheck: 12635
         Heap Blocks: lossy=896
         ->  Bitmap Index Scan on events_at_brin_idx  (cost=0.00..16.22 rows=68359 width=0) (actual time=0.188..0.189 rows=8960 loops=1)
               Index Cond: ((at >= '2025-12-24 00:00:00-03'::timestamp with time zone) AND (at < '2025-12-25 00:00:00-03'::timestamp with time zone))
 Planning Time: 0.398 ms
 Execution Time: 17.943 ms
(9 rows)

Time: 19.358 ms
```

**18 milliseconds for 55,835 events.** Read the bitmap lines from the bottom. The index scan
matched a handful of ranges, and `Heap Blocks: lossy=896` is seven ranges of 128 pages: BRIN
cannot say which rows match, only which pages might, so the bitmap is **lossy**, a list of pages
rather than rows. Every row on those pages was then checked again, and `Rows Removed by Index
Recheck: 12635` is the events of the hours either side of the day that shared its first and last
ranges. A B-tree would have pointed straight at the 55,835 rows; BRIN read 68,470 rows to find
them, and for 0.03% of the B-tree's size that is a good trade.

That is BRIN's whole offer: an index almost free to store and cheap to keep up, which a new row
updates only when it lands outside its range's summary, in exchange for reading a little more
than the answer. It suits exactly the big append-only tables, logs and events and readings, where
a B-tree on the time column would be one of the largest things on the disk.

## The column it was not made for

Build the same kind of index on `customer_id`, whose values are scattered across the table:

```
market=# CREATE INDEX events_customer_brin_idx ON events USING brin (customer_id);
CREATE INDEX
Time: 927.104 ms

market=# EXPLAIN ANALYZE SELECT count(*) FROM events WHERE customer_id = 4242;
                                                                          QUERY PLAN                                                                           
---------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=82412.88..82412.89 rows=1 width=8) (actual time=436.591..445.316 rows=1 loops=1)
   ->  Gather  (cost=82412.66..82412.87 rows=2 width=8) (actual time=436.349..445.305 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate  (cost=81412.66..81412.67 rows=1 width=8) (actual time=432.313..432.315 rows=1 loops=3)
               ->  Parallel Bitmap Heap Scan on events  (cost=26.04..81412.64 rows=8 width=0) (actual time=171.791..432.288 rows=6 loops=3)
                     Recheck Cond: (customer_id = 4242)
                     Rows Removed by Index Recheck: 1666661
                     Heap Blocks: lossy=26267
                     ->  Bitmap Index Scan on events_customer_brin_idx  (cost=0.00..26.04 rows=3063283 width=0) (actual time=3.463..3.464 rows=654320 loops=1)
                           Index Cond: (customer_id = 4242)
 Planning Time: 0.583 ms
 Execution Time: 445.468 ms
(13 rows)

Time: 447.036 ms
```

**445 milliseconds for 18 events.** The index matched 654,320 rows' worth of ranges, which is all
of them: every stretch of pages holds events of customers from near 1 to near 200,000, so every
summary says "might be here". The scan ran in three
processes, and `Rows Removed by Index Recheck: 1666661` in each of them, three times over, is
every other event in the table. The index made
the query no faster than a sequential scan, and the planner chose it only because it does not know
in advance how useless the summaries are.

So BRIN is a bet on physical order. Check `correlation` before building one, and remember that
order can decay: a table whose rows are updated, or deleted and refilled, slowly loses it, and the
BRIN index loses its use with it.

## Which lesson 2 query each index fixes

| index | question it answers | in `market` | lesson 2's workload |
|---|---|---|---|
| B-tree | `=`, ranges, `ORDER BY`, `LIKE 'prefix%'` | `price_cents`, for the tag search's `ORDER BY … LIMIT` | **`tag-search.sql`**, 58.7 to 0.7 ms; lesson 2 already added `seller_id` for `seller-dashboard.sql` |
| hash | `=` only | `customers.email` | none |
| GIN | contains: array elements, `jsonb` keys, words | `tags`, `payload` | `tag-search.sql`, 58.7 to 19.8 ms |
| GiST | similar, nearest, overlaps | titles by trigram, away ranges | none |
| BRIN | ranges on a column in table order | `events.at` | none |

`pending-count.sql`, second in lesson 2's tally, is missing from the table on purpose. A plain
B-tree on `status` would do for it, and lesson 9 builds one seventy times smaller.
`customer-orders.sql` is already served by `orders_customer_id_idx`, and lesson 10 makes it never
touch the table at all.

This lesson built indexes, two extensions and a table on `market`. Close `psql` and put the
database back as lesson 3 starts:

```sh
~/reset-market.sh
```
