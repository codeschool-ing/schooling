---
title: A load that doubles
version: 1
---

To see whether a step changed anything, Ana needs a way to describe what it left behind that is
short enough to compare by eye and exact enough to miss nothing. Counting rows is short and misses
almost everything. An **md5 of every row, in a fixed order**, misses nothing:

```
-- One day of marts.fact_sales reduced to two values: how many lines, and an md5
-- of all of them in a fixed order. Two runs that leave the same day behind give
-- the same two values; any difference at all, in any column, changes the md5.
SELECT count(*) AS lines,
       md5(string_agg(f::text, '|' ORDER BY order_id, line_no)) AS fingerprint
  FROM marts.fact_sales f
 WHERE order_date = :'day';
```

`f::text` turns each row into one string — every column, in order — and `string_agg` joins them in
the order of the key, so that the same rows always give the same text and the same md5. A changed
value anywhere in the day, a row too many, a row missing: each changes the fingerprint.

Then the naive load of a day's sales. It is lesson 7's `fact_sales.sql` without its first line, the
`DELETE`:

```
-- marts.fact_sales for one day, the naive way: insert the day's lines.
INSERT INTO marts.fact_sales
SELECT o.order_date, o.order_id, l.line_no,
       coalesce(d.customer_key, -1),
       l.book_id, l.quantity, l.line_cents
  FROM staging.orders o
  JOIN staging.order_lines l USING (order_id)
  LEFT JOIN marts.dim_customer d
         ON d.customer_id = o.customer_id
        AND o.ordered_at >= d.valid_from
        AND (o.ordered_at < d.valid_to OR d.valid_to IS NULL)
 WHERE o.order_date = :'day' AND o.is_sale;
```

```
ana@vm:~/etl$ psql -d wh -v day=2026-03-16 -f fingerprint.sql
 lines |           fingerprint            
-------+----------------------------------
   448 | c5aa6b634e10684f652731525f1e420f
(1 row)

ana@vm:~/etl$ psql -q -d wh -v day=2026-03-16 -f load/fact_sales_append.sql
ana@vm:~/etl$ psql -d wh -v day=2026-03-16 -f fingerprint.sql
 lines |           fingerprint            
-------+----------------------------------
   896 | e55dc68e9fb03305a2e57f55ff7afd0d
(1 row)

ana@vm:~/etl$ psql -q -d wh -v day=2026-03-16 -f load/fact_sales_append.sql
ana@vm:~/etl$ psql -d wh -v day=2026-03-16 -f fingerprint.sql
 lines |           fingerprint            
-------+----------------------------------
  1344 | b34f029d164be35d08621e10bd994952
(1 row)
```

Before: 448 lines, loaded by the nightly. One more run of the insert: 896, every line twice. Another:
1,344. Each run did exactly what it was told — insert the day's lines — and each one added the day
again. **Nothing failed, and the sales of the 16th are now three times what the shop sold.** A
report summing `line_cents` would have no reason to doubt it.

This is the most common way a pipeline goes wrong without an error. A retry after a timeout, an
Airflow task cleared to fix something else, a backfill over a range that overlaps last week's: any of
them runs the insert a second time, and the second time is invisible unless somebody counts.
