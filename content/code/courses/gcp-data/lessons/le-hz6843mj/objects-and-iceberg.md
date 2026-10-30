---
title: Object tables and Iceberg
version: 1
---

**Two more kinds of table read Cloud Storage, and each solves a problem the Parquet table of the last
two sections does not have.** An **object table** is for files that are not rows at all: receipts
photographed by delivery drivers, product pictures, PDFs of invoices. An **Iceberg table** is for rows
that have to change: an update, a delete, a schema that grows a column, done to files several engines
read. Both are taught here from Google's documentation and none of it was run.

## Object tables

**An object table is a read-only table with one row per object in a bucket, and the columns are the
object's metadata.** It is created over a connection, like a BigLake table, with the format
`'OBJECT_TABLE'`:

```sql
CREATE EXTERNAL TABLE quitanda.receipts
WITH CONNECTION `planner-dev.southamerica-east1.quitanda-lake`
OPTIONS (
  object_metadata = 'SIMPLE',
  uris = ['gs://quitanda-raw-prod/receipts/*']
);
```

**Each row describes one object**: its `uri`, its `generation`, its `content_type`, its `size`, when it
was `updated`, and the custom metadata attached to it. The contents are not in the table. What the
table makes possible is SQL over the inventory of a bucket, with the governance of BigQuery: which
receipts were uploaded yesterday, how many bytes of pictures each store has sent, which objects are
over a size. The documentation's main use for it is feeding the objects to a model, through BigQuery
ML or a remote function, with the table as the list of what to process.

**It is an inventory, and lesson 1 already had one of a sort**: `gcloud storage ls` lists objects too.
The difference is that the object table can be joined with the orders, filtered in SQL and granted to
somebody who has no access to the bucket.

## Iceberg

**Apache Iceberg is an open table format**: a set of Parquet files plus metadata files, also in the
bucket, that record which data files make up the table at each moment. Changing the table means
writing new data files and a new metadata file that points at the new set, and every engine that
understands Iceberg reads the same table at the same version. It is what gives files in a bucket the
things lesson 16's warehouse took for granted: updates and deletes, a schema that evolves, and reading
the table as it was at an earlier version.

**BigQuery meets Iceberg in two ways**, in Google's documentation. **It can read an Iceberg table that
another engine manages**, from its metadata, as a read-only external or BigLake table. And **it can
manage one itself**: a BigLake table for Apache Iceberg in BigQuery, where BigQuery writes the Parquet
and the Iceberg metadata into a bucket you own and accepts DML on it, while Spark and other engines read
the same files. The BigQuery pricing page names this as "Lakehouse for Apache Iceberg tables", with
loads and merges into them billed at what it calls the standard Lakehouse for Apache Iceberg rates; the
course does not price them further.

**For Quitanda, Iceberg is the answer to a question it does not yet have.** The orders are written once
a night and never changed, so a folder of Parquet files per day serves them. The day a correction has
to change last month's orders in a lake that Spark and BigQuery both read, rewriting folders by hand
stops being safe, and a table format that records every change is the tool. Lesson 25 brings change data
capture, which is the usual way that day arrives.
