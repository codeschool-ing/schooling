---
title: Three kinds of fact table
version: 1
---

`fact_sales` and `fact_inventory` are built differently, and not by accident. Kimball names three
kinds of fact table, and every business process fits one of them. Which one it is follows from how
the process happens in time.

| kind | one row per | written | example here |
|---|---|---|---|
| **transaction** | event | once, when it happens | `fact_sales` |
| **periodic snapshot** | thing, per period | once per period | `fact_inventory` |
| **accumulating snapshot** | thing with a lifecycle | when it starts, then updated at each step | `fact_fulfilment`, below |

The first two are already built. A transaction table grows with activity: a busy December adds more
rows than a quiet February. A periodic snapshot grows with the calendar: every shop's shelves are
counted at the end of every month whether anything sold or not, and a month with no movement still
gets its rows.

## The accumulating snapshot

The online shop's orders go through steps: ordered, paid, shipped, delivered. The manager wants to
know how long each step takes, and which parcels are still on the road. That is a process with a
**beginning, a known list of milestones and an end**, and it gets one row per order, with a date for
each milestone:

```sql
-- Grain: one row per online order, updated as it moves. A milestone not
-- reached yet points at the 'Not yet' date, key 0.
CREATE TABLE fact_fulfilment AS
SELECT o.order_id,
       CAST(strftime(o.ordered_at, '%Y%m%d') AS INTEGER)                  AS ordered_date_key,
       coalesce(CAST(strftime(o.paid_at, '%Y%m%d') AS INTEGER), 0)        AS paid_date_key,
       coalesce(CAST(strftime(o.shipped_at, '%Y%m%d') AS INTEGER), 0)     AS shipped_date_key,
       coalesce(CAST(strftime(o.delivered_at, '%Y%m%d') AS INTEGER), 0)   AS delivered_date_key,
       o.status,
       date_diff('day', CAST(o.ordered_at AS DATE), CAST(o.shipped_at AS DATE))   AS days_to_ship,
       date_diff('day', CAST(o.ordered_at AS DATE), CAST(o.delivered_at AS DATE)) AS days_to_deliver
FROM staging.orders o
JOIN staging.shops sh USING (shop_id)
WHERE sh.channel = 'online' AND o.status <> 'cancelled';
```

```
ana@lab:~/wh$ duckdb wh.duckdb < fact_fulfilment.sql
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT * FROM fact_fulfilment WHERE order_id IN (100001, 676352)"
┌──────────┬──────────────────┬───────────────┬──────────────────┬────────────────────┬───────────┬──────────────┬─────────────────┐
│ order_id │ ordered_date_key │ paid_date_key │ shipped_date_key │ delivered_date_key │  status   │ days_to_ship │ days_to_deliver │
│  int64   │      int32       │     int32     │      int32       │       int32        │  varchar  │    int64     │      int64      │
├──────────┼──────────────────┼───────────────┼──────────────────┼────────────────────┼───────────┼──────────────┼─────────────────┤
│   100001 │         20240101 │      20240101 │         20240102 │           20240104 │ delivered │            1 │               3 │
│   676352 │         20251230 │      20251230 │         20251231 │                  0 │ shipped   │            1 │            NULL │
└──────────┴──────────────────┴───────────────┴──────────────────┴────────────────────┴───────────┴──────────────┴─────────────────┘
```

Order 100001 went through every step in three days. Order 676352 was ordered on 30 December 2025,
shipped the next day, and had not been delivered when the data ends: its `delivered_date_key` is 0,
the *Not yet* row of `dim_date`. **When it arrives, the load updates this row**: the delivery date
gets its key and `days_to_deliver` its number. That is the one kind of fact row that is updated, and
it is updated only to fill in a milestone.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"One row of fact_fulfilment for order 676352, shown as it stands after each load. After the load of 30 December 2025: ordered and paid on the 30th, shipped and delivered not yet. After the load of 31 December: shipped on the 31st, delivered still not yet. After a later load, the delivery date would be filled in the same row. The row is updated in place; no new row is added.\"><defs><marker id=\"ah-accumulating\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"300\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">ordered</text><text x=\"415\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">paid</text><text x=\"530\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">shipped</text><text x=\"645\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">delivered</text><text x=\"20\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">load of 30 Dec</text><text x=\"20\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">row inserted</text><rect x=\"250\" y=\"60\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20251230</text><rect x=\"365\" y=\"60\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20251230</text><rect x=\"480\" y=\"60\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"530\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0 · Not yet</text><rect x=\"595\" y=\"60\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"645\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0 · Not yet</text><line x1=\"180\" y1=\"100\" x2=\"180\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-accumulating)\"></line><text x=\"20\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">load of 31 Dec</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">same row, updated</text><rect x=\"250\" y=\"130\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20251230</text><rect x=\"365\" y=\"130\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20251230</text><rect x=\"480\" y=\"130\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20251231</text><rect x=\"595\" y=\"130\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"645\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0 · Not yet</text><line x1=\"180\" y1=\"170\" x2=\"180\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-accumulating)\"></line><text x=\"20\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a later load</text><text x=\"20\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">same row, updated</text><rect x=\"250\" y=\"200\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20251230</text><rect x=\"365\" y=\"200\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20251230</text><rect x=\"480\" y=\"200\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20251231</text><rect x=\"595\" y=\"200\" width=\"100\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"645\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026…</text></svg>", "caption": "An accumulating snapshot: one row per order, filled in as each milestone is reached."}
```

The question it was built for:

```sql
SELECT d.year, d.month_name,
       count(*)                          AS orders,
       round(avg(f.days_to_ship), 1)     AS avg_days_to_ship,
       round(avg(f.days_to_deliver), 1)  AS avg_days_to_deliver,
       count(*) FILTER (WHERE f.delivered_date_key = 0) AS not_delivered_yet
FROM fact_fulfilment f
JOIN dim_date d ON d.date_key = f.ordered_date_key
WHERE d.month IN (11, 12)
GROUP BY ALL ORDER BY d.year, d.month_name DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < lead-times.sql
┌───────┬────────────┬────────┬──────────────────┬─────────────────────┬───────────────────┐
│ year  │ month_name │ orders │ avg_days_to_ship │ avg_days_to_deliver │ not_delivered_yet │
│ int64 │  varchar   │ int64  │      double      │       double        │       int64       │
├───────┼────────────┼────────┼──────────────────┼─────────────────────┼───────────────────┤
│  2024 │ November   │  12078 │              2.4 │                 6.5 │                 0 │
│  2024 │ December   │  17504 │              2.1 │                 6.2 │                 0 │
│  2025 │ November   │  16490 │              2.3 │                 6.4 │                 0 │
│  2025 │ December   │  20054 │              2.2 │                 6.2 │              4071 │
└───────┴────────────┴────────┴──────────────────┴─────────────────────┴───────────────────┘
```

Despatch took about two days and delivery about six, in both Christmas seasons. And 4,071 orders of
December 2025 were still on the way when the data ends. **A transaction table could answer the first
two numbers with some effort; only the snapshot answers the third directly**, because the open
orders are rows, rather than an absence of rows.

Three tables, three shapes of time. Getting the kind wrong is easy to see afterwards. A stock table
built as transactions has no row for a book that did not move, so it cannot say what was on the shelf.
A fulfilment table built as transactions has one row per milestone, and every lead-time question
becomes a self-join.
