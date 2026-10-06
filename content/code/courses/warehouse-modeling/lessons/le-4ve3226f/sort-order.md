---
title: The order of the rows matters
version: 1
---

Run-length encoding only works when equal values are next to each other, and dictionary and bit-packing work
better when nearby values are close. So the order in which rows are written changes how small a column
gets. Write the same rows in three orders: shuffled, as they were loaded, and sorted by shop and date:

```sql
-- The same rows in three orders: shuffled, as loaded, and sorted by shop and date.
COPY (SELECT * FROM fact_sales ORDER BY hash(order_id, line_no)) TO 'shuffled.parquet';
COPY (SELECT * FROM fact_sales ORDER BY order_id, line_no)       TO 'by_order.parquet';
COPY (SELECT * FROM fact_sales ORDER BY shop_key, date_key)      TO 'by_shop_date.parquet';

SELECT file_name,
       sum(total_compressed_size) FILTER (WHERE path_in_schema = 'shop_key') AS shop_key_bytes,
       sum(total_compressed_size) FILTER (WHERE path_in_schema = 'date_key') AS date_key_bytes,
       sum(total_compressed_size)                                            AS all_columns
FROM parquet_metadata(['shuffled.parquet', 'by_order.parquet', 'by_shop_date.parquet'])
GROUP BY file_name ORDER BY all_columns DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < order.sql
┌──────────────────────┬────────────────┬────────────────┬─────────────┐
│      file_name       │ shop_key_bytes │ date_key_bytes │ all_columns │
│       varchar        │     int128     │     int128     │   int128    │
├──────────────────────┼────────────────┼────────────────┼─────────────┤
│ shuffled.parquet     │         337262 │        1136811 │    13403406 │
│ by_order.parquet     │         311035 │           5602 │     9331332 │
│ by_shop_date.parquet │            524 │          34696 │     9317594 │
└──────────────────────┴────────────────┴────────────────┴─────────────┘
```

The same 887,477 rows, three files:

- **Shuffled**, 13,403,406 bytes. Every column is as scattered as it can be.
- **In order of order number**, as the warehouse loaded them, 9,331,332 bytes. `date_key` drops from
  1,136,811 bytes to 5,602, because dates rise with order numbers and a day's sales sit together.
- **Sorted by shop and date**, about the same total, and `shop_key` takes **524 bytes**: seven runs, one per
  shop, for the whole column.

**Sorting moved the total by about 30%, and a single column by a factor of six hundred.** A warehouse that
loads in date order gets most of that for free, because new data arrives in date order. The rest is a choice:
sorting by the columns that queries filter on most compresses them best, and the next section shows that it
also lets a reader skip most of the file.

Cloud warehouses expose the same decision under different names: a **sort key** in Redshift, a **clustering
key** in Snowflake and BigQuery. Lesson 9 shows each.
