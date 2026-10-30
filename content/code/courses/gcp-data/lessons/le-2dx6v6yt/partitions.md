---
title: Partitioning, and the three ways to cut a table
version: 1
---

**A partitioned table is one table stored as many pieces, cut by the value of one column, and a
query that names that column in its filter reads only the pieces it needs.** Lesson 14 showed that
on demand bills the bytes of the columns a query reads. Partitioning decides which rows of those
columns it has to read. Together they are the bill: a query that names two columns of a table cut
by day, and asks about one day, pays for two columns of one day. The same query against a table
that is not partitioned pays for two columns of every day the table holds.

**A partition is not an index, and the difference matters for the bill.** An index helps a database
find rows faster and changes nothing about what is charged. A partition changes what BigQuery reads
before the query starts, and so changes the bytes billed, and the dry run of lesson 16 can print
the difference before anything runs. Everything in this section comes from Google's documentation,
"Introduction to partitioned tables" and "Query partitioned tables", and from the pricing page. The
next section practises the same idea on DuckDB.

## Three ways to cut

**By a date or time column**, which is the one Quitanda wants. The table names a column of type
`DATE`, `TIMESTAMP` or `DATETIME`, and a granularity: `DAY`, `HOUR`, `MONTH` or `YEAR`. Every row
goes into the partition of its value, and a row whose value is `NULL` goes into a partition of its
own called `__NULL__`. Quitanda's orders, partitioned by `dt` and by day, would be one partition per
day, exactly the sixty folders of lesson 13.

**By ingestion time**, for data that has no date column worth trusting. BigQuery puts each row in the
partition of the moment it arrived, and exposes it as two pseudo-columns, `_PARTITIONTIME` and
`_PARTITIONDATE`, which a query filters on like any other column. It suits a raw landing table, where
the moment of arrival is the only date that is certain; it is wrong for orders, because a late order
lands in the partition of the day it was loaded and not of the day it was placed.

**By integer range**, for a whole-number column. The table names the column, a start, an end and an
interval, and each interval is a partition: `store_id` from 0 to 100 in tens would make ten. Values
outside the range go into a partition called `__UNPARTITIONED__`. It suits a table queried by a
numeric key with a known range, such as a customer number cut into blocks, and it is the rarest of the
three.

## The table, written down

The DDL for Quitanda's orders, in GoogleSQL, partitioned by day and clustered by store. It is shown
as it would be run and was not run; the clustering line is explained two sections on:

```sql
CREATE TABLE quitanda.orders (
  order_id    STRING NOT NULL,
  customer_id STRING,
  store_id    INT64,
  district    STRING,
  items       INT64,
  total_cents INT64,
  payment     STRING,
  created_at  TIMESTAMP,
  dt          DATE
)
PARTITION BY dt
CLUSTER BY store_id
OPTIONS (require_partition_filter = TRUE, partition_expiration_days = 1095);
```

**`PARTITION BY dt` is the decision**, and the other two kinds would be written
`PARTITION BY _PARTITIONDATE` and `PARTITION BY RANGE_BUCKET(store_id, GENERATE_ARRAY(0, 100, 10))`.
The two options are the guardrails the next section explains: one refuses a query that does not
filter on `dt`, and the other deletes each partition three years after its date.

## What a partition also buys

**A partition is a unit of storage as well as of reading.** Lesson 13 priced the consequence: each
partition goes long-term on its own after 90 days without a write, so a table that receives a new day
every night and never touches the old ones is mostly long-term. **Deleting a partition is free**: the
pricing page lists deleting "individual table partitions" among the free operations, and
`partition_expiration_days` does it on a schedule, with no query and no bill. And a nightly job that
replaces one day's data can overwrite that one partition and leave the other days, and their 90-day
clocks, alone.

**The column chosen has to be the column the questions filter on.** Partitioning by `created_at`
while every report filters on `dt` would read every partition, because the filter does not name the
partitioning column. At Quitanda the two hold the same day, and the reports say `dt`, so `dt` it is.
A table can be partitioned by one column only, which is why the second most common filter goes to
clustering.
