---
title: The row that arrives in the past
version: 1
---

The watermark has a trap, and it is the one that makes people distrust incremental loads.

`updated_at` is set when a row is *written*. The row becomes visible when its transaction
*commits*. Those are two different moments, and a long transaction can put minutes between them.
**A row written before the watermark and committed after the extraction ran falls in a window the
pipeline will never ask for again.**

The lab stages one. At the Paulista shop on 2 March, a card machine hangs at 23:40 with the
transaction open; the order commits after that night's extraction has read up to 23:59:47. What
the till leaves in the shop is an order whose timestamps say 23:40:

```
ana@vm:~/etl$ psql -c "SELECT order_id, ordered_at, updated_at FROM orders WHERE order_id = 900001"
 order_id |       ordered_at       |       updated_at       
----------+------------------------+------------------------
   900001 | 2026-03-02 23:40:00-03 | 2026-03-02 23:40:00-03
(1 row)

ana@vm:~/etl$ sudo bash ~/lab/lab.sh day 2026-03-03
ana@vm:~/etl$ python incremental.py orders
shop.orders: 301 rows since 03-02 23:59:47, watermark now 03-03 23:51:38
ana@vm:~/etl$ python incremental.py orders 60
shop.orders+60m: 306 rows since 03-02 23:59:47, watermark now 03-03 23:51:38
ana@vm:~/etl$ psql -d wh -c "SELECT 'no lookback' AS run, count(*) FROM raw.orders_changes WHERE order_id = 900001 UNION ALL SELECT '60 minutes', count(*) FROM raw.orders_changes_60m WHERE order_id = 900001"
     run     | count 
-------------+-------
 no lookback |     0
 60 minutes  |     1
(2 rows)
```

The plain extraction on the night of 3 March asks for everything after 23:59:47 on the 2nd, and
order 900001 is not above that. The count at the bottom says the rest: **the warehouse will never
hold this order**, and nothing reported a thing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l04-late\" aria-label=\"Order 900001 on a time line. Its updated_at is 23:40 on 2 March, but its transaction commits after the night's extraction has read up to 23:59:47. The next night reads only what is above 23:59:47, so the order falls in a gap neither night reads. A lookback of sixty minutes starts the next window at 22:59:47 and covers it.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30.0 120.0 L690.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M420.0 40.0 L420.0 200.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"420.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">watermark 23:59:47</text><circle cx=\"280.0\" cy=\"120.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"270.0\" y=\"102.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">written: updated_at 23:40</text><path d=\"M286.0 112 C 360.0 50, 480.0 50, 526.0 111\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#st-ah-paper-dim)\"></path><circle cx=\"530.0\" cy=\"120.0\" r=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\"></circle><text x=\"530.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">committed, after the extraction</text><rect x=\"420.0\" y=\"156.0\" width=\"220.0\" height=\"20.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"530.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">night 3 reads from here</text><rect x=\"260.0\" y=\"194.0\" width=\"380.0\" height=\"20.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"450.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">with a 60-minute lookback</text><text x=\"280.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">read by neither night</text></svg>", "caption": "A row becomes visible when it commits, but carries the time it was written. Re-reading the end of the last window is what catches it."}
```

## Reading a little of the past again

The second extraction, the one with `60` on its command line, does not trust the edge of its own
window. It asks for everything above *the watermark minus sixty minutes*, so each night re-reads
the last hour of the night before. On 3 March that hour contained the slow till's order, and the
lookback copy has it.

The price is rows read twice:

```
ana@vm:~/etl$ psql -d wh -c "SELECT count(*) AS rows, count(DISTINCT (order_id, updated_at)) AS versions FROM raw.orders_changes_60m"
 rows  | versions 
-------+----------
 17766 |    17758
(1 row)
```

Eight rows were loaded twice over three nights — the last hour of each night, read again the next.
**A lookback trades duplicates for completeness, and the duplicates are the easy half**: a version
of a row is identified by its key and its `updated_at`, and the next section turns many versions
into one. A missed row has no such remedy.

How long to look back is a judgement about the source: the longest a transaction there can stay
open, with a margin. If the shop's tills give up on a payment after a few minutes, an hour is
generous. A source that runs hour-long batch jobs needs more. Some databases offer an exact answer instead —
PostgreSQL can report the oldest transaction still running — and lesson 5 avoids the question
entirely by reading changes in commit order from the database's own log.
