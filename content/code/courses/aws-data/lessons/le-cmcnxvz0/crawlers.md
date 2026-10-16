---
title: Crawlers, and what moto's crawler does not do
version: 1
---

**A crawler is a program AWS runs that reads files and writes the catalog for you.** Pointed at a
prefix, it lists what is there, opens a sample of the files, works out their format and columns,
and creates or updates tables and partitions to match. It is the answer to "I have a bucket of files
and no idea what is in them", and it is a poor answer to "my job wrote one more day", which is the
case most lakes have every night.

moto keeps a crawler's definition and runs none of it, so this section has two halves: what was
recorded, and what a real crawler would have done with the same definition.

## The definition

```
ana@laptop:~/aws$ aws glue create-crawler --name orders-crawler --role arn:aws:iam::123456789012:role/quitanda-glue-crawler --database-name quitanda --targets 'S3Targets=[{Path=s3://quitanda-curated-prod/orders/,SampleSize=5}]' --schema-change-policy UpdateBehavior=LOG,DeleteBehavior=LOG --recrawl-policy RecrawlBehavior=CRAWL_NEW_FOLDERS_ONLY --schedule 'cron(30 3 * * ? *)'
ana@laptop:~/aws$ aws glue get-crawler --name orders-crawler --query 'Crawler.[State,Schedule.State,SchemaChangePolicy.UpdateBehavior,RecrawlPolicy.RecrawlBehavior]' --output text
READY	SCHEDULED	LOG	CRAWL_NEW_FOLDERS_ONLY
```

Every setting came back as it was sent, and each one is a decision a real crawler acts on:

- **`SampleSize=5`** reads five files per folder rather than all of them. Sampling makes a crawl fast
  on a large prefix, and it means a schema is inferred from five days and assumed for the other 26.
- **`UpdateBehavior=LOG`** tells it to report a schema change in its log instead of writing it into
  the table. The default, `UPDATE_IN_DATABASE`, rewrites the table the moment a file disagrees with
  it, which is how a single malformed export changes the type of a column for every query the next
  morning.
- **`DeleteBehavior=LOG`** leaves a table in place when its files disappear. The other choices mark
  it deprecated, the default, or delete it from the catalog.
- **`CRAWL_NEW_FOLDERS_ONLY`** visits only folders it has not seen, which turns a nightly crawl of
  three years into a crawl of one day. The third choice, event mode, reads S3's notifications of new
  objects instead of listing anything.
- **`cron(30 3 * * ? *)`** is 03:30 in UTC, because Glue's schedules are written in UTC. In São
  Paulo that is half past midnight, which is worth knowing before a crawl is set for "after the
  export" and runs before it.

## The run that never ends

```
ana@laptop:~/aws$ aws glue start-crawler --name orders-crawler
ana@laptop:~/aws$ aws glue get-crawler --name orders-crawler --query 'Crawler.[State,LastCrawl.Status]' --output text
RUNNING	RUNNING
ana@laptop:~/aws$ sleep 10; aws glue get-crawler --name orders-crawler --query 'Crawler.[State,LastCrawl.Status]' --output text
RUNNING	RUNNING
ana@laptop:~/aws$ aws glue get-tables --database-name quitanda --query 'TableList[].Name' --output text
orders
ana@laptop:~/aws$ aws glue stop-crawler --name orders-crawler
ana@laptop:~/aws$ sleep 10; aws glue get-crawler --name orders-crawler --query 'Crawler.[State,LastCrawl.Status]' --output text
STOPPING	STOPPING
```

**`RUNNING`, ten seconds later still `RUNNING`, and the catalog has only the table this lesson made
by hand.** Stopped, it went to `STOPPING` and stayed there. moto never moves a crawler past those
states and never opens a file, so nothing in this section was crawled. What follows is AWS's
documented behaviour, not run here.

## What a real crawl does

A real crawler starts with **classifiers**: small recognisers, tried in order, each answering
whether a file is its format and how sure it is. Glue has built-in ones for CSV, JSON, Parquet, ORC,
Avro, XML and common log formats, and you can put custom ones first, a grok pattern for a log line or
a CSV with a delimiter of its own. The winning classifier gives the schema of the sample.

Then it **groups**. Files under one prefix whose schemas are similar enough become one table, and the
folders below become partitions: `dt=2026-10-01/` gives a partition key `dt`, and a folder with no
`name=` in it gives one called `partition_0`. When the schemas are too different, a crawler makes a
table for each folder instead, and a lake with one odd export can wake up with a table for each of 31 folders. The setting that prevents that is the one that asks for a single schema
per path, and the habit that prevents it is not crawling a prefix whose layout you already know.

**A crawl is billed by the DPU-hour, per second, with a ten-minute minimum for each run**, at the crawler line of the sheet, 0.69 dollars, the same as a job's. A DPU is a unit of compute Glue sizes for the crawl, and
AWS chooses how many. At one DPU, the minimum run is 0.69 × 10 / 60 = 0.115 dollars. A nightly crawl that never finishes faster than the minimum is 31 × 0.115 = 3.565 dollars in October, for work that one `batch-create-partition` call from the writer does inside the free tier.
