---
title: The same star, three ways
version: 1
---

Put the three side by side and the pattern is plain: **the logical model is the same, and each product asks
a different physical question about it.**

| | BigQuery | Snowflake | Redshift |
|---|---|---|---|
| where data lives | Google's storage, its format | the cloud's object storage, its format | managed storage with local cache (RA3), or serverless |
| compute | slots, assigned by the service | virtual warehouses you create and size | nodes you choose, or RPUs in serverless |
| how you pay for compute | bytes read per query, or reserved slots | credits per second a warehouse runs | node hours, or RPU hours |
| what you declare | `PARTITION BY`, `CLUSTER BY` | `CLUSTER BY` on large tables | `DISTSTYLE`, `DISTKEY`, `SORTKEY` |
| what it does for you | everything else | micro-partitions and their statistics | `AUTO` choices, if you let it |
| integer types | `INT64` | `NUMBER(38,0)` | `INTEGER`, `BIGINT` |

The declarations all aim at the two things lessons 7 and 8 measured. **Keep together the rows a query
wants**, so blocks and partitions can be skipped: BigQuery's partitions and clusters, Snowflake's clustering
keys, Redshift's sort keys. And, where the product still exposes it, **keep a join's two sides on the same
machine**: Redshift's distribution keys.

What does not appear in the table is as important. **Facts and dimensions, the grain, surrogate keys, type 2
history, conformed dimensions and bridge tables are the same in all three**, and in DuckDB, and in PostgreSQL
if it came to that. A warehouse designed well can move from one product to another with its DDL rewritten and
its model untouched; one designed around a single product's knobs cannot.

For somebody in the `software-architecture` track, this table is the one to bring to the meeting: the choice
between the three is mostly about the bill and the operating model, and very little about the design of the
tables.
