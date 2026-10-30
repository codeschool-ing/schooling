---
title: What a table weighs, in logical bytes
version: 1
---

**BigQuery does not measure a table by the size of its files.** It cannot, because a file is
something its storage arranges and you never see. It measures a table by **adding up the size of
every value in it, by the value's type**, as if nothing were compressed: an `INT64` is 8 bytes
whether it holds 7 or 7 billion, and a `STRING` is 2 bytes plus its length in UTF-8. That total is
the table's **logical size**, and it is the number two of the three bills in this course are worked
out from: the logical storage bill of the next section, and the on-demand query bill of lesson 14.

## The size of each type

The pricing page sends you to a table in BigQuery's documentation, "Data type sizes", for the rule.
These are the rows Quitanda's table uses, and the ones you are most likely to meet next:

| type | logical size of one value |
|---|---|
| `INT64` | 8 bytes |
| `FLOAT64` | 8 bytes |
| `NUMERIC` | 16 bytes |
| `BOOL` | 1 byte |
| `STRING` | 2 bytes + its UTF-8 length |
| `BYTES` | 2 bytes + its length |
| `DATE`, `TIMESTAMP`, `DATETIME`, `TIME` | 8 bytes |
| `ARRAY`, `STRUCT` | the sizes of what they contain |
| `NULL`, of any type | 0 bytes |

**A fixed-width type costs the same for every value**, so a column of `INT64` in a table of a
million rows is 8,000,000 bytes, always. **A `STRING` costs what it holds**, and "what it holds" is
counted in UTF-8 bytes, not in characters, which in Portuguese is not the same thing.

## The districts, counted

Quitanda's eight districts are the cleanest place to see it. DuckDB's `length` counts characters and
its `strlen` counts bytes, which is the measure BigQuery uses:

```
ana@laptop:~/gcp$ python3 ask.py "SELECT DISTINCT district, length(district) AS characters, strlen(district) AS utf8_bytes, 2 + strlen(district) AS bigquery_bytes FROM orders ORDER BY district"
┌──────────────┬────────────┬────────────┬────────────────┐
│   district   │ characters │ utf8_bytes │ bigquery_bytes │
│   varchar    │   int64    │   int64    │     int64      │
├──────────────┼────────────┼────────────┼────────────────┤
│ Butantã      │          7 │          8 │             10 │
│ Lapa         │          4 │          4 │              6 │
│ Moema        │          5 │          5 │              7 │
│ Mooca        │          5 │          5 │              7 │
│ Pinheiros    │          9 │          9 │             11 │
│ Santana      │          7 │          7 │              9 │
│ Tatuapé      │          7 │          8 │             10 │
│ Vila Mariana │         12 │         12 │             14 │
└──────────────┴────────────┴────────────┴────────────────┘
```

**`Butantã` and `Tatuapé` are seven characters and eight bytes**, because `ã` and `é` each take two
bytes in UTF-8, so BigQuery counts each of them as 10 bytes. `Vila Mariana` is the longest name and
costs 14. In a table of a million orders, the district column weighs whatever mix of those eight
numbers the orders happen to have, and the only way to know it is to add it up.

## The whole table, column by column

**The same rule, applied to every column, is a single query.** Each string column is the sum of 2 +
its length, and each fixed-width column is 8 times the number of rows. `dt` counts too, because once
the table is loaded it is a `DATE` column like any other. Save this as `~/gcp/logical.sql`:

`logical.sql`:

```sql
WITH sizes AS (
    SELECT
        sum(2 + strlen(order_id))    AS order_id,
        sum(2 + strlen(customer_id)) AS customer_id,
        8 * count(*)                 AS store_id,
        sum(2 + strlen(district))    AS district,
        8 * count(*)                 AS items,
        8 * count(*)                 AS total_cents,
        sum(2 + strlen(payment))     AS payment,
        8 * count(*)                 AS created_at,
        8 * count(*)                 AS dt
    FROM orders
)
SELECT coalesce(column_name, 'all nine') AS column_name,
       sum(logical_bytes)                AS logical_bytes
FROM (UNPIVOT sizes ON COLUMNS(*) INTO NAME column_name VALUE logical_bytes)
GROUP BY ROLLUP (column_name)
ORDER BY logical_bytes;
```

**`UNPIVOT` turns the one wide row into one row per column**, and `ROLLUP` adds the total as a last
row with no name, which `coalesce` calls `all nine`. Neither is GoogleSQL you would need; they are
there so the answer fits on a screen:

```
ana@laptop:~/gcp$ python3 ask.py logical.sql
┌─────────────┬───────────────┐
│ column_name │ logical_bytes │
│   varchar   │    int128     │
├─────────────┼───────────────┤
│ payment     │       6723152 │
│ store_id    │       9960944 │
│ total_cents │       9960944 │
│ items       │       9960944 │
│ created_at  │       9960944 │
│ dt          │       9960944 │
│ customer_id │      11206062 │
│ district    │      11521750 │
│ order_id    │      19921888 │
│ all nine    │      99177572 │
└─────────────┴───────────────┘
  10 rows           2 columns
```

**The table weighs 99,177,572 logical bytes**, about 94.6 MiB or 0.092 GiB. The five fixed-width
columns weigh exactly the same, 9,960,944 bytes each, which is 8 × 1,245,118. The heaviest column is
`order_id`, at 19,921,888 bytes: fourteen characters and two bytes of overhead on every row, so 16
bytes a row, twice the weight of a number. `payment` is the lightest, because `pix` and `card` are
short words.

## Logical against the files on disk

**The Parquet files holding the same rows are a third of that size**:

```
ana@laptop:~/gcp$ du -cb warehouse/orders/*/*.parquet | tail -1
32451790	total
```

**99,177,572 logical bytes against 32,451,790 on disk is a ratio of 3.06.** Parquet compresses each
column apart, and these columns compress well: `district` has eight values and `store_id` sixteen, so
each is mostly repetition, and the timestamps of a day are in order. BigQuery's own format does the
same kind of thing, and its stored size is what Google calls the table's **physical** bytes. Nothing
in this lab can measure that number, because nothing here is BigQuery's storage. What the Parquet
files give you is a fair idea of how compressible these columns are, and the next section shows why
that ratio, roughly three, is precisely the number on which the choice between logical and physical
billing turns.

**The logical size is also the size a query is billed by.** On demand, BigQuery bills the logical
bytes of the columns a query reads, in the partitions it reads. A query that adds up `total_cents`
over the whole table touches 9,960,944 bytes of it, and one that reads `SELECT *` touches all
99,177,572. Lesson 14 prices that, and lesson 16 adds the two rules this section has left out: every
query is rounded up to the next MB, and no table referenced is billed for less than 10 MB.
