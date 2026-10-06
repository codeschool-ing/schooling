---
title: A rename, measured three ways
version: 1
---

Take the most extreme denormalisation there is: every sale, with every attribute of every dimension
written on its row. **One big table**, OBT for short:

```sql
-- One big table: every sale with every attribute of its dimensions on the row.
CREATE TABLE sales_wide AS
SELECT f.order_id, f.line_no, f.quantity, f.gross_cents, f.discount_cents, f.net_cents,
       d.date, d.year, d.month, d.month_name, d.day_name, d.is_weekend, d.is_holiday,
       s.shop_name, s.city AS shop_city, s.state AS shop_state, s.region, s.channel,
       b.isbn, b.title, b.authors, b.format, b.category, b.subcategory, b.department,
       b.publisher,
       c.tier, c.city AS customer_city, c.state AS customer_state,
       p.code AS promotion_code, p.promotion_name
FROM fact_sales f
JOIN dim_date d      USING (date_key)
JOIN dim_shop s      USING (shop_key)
JOIN dim_book b      USING (book_key)
JOIN dim_customer c  USING (customer_key)
JOIN dim_promotion p USING (promotion_key);
```

```
ana@lab:~/wh$ duckdb wh.duckdb < obt.sql
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT count(*) AS rows, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'sales_wide') AS columns FROM sales_wide"
┌────────┬─────────┐
│  rows  │ columns │
│ int64  │  int64  │
├────────┼─────────┤
│ 887477 │      31 │
└────────┴─────────┘
```

887,477 rows, 31 columns, and no joins left for anybody to write. Now suppose the shop renames the
department *Non-fiction* to *Nonfiction*. Where does that write?

```sql
-- The department "Non-fiction" is renamed "Nonfiction". Where does that write?
SELECT (SELECT count(*) FROM sf_department_demo WHERE department = 'Non-fiction') AS snowflake_rows,
       (SELECT count(*) FROM dim_book WHERE department = 'Non-fiction')            AS star_rows,
       (SELECT count(*) FROM sales_wide WHERE department = 'Non-fiction')          AS wide_rows;
```

```
ana@lab:~/wh$ duckdb wh.duckdb -c "CREATE TABLE sf_department_demo AS SELECT DISTINCT department FROM dim_book"
ana@lab:~/wh$ duckdb wh.duckdb < rename.sql
┌────────────────┬───────────┬───────────┐
│ snowflake_rows │ star_rows │ wide_rows │
│     int64      │   int64   │   int64   │
├────────────────┼───────────┼───────────┤
│              1 │      1185 │    375294 │
└────────────────┴───────────┴───────────┘
```

**One row in a normalised department table. 1,185 rows in the star's `dim_book`. 375,294 rows in the
wide table.** The star repeats the name once per book, which the load rewrites without noticing. The
wide table repeats it once per sale, and a rename becomes an operation on nearly half of the biggest
table in the warehouse.

Now suppose that operation is interrupted. The update has rewritten 2025 and not yet reached 2024:

```sql
-- The rename, interrupted halfway: 2025 has been rewritten and 2024 not yet.
BEGIN;
UPDATE sales_wide SET department = 'Nonfiction'
WHERE department = 'Non-fiction' AND year = 2025;

SELECT year, department, count(*) AS lines
FROM sales_wide WHERE department IN ('Non-fiction', 'Nonfiction')
GROUP BY ALL ORDER BY ALL;
ROLLBACK;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < half-update.sql
┌───────┬─────────────┬────────┐
│ year  │ department  │ lines  │
│ int64 │   varchar   │ int64  │
├───────┼─────────────┼────────┤
│  2024 │ Non-fiction │ 168480 │
│  2025 │ Nonfiction  │ 206814 │
└───────┴─────────────┴────────┘
```

There is the update anomaly from section 02, alive in a warehouse: one department under two names, and
every report grouped by department showing two rows for it, split by year. The transaction rolled it
back, so the table is whole again. A load that updated in place without one, or a person fixing a
name by hand, would have left it like that.

**This is the real cost of the wide table, and it is not storage.** The wide table is a derived copy,
and the safe way to change it is to rebuild it from the star. Treated that way, it is a convenience.
Edited in place, it is a table with all of normalisation's anomalies and none of its defences.
