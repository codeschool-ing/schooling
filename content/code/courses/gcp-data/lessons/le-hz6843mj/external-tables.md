---
title: External tables, and querying files where they lie
version: 1
---

**An external table is a table whose data BigQuery does not store.** Its definition names files in
Cloud Storage and a format, and a query against it reads those files at the moment it runs. Nothing is
loaded and nothing is copied: delete a file from the bucket and the next query does not see its rows,
write a new one and the next query does. Lesson 13 loaded Quitanda's orders into a table, and the load
was free while the same orders were then stored twice. An external table is the other choice: the
orders stay in `quitanda-curated-prod`, billed as objects, and BigQuery comes to them.

Everything about BigQuery in this section comes from Google's documentation, "Introduction to external
data sources" and "Query Cloud Storage data", and from the pricing page. None of it was run. The next
section reads the same files back out of the Cloud Storage emulator with a program, which is the part a
laptop can do.

## Defining one

The DDL for the orders as an external table, shown as it would be run and not run:

```sql
CREATE EXTERNAL TABLE quitanda.orders_ext
WITH PARTITION COLUMNS (dt DATE)
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://quitanda-curated-prod/orders/*'],
  hive_partition_uri_prefix = 'gs://quitanda-curated-prod/orders/'
);
```

**`uris` is where the files are**, with a wildcard, and `format` says how to read them: Parquet here,
and the documentation lists CSV, JSON, Avro and ORC among the others. **`WITH PARTITION COLUMNS` and
`hive_partition_uri_prefix` are lesson 13's Hive convention, read by BigQuery**: everything after the
prefix that looks like `dt=2026-09-29/` becomes a value of the column `dt`. A query that filters on `dt`
then skips the folders it rules out, by name, before opening a file, which is the pruning lesson 15
measured on DuckDB. The option `require_hive_partition_filter = true` is the external table's version
of `require_partition_filter`.

## What it gives up

**An external table is slower and more limited than a native one**, and the documentation is direct
about why. BigQuery has to list the objects and read each file's own metadata at query time, where a
native table has its metadata ready; it reads Parquet, not its own storage format; and it cannot use
the statistics it keeps for its own tables. **Clustering is not available**, since BigQuery does not
arrange the files. The results of a query on an external table are not cached the way native results
are. And whatever writes the files decides the layout: a job that writes a thousand small files a day
makes every query open a thousand files, and BigQuery cannot fix it from its side.

**What it gains is that the data has one home.** The files the nightly export writes are the table,
with no load step between them that can fail, lag or double the storage. Other engines can read the
same files: Spark on Dataproc in lesson 23, DuckDB on a laptop in this one. That is the argument for
the lake that lessons 1 to 5 built, and an external table is how the warehouse joins it without
owning it.

## How it is billed

**On demand, a query on an external table is billed per TiB like any other**, at the same 11.25 USD in
`southamerica-east1`, by the bytes the query reads from the files. For a columnar format such as
Parquet, that means the columns the query names, in the files its partition filter keeps; for CSV or
JSON, where a column cannot be read without its row, it means whole files. Google's documentation of
external data sources says how the bytes are counted for each format, and the habit of lesson 16
applies unchanged: name the columns, filter the partitions.

**The storage is Cloud Storage's, at Cloud Storage's prices.** The files are billed as objects in their
class, 0.035 USD per GiB-month for Standard in São Paulo, on `cloud.google.com/storage/pricing`, read
2026-10-30. And the pricing page of BigQuery adds the rule that matters most over years: "Long-term
storage pricing applies only to BigQuery storage, not to data stored in external data sources such as
Bigtable, Cloud Storage, and Google Drive." A file nobody has touched for a year is cheaper in BigQuery
than in a Standard bucket, unless a life-cycle rule from lesson 3 moves it to a colder class. The last
section of this lesson puts the two side by side.
