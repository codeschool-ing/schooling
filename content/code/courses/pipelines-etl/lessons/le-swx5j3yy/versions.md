---
title: Many versions, one row
version: 1
---

An incremental extraction does not deliver a table. **It delivers a stream of versions**: every
time a row changes, a new copy of it arrives with a new `updated_at`. Ana's raw table keeps all of
them, appended, never updated:

```
ana@vm:~/etl$ psql -d wh -c "SELECT order_id, status, updated_at, extracted_at FROM raw.orders_changes WHERE order_id IN (SELECT order_id FROM raw.orders_changes GROUP BY order_id HAVING count(*) > 1) ORDER BY order_id, updated_at LIMIT 4"
 order_id |  status   |       updated_at       |         extracted_at          
----------+-----------+------------------------+-------------------------------
   113697 | completed | 2026-02-17 19:27:23-03 | 2026-10-07 00:17:18.140091-03
   113697 | refunded  | 2026-03-03 17:17:14-03 | 2026-10-07 00:17:20.763591-03
   114178 | completed | 2026-02-19 15:57:06-03 | 2026-10-07 00:17:18.140091-03
   114178 | refunded  | 2026-03-03 10:34:33-03 | 2026-10-07 00:17:20.763591-03
(4 rows)
```

Order 113697 was placed on 17 February and refunded on 3 March. The first night's extraction
loaded it as completed; the third night's loaded it again as refunded. **Both rows are true**: each
is what the shop said at the moment it was read, and the `extracted_at` column records that moment
— in the machine's own clock, which is October, while the shop's data lives in March.

Keeping every version is the raw layer doing its job from lesson 2: the history of what was seen is
there for an audit, a debugging session or a bug fix. But most readers want one row per order, the
latest, and that is one query:

```
-- The latest version of each order the extraction has seen.
CREATE OR REPLACE VIEW raw.orders_latest AS
SELECT DISTINCT ON (order_id) *
  FROM raw.orders_changes
 ORDER BY order_id, updated_at DESC, extracted_at DESC;
```

`DISTINCT ON (order_id)` keeps the first row of each order in the order the `ORDER BY` gives —
newest `updated_at` first, and if the lookback has delivered the same version twice, the one
extracted last. Comparing it with the shop:

```
ana@vm:~/etl$ psql -q -d wh -f latest.sql
ana@vm:~/etl$ psql -d wh -c "SELECT (SELECT count(*) FROM raw.orders_changes) AS versions, (SELECT count(*) FROM raw.orders_latest) AS orders"
 versions | orders 
----------+--------
    17757 |  17749
(1 row)

ana@vm:~/etl$ psql -c "SELECT count(*) AS orders FROM orders WHERE updated_at <= '2026-03-03 23:59:59-03'"
 orders 
--------
  17750
(1 row)
```

Seventeen thousand seven hundred and fifty-seven versions collapse to 17,749 orders. The shop has
17,750 orders updated up to the end of 3 March. **The missing one is 900001**, the slow till's
order: this view is built on the extraction without a lookback, and that extraction never saw it.
A count compared against the source is the cheapest check there is, and it just found the bug the
last section described.

## A view, not a table

`raw.orders_latest` is a view, so it is recomputed every time it is read and is never out of date
with the versions underneath it. When that becomes slow, the latest state is kept in a table that
each load updates by key instead — an *upsert*, which is lesson 7's subject, together with the
slowly changing dimension that keeps the versions on purpose.
