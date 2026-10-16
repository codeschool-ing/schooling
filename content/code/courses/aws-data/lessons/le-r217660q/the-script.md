---
title: The Glue script, and what a DynamicFrame is
version: 1
---

**Quitanda's nightly job is three steps: read the new raw CSV, make it clean, write it as curated
Parquet.** Clean means typed, with each order once: the shop's export is sometimes sent twice, and
an order counted twice is revenue that never happened. This is the script Glue would run for it.

**It is not run in this course.** Spark is not in the lab, the `awsglue` library exists only inside a
Glue run, and moto would not run it if it were there. It is shown so that you can read a real Glue
script; the next section runs the same transformation, step for step, with tools that are here.

```schooling-example
{"language": "python", "file": "orders_etl.py", "parts": [{"code": "import sys\n\nfrom awsglue.context import GlueContext\nfrom awsglue.dynamicframe import DynamicFrame\nfrom awsglue.job import Job\nfrom awsglue.utils import getResolvedOptions\nfrom pyspark.context import SparkContext\n\n", "note": "`awsglue` is Glue's own library, and it exists only inside a Glue run: there is no `pip install` that gives it to this lab, which is one reason the script is not run here."}, {"code": "args = getResolvedOptions(sys.argv, ['JOB_NAME'])\nglue = GlueContext(SparkContext.getOrCreate())\njob = Job(glue)\njob.init(args['JOB_NAME'], args)\n\n", "note": "The run's arguments, the Spark context and the job object. `job.init` is where Glue loads this job's bookmark, if it has one."}, {"code": "raw = glue.create_dynamic_frame.from_catalog(\n    database='quitanda_raw', table_name='orders', transformation_ctx='raw_orders')\n", "note": "**The source is a table in the catalog, not a path**: `quitanda_raw.orders` would describe the raw CSV prefix the way lesson 16 described the curated one. `transformation_ctx` names this read for the bookmark, so that the next run reads only files this one did not."}, {"code": "raw = raw.resolveChoice(specs=[('total_cents', 'cast:long')])\ntyped = raw.apply_mapping([\n    ('order_id', 'string', 'order_id', 'string'),\n    ('customer_id', 'string', 'customer_id', 'string'),\n    ('hour', 'long', 'hour', 'byte'),\n    ('items', 'long', 'items', 'short'),\n    ('total_cents', 'long', 'total_cents', 'long'),\n    ('payment', 'string', 'payment', 'string'),\n    ('neighbourhood', 'string', 'neighbourhood', 'string'),\n    ('dt', 'string', 'dt', 'string'),\n])\n", "note": "A DynamicFrame lets a column hold two types at once, a *choice*, when files disagree. `resolveChoice` settles it by casting; `apply_mapping` names every column with its type on the way in and on the way out, which is where `hour` becomes a byte and `items` a short, the `tinyint` and `smallint` of the table."}, {"code": "orders = typed.toDF().dropDuplicates(['order_id'])\n\n", "note": "`toDF` turns it into an ordinary Spark DataFrame, which has `dropDuplicates`. **The duplicates removed are the ones inside this run's input**, which with a bookmark is only the new files."}, {"code": "sink = glue.getSink(connection_type='s3', path='s3://quitanda-curated-prod/orders/',\n                    enableUpdateCatalog=True, updateBehavior='LOG',\n                    partitionKeys=['dt'], transformation_ctx='curated_orders')\nsink.setFormat('glueparquet')\nsink.setCatalogInfo(catalogDatabase='quitanda', catalogTableName='orders')\n", "note": "The output: Parquet under the curated prefix, a folder per `dt`, and `enableUpdateCatalog` so that Glue adds each new partition to `quitanda.orders` itself. `updateBehavior='LOG'` is lesson 16's crawler setting again: a change of schema is reported, not written into the table."}, {"code": "sink.writeFrame(DynamicFrame.fromDF(orders, glue, 'orders'))\njob.commit()\n", "note": "`writeFrame` adds files under each `dt=` folder; it does not replace what is there. `job.commit` saves the bookmark, and **only a run that reaches this line moves it**."}]}
```

## A DynamicFrame and a DataFrame

**A DataFrame has one schema, decided before any row is read; a DynamicFrame lets every record
carry its own.** Spark's DataFrame is a table: columns, types, and rows that fit them. Glue's
DynamicFrame is a collection of records, each describing itself, with the schema worked out from the
records when something asks for it. Where two files disagree about a column, a long in one and a
string in the other, a DataFrame has to fail or guess, and a DynamicFrame keeps both as a *choice*
until the script decides, which is what `resolveChoice` is for.

That is the reason DynamicFrames exist, and lesson 16's coupons and reais are the case they were made
for: raw files from a source nobody controls, whose types drift. Everything else, a join, a window,
`dropDuplicates`, is the DataFrame's, so a Glue script usually reads into a DynamicFrame, settles the
types, and turns it into a DataFrame with `toDF` for the work. On the way out `DynamicFrame.fromDF`
turns it back, because Glue's sinks, the ones that update the catalog as they write, take a
DynamicFrame.

## What this script gets wrong

**`writeFrame` adds files and the bookmark reads only new ones**, and together those two make a
quiet mistake. Suppose the shop sends 15 October's export again the next night, in a second file. The
bookmark gives the script only that file, `dropDuplicates` finds no duplicates inside it, and the
sink adds its rows to the day, beside the first file's rows. Every order in it is now in the curated
layer twice, and nothing failed.

The cure is to read every raw file of each day that has a new one, and replace those days instead of
adding to them. In Spark that is an overwrite with `partitionOverwriteMode` set to `dynamic`, which
replaces the partitions a write touches and leaves the rest alone. The program in the next section
does exactly that, and the section after it sends 15 October twice to show the difference.

