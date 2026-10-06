---
title: BigQuery
version: 1
---

**BigQuery** is Google Cloud's warehouse, and the one that hides the machines most completely. There is
no cluster to create: you create a **dataset**, which is a container of tables, load data, and run
queries. Google decides how many machines a query gets.

Its pieces, in the vocabulary of the previous lessons:

- **Storage** is columnar, in Google's own format, kept in its distributed file system and billed by the
  gigabyte per month.
- **Compute** is measured in **slots**: a slot is a unit of processing capacity, roughly a share of a
  machine's processor and memory. A query is given as many slots as it can use, up to what the project is
  allowed.
- **Partitioning** is declared per table, by a date or timestamp column, by ingestion time, or by an integer
  range. A query that filters on the partition column reads only the matching partitions, exactly as the
  Parquet folders did in lesson 7.
- **Clustering** is declared on up to four columns, and orders the data inside each partition by them, so
  that blocks can be skipped by their statistics, lesson 8's zone maps.

The DDL for Ana's fact table, in BigQuery's dialect (**not run**: there is no BigQuery in this lab):

```sql
CREATE TABLE ponto_final.fact_sales (
  sale_date      DATE,
  shop_key       INT64,
  book_key       INT64,
  customer_key   INT64,
  promotion_key  INT64,
  order_id       INT64,
  line_no        INT64,
  quantity       INT64,
  gross_cents    INT64,
  discount_cents INT64,
  net_cents      INT64
)
PARTITION BY sale_date
CLUSTER BY shop_key, book_key;
```

One change from the lab is deliberate: the date is a `DATE` column rather than an integer key, because
BigQuery partitions by a date column. The dimension `dim_date` stays, joined on the date itself. The
clustering columns are the ones queries filter on after the date, which is lesson 8's advice about sort
order, written as a declaration.

BigQuery offers two ways to pay for compute: **on demand**, by the bytes each query reads, and **capacity**,
by the slots reserved per hour. The first is the one that changes how a model is designed, and it is the
next section.
