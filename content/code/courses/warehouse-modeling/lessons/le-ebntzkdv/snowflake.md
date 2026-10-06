---
title: Snowflake
version: 1
---

**Snowflake** runs on top of the three large clouds, AWS, Azure and Google Cloud, and was built from the
start around the separation of storage and compute. It makes that separation visible: you create the
compute yourself, by name.

- **Storage** is a database of tables, held in the cloud provider's object storage in Snowflake's own
  columnar format, billed by the terabyte per month.
- **Compute** is a **virtual warehouse**: a named cluster of machines, in T-shirt sizes from X-Small up,
  that runs queries. A warehouse can be started, stopped, resized, or set to suspend itself after a minute
  of idleness, and several warehouses can read the same tables at once.
- **Micro-partitions** are how every table is stored: the data is cut, automatically, into blocks of between
  50 and 500 MB before compression, each with the minimum and maximum of every column. That is lesson 8's zone maps, built
  in, and nobody declares them.
- **Clustering keys** can be declared on a large table so that Snowflake keeps related rows in the same
  micro-partitions, which makes the zone maps useful for the columns queries filter on.

Ana's fact table in Snowflake's dialect (**not run**):

```sql
CREATE TABLE ponto_final.public.fact_sales (
  date_key       NUMBER(8,0),
  shop_key       NUMBER(38,0),
  book_key       NUMBER(38,0),
  customer_key   NUMBER(38,0),
  promotion_key  NUMBER(38,0),
  order_id       NUMBER(38,0),
  line_no        NUMBER(38,0),
  quantity       NUMBER(38,0),
  gross_cents    NUMBER(38,0),
  discount_cents NUMBER(38,0),
  net_cents      NUMBER(38,0)
)
CLUSTER BY (date_key, shop_key);
```

There is no partition clause: the micro-partitions are made for you, and the clustering key says what to
keep together inside them. Snowflake's documentation recommends clustering keys only for very large tables,
because keeping the order costs compute of its own, in the background, billed like any other.

The **isolation** lesson 7 promised is Snowflake's most visible feature. Ana could give the finance team a
warehouse called `FINANCE_WH` and the dashboards one called `BI_WH`, both reading the same tables; a heavy
month-end report in one does not slow the other, because they share no machines.
