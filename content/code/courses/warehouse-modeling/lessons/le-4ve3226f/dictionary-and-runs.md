---
title: Dictionaries and runs
version: 1
---

Look at what each column of `fact_sales` holds:

```sql
-- A column with few distinct values, and one with many.
SELECT count(DISTINCT shop_key) AS shops, count(DISTINCT order_id) AS orders,
       count(*) AS rows
FROM fact_sales;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < dictionary.sql
┌───────┬────────┬────────┐
│ shops │ orders │  rows  │
│ int64 │ int64  │ int64  │
├───────┼────────┼────────┤
│     7 │ 572439 │ 887477 │
└───────┴────────┴────────┘
```

887,477 rows, and `shop_key` has seven different values in all of them. A column like that wastes most of
its bytes saying the same few things again and again, and two encodings exploit it.

**Dictionary encoding.** Write the distinct values once, in a dictionary, and replace each value in the
column with its position in the dictionary. Seven shops need positions 0 to 6, which fit in three bits,
so each row of the column costs three bits instead of eight bytes. Parquet uses a dictionary on nearly
every column by default, and the encodings it chose are in its metadata as `PLAIN_DICTIONARY`.

**Run-length encoding**, RLE. Where the same value repeats in consecutive rows, write it once with the
number of times it repeats, instead of every copy. It only works when equal values sit together, which
depends on the order of the rows.

DuckDB chose an encoding for each column of its own copy, one segment at a time:

```sql
-- How DuckDB compressed each column of its own fact_sales.
SELECT column_name, compression, count(*) AS segments
FROM pragma_storage_info('fact_sales')
WHERE segment_type <> 'VALIDITY'
GROUP BY ALL
ORDER BY column_name, segments DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < compression.sql
┌────────────────┬─────────────┬──────────┐
│  column_name   │ compression │ segments │
│    varchar     │   varchar   │  int64   │
├────────────────┼─────────────┼──────────┤
│ book_key       │ BitPacking  │        8 │
│ customer_key   │ BitPacking  │        8 │
│ date_key       │ RLE         │        8 │
│ discount_cents │ BitPacking  │        4 │
│ discount_cents │ RLE         │        4 │
│ gross_cents    │ BitPacking  │        8 │
│ line_no        │ BitPacking  │        8 │
│ net_cents      │ BitPacking  │        8 │
│ order_id       │ BitPacking  │        8 │
│ promotion_key  │ BitPacking  │        7 │
│ promotion_key  │ RLE         │        1 │
│ quantity       │ BitPacking  │        8 │
│ shop_key       │ BitPacking  │        8 │
└────────────────┴─────────────┴──────────┘
  13 rows                       3 columns
```

**`date_key` is RLE in every segment.** The table was loaded in order of order number, the order numbers
rise with time, and so every day's sales sit together in one run. `discount_cents` is RLE in half its
segments, because most lines have no discount and the zeros come in runs; the other half, where promotions
were running, are bit-packed. Every other column is **bit-packed**, which is the next section.

DuckDB makes the choice per segment, by trying the encodings and keeping the smallest. Nobody declared any of
it, and that is typical of columnar engines: the encodings are an implementation detail the reader never
has to name, and they adapt to the data.
