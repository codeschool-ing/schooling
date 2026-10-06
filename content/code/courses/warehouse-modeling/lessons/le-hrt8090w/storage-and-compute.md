---
title: Storage and compute, apart
version: 1
---

In the shared-nothing design of section 06, each node owns its share of the data on its own disks. That
has a consequence that took the industry a decade to work around: **to add processing power you have to
add storage, and move data onto it.** Doubling the nodes means rewriting every table's distribution across
twice as many machines, which can take hours, and shrinking back at night means doing it again.

The design that replaced it in the cloud keeps the data in one place and the processing in another:

- **The data lives in object storage**, the store `cloud` lesson 5 described: files in buckets, cheap, and
  readable by any number of machines at once.
- **Compute is a pool of machines with no data of their own.** They read the files they need for a query,
  cache what they read often, and can be started, stopped, enlarged or multiplied without moving a byte of
  stored data.

What makes it practical is what section 10 just did: a table stored as columnar files, partitioned so a
query reads only the files it needs, with enough statistics in each file (lesson 8 shows them) to skip
most of the rest. The data was written once, to `sales_by_month/`, and any number of DuckDB processes, or
any other engine that reads Parquet, could query it at the same time.

What this buys a warehouse:

- **Elasticity.** A bigger cluster for the month-end close, a small one the rest of the month, and none at
  night.
- **Isolation.** The finance team's heavy reports run on their own compute, reading the same data, and do
  not slow the dashboard everybody else uses. This is the "many queries, many machines" scaling from section
  04, and it is where scaling out works best.
- **Paying for what runs.** Storage is billed by the gigabyte-month; compute by the second or by the data
  scanned.

Lesson 9 is three products built on exactly this split, BigQuery, Snowflake and Redshift, and how each one
bills for it. Lesson 10 is the same idea with the files left open for any engine to read.
