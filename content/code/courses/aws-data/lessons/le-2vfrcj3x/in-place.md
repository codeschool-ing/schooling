---
title: Athena reads the files where they lie
version: 1
---

**Athena is SQL over files that stay in S3.** Nothing is loaded into it, and nothing is stored in
it: there is no disk of Athena's to fill, no instance to size and no cluster to leave running. A
query names a table, the table names a prefix in S3 and a file format, and Athena's engine reads
the objects under that prefix at the moment the query runs. When it finishes, the files are exactly
as they were, and the answer is written as a file of its own to a prefix you chose.

The picture most people arrive with is the opposite one: a warehouse you load the data into, like
the Redshift of lesson 14. That picture leads to two mistakes. One is looking for a place to put
the data, when the data is already where it belongs. The other is the expensive one, and it is the
subject of this lesson: **Athena is billed by the bytes it reads, not by the time it runs or the
rows it returns.** A query that reads a whole bucket to count ten rows pays for the bucket.

## A table is a description, not a container

An Athena table is a few lines in the Glue Data Catalog, which lesson 16 opens: the columns and
their types, the format of the files, where they live, and the columns that come from the key
rather than from the file. For the orders this lesson writes, the description is this file:

`orders.sql`:

```sql
CREATE EXTERNAL TABLE quitanda.orders (
  order_id      string,
  customer_id   string,
  hour          tinyint,
  items         smallint,
  total_cents   bigint,
  payment       string,
  neighbourhood string
)
PARTITIONED BY (dt string)
STORED AS PARQUET
LOCATION 's3://quitanda-curated-prod/orders/'
```

**`EXTERNAL` means the data is not the table's.** Dropping the table deletes the description and
leaves every object in S3 where it is. `PARTITIONED BY (dt string)` says that `dt` is not a column
inside the files at all: it is read from the key, from the `dt=2026-10-01/` that lesson 1 put in
every path for exactly this reason. And `STORED AS PARQUET` names the format, which is the decision
the rest of this lesson prices.

A partition has to be known to the catalog before Athena reads it. A new day's file, written
tonight, is invisible to every query until its partition is added. `MSCK REPAIR TABLE` walks the prefix and registers what it finds, an `ALTER TABLE … ADD PARTITION` names one, a crawler does it on a schedule, and the projection at the end of this lesson makes it unnecessary. That is the most common
surprise of a first week with Athena, a file that is plainly in the bucket and a query that does
not see it.

## What moto does with it

Sent to moto, the statement does what lesson 1's query did:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-athena-results-prod
make_bucket: quitanda-athena-results-prod
ana@laptop:~/aws$ aws athena start-query-execution --query-string file://orders.sql --result-configuration OutputLocation=s3://quitanda-athena-results-prod/
{
    "QueryExecutionId": "5d04099c-fed5-4816-a1f2-e26a5321bdf7"
}
ana@laptop:~/aws$ aws athena get-query-execution --query-execution-id 5d04099c-fed5-4816-a1f2-e26a5321bdf7 --query 'QueryExecution.[StatementType,Status.State]' --output text
DDL	SUCCEEDED
ana@laptop:~/aws$ aws glue get-databases
{
    "DatabaseList": []
}
```

**`DDL` and `SUCCEEDED`, and the catalog is empty.** Athena would have refused the statement,
because there is no database called `quitanda` yet, and with one it would have written a table into
the catalog. moto did neither: it read the statement far enough to call it DDL, marked it done and
kept nothing. The same is true of every
`SELECT` this lesson asks, so from here on the questions go to DuckDB, an engine that runs inside a
Python program, reading the same objects in moto's S3 that Athena would read. **Every answer below
is DuckDB's, and every byte count is what DuckDB read**; where Athena behaves differently, the
lesson says so.

## The price is one line

```
ana@laptop:~/aws$ python3 prices.py athena
AWS public price list, sa-east-1, USD, excluding tax

Athena, USD
  SQL queries, per TB scanned                           9.00000  TB
```

**Nine dollars a terabyte read, in São Paulo**, and the rest of the bill is in the rules around
that number, from Athena's pricing page:

- the bytes are rounded up to a whole megabyte, with **10 MB as the least any query costs**;
- the bytes are the ones read from S3, compressed, so a compressed file costs its compressed size;
- statements that only change the catalog, such as `CREATE TABLE` or `ADD PARTITION`, cost
  nothing, and neither does a query that fails;
- a query you cancel costs what it had read when it stopped.

The answer Athena writes to the results prefix is an ordinary object, billed as S3 storage, and the
reads it makes are ordinary GET requests, billed at the price the S3 block of the sheet prints. Athena also sells
capacity by the hour, for teams whose queries are predictable enough to reserve it; this course
prices the per-terabyte way, which is the default and the one a first lake pays.
