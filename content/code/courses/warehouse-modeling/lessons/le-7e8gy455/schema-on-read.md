---
title: Schema on read, and what it costs
version: 1
---

A warehouse is **schema on write**: data is checked against the model when it is loaded, and refused if it
does not fit. A lake is **schema on read**: nothing is checked when a file arrives, and every reader
interprets the files in its own way when it reads them.

A week later the website's new version starts writing its export with two small differences: a column
renamed from `customer_id` to `client_id`, and shipping written as the word `free` where it used to be `0`.
The file is made here from the last week of December, so the change can be seen against the old one:

```sql
-- A week later, a file from the website's new version, made here from the
-- last week of December: one column renamed, and shipping written as text.
COPY (SELECT order_id + 1000000 AS order_id, shop_id, customer_id AS client_id,
             ordered_at + INTERVAL 7 DAY AS ordered_at, status,
             CASE WHEN shipping_cents = 0 THEN 'free' ELSE CAST(shipping_cents AS VARCHAR) END
                 AS shipping_cents,
             paid_at + INTERVAL 7 DAY AS paid_at, shipped_at + INTERVAL 7 DAY AS shipped_at,
             delivered_at + INTERVAL 7 DAY AS delivered_at
      FROM read_csv('lake/raw/orders/orders_2025-12-31.csv')
      WHERE ordered_at >= '2025-12-25')
TO 'lake/raw/orders/orders_2026-01-07.csv' (HEADER);
```

```
ana@lab:~/wh$ duckdb < new-export.sql
ana@lab:~/wh$ head -2 lake/raw/orders/orders_2026-01-07.csv
order_id,shop_id,client_id,ordered_at,status,shipping_cents,paid_at,shipped_at,delivered_at
1668353,7,22066,2026-01-01 00:19:38-03,delivered,free,2026-01-01 00:21:32-03,2026-01-05 15:20:07-03,2026-01-07 12:05:50-03
ana@lab:~/wh$ duckdb -c "SELECT count(*) AS orders, sum(shipping_cents) AS shipping FROM read_csv('lake/raw/orders/*.csv')"
Invalid Input Error: Schema mismatch between globbed files.
Main file schema: lake/raw/orders/orders_2025-12-31.csv
Current file: lake/raw/orders/orders_2026-01-07.csv
Column with name: "customer_id" is missing
Column with name: "shipping_cents" is expected to have type: BIGINT But has type: VARCHAR
Potential Fixes 
* Consider setting union_by_name=true.
* Consider setting files_to_sniff to a higher value (e.g., files_to_sniff = -1)

ana@lab:~/wh$ duckdb -c "SELECT count(*) AS orders, count(customer_id) AS with_customer FROM read_csv('lake/raw/orders/*.csv', union_by_name = true)"
┌────────┬───────────────┐
│ orders │ with_customer │
│ int64  │     int64     │
├────────┼───────────────┤
│ 586584 │        430221 │
└────────┴───────────────┘
```

The new file sits beside the old one, and nothing objected when it arrived. The first reader to ask for the
whole folder gets an error that names exactly what happened: a column missing, another of the wrong type.
That is the good outcome. The reader who follows DuckDB's own suggestion, `union_by_name = true`, gets an
answer and no error: 586,584 orders, of which 430,221 have a customer. **Every order of the new week has
lost its customer**, because their customer is now in a column called `client_id` that this query never
mentions.

That is schema on read in one example:

- **The problem is found by the reader, not the writer**, and found late: the file arrived a week ago, and
  the person who could fix it is not the person who found it.
- **Every reader finds it separately**, and decides separately what to do. One fails, one carries on with a
  smaller number, one writes a workaround that the next reader does not know about.

A warehouse would have refused the file at the door, with a message to the people who send it. That is what
schema on write buys, and section 10 shows a lake table getting it back.
