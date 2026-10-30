---
title: BigLake, connections and a cache of metadata
version: 1
---

**A BigLake table is an external table that BigQuery reads with its own identity instead of yours.**
With a plain external table, whoever runs the query needs permission to read the files in the bucket,
so granting an analyst a table means granting them the bucket as well, every file in it, through any
tool. A BigLake table goes through a **connection**: a resource in BigQuery with a service account of
its own, and it is that service account that is granted the bucket. The analyst is granted the table,
and never touches Cloud Storage. Everything in this section is from Google's documentation of BigLake
and of its connections, and none of it was run.

## A connection, and the table on it

The connection is created once, per region. On Google Cloud, as you would type it and not run here:

```sh
bq mk --connection --location=southamerica-east1 --project_id=planner-dev \
  --connection_type=CLOUD_RESOURCE quitanda-lake
bq show --connection planner-dev.southamerica-east1.quitanda-lake
```

**`CLOUD_RESOURCE` is the kind of connection that reaches Cloud Storage**, and `bq show` would print the
service account Google created for it. That account is then granted read access on
`quitanda-curated-prod`, the IAM step `gcp-foundations` taught, and it is the only identity that ever
reads the files. The table names the connection:

```sql
CREATE EXTERNAL TABLE quitanda.orders_lake
WITH PARTITION COLUMNS (dt DATE)
WITH CONNECTION `planner-dev.southamerica-east1.quitanda-lake`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://quitanda-curated-prod/orders/*'],
  hive_partition_uri_prefix = 'gs://quitanda-curated-prod/orders/',
  max_staleness = INTERVAL 4 HOUR,
  metadata_cache_mode = 'AUTOMATIC'
);
```

**`WITH CONNECTION` is the whole difference in the DDL**, and it changes what can be enforced. Because
BigQuery reads the files on the user's behalf, it can filter what it returns: the documentation lists
**row-level security** and **column-level security** with data masking for BigLake tables, the same
controls a native table has. An analyst can be given the orders of their own district, or the orders
without `customer_id`, and no tool they hold can read around it, because they have no access to the
files to read around it with.

## The metadata cache

**The slowest part of querying files is finding out what is in them**, and the last section measured
it: every file's footer read before a byte of data, and every object listed before any file is opened.
A BigLake table can **cache that metadata** in BigQuery: the list of files, and the statistics in their
footers, including the minimum and maximum of each column that lesson 15 used to skip row groups.

**`max_staleness` says how old the cache may be before a query refuses to trust it**, and
`metadata_cache_mode` says who refreshes it. `AUTOMATIC` lets BigQuery refresh it on its own schedule;
`MANUAL` leaves it to a call of the system procedure `BQ.REFRESH_EXTERNAL_METADATA_CACHE`, which a job
runs after it writes new files. A query run within the staleness uses the cached list and statistics
and skips the listing and the footers; a query run after it reads the files as a plain external table
would. The documentation sets the range of staleness a table may declare and the details of the
automatic schedule.

**The price of the cache is that the table may be behind the bucket.** With four hours of staleness, a
file written at nine is not seen by a nine-thirty query that uses the cache. For Quitanda's nightly
export, written once at three in the morning and refreshed manually by the job that writes it, that is
no cost at all; for a bucket that receives files every minute, it is the question to answer first.

## BigLake against a native table

**BigLake closes most of the gap with a native table and keeps the one thing a native table cannot
offer**: the data stays in open files, in a bucket the company owns, readable by other engines. What
it does not close is the storage: the files are still billed as Cloud Storage objects, with no
long-term discount from BigQuery, and the layout is still whatever the writer made. A table the
warehouse queries a thousand times a day, from data nothing else reads, is cheaper and faster as a
native table; a table several engines share, governed in one place, is what BigLake is for.
