---
title: Which rows go to which machine
version: 1
---

The usual way to spread a table across nodes is by **hashing a column**: compute a hash of the
column's value, take it modulo the number of nodes, and that is the node. The same value always lands on
the same node, which matters for joins, and different values scatter roughly evenly, which matters for
balance. The column is called the **distribution key**; Redshift calls it `DISTKEY`, and lesson 9 shows
it there.

There is one machine in the lab, so the four nodes here are arithmetic: a hash modulo 4, counted.
Two candidate keys for the sales table, the order number and the shop:

```sql
-- Where the sales rows would go on four machines, by two choices of key.
SELECT hash(order_id) % 4 AS node, count(*) AS rows_by_order
FROM fact_sales GROUP BY node ORDER BY node;

SELECT hash(shop_key) % 4 AS node, count(*) AS rows_by_shop
FROM fact_sales GROUP BY node ORDER BY node;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < nodes.sql
┌────────┬───────────────┐
│  node  │ rows_by_order │
│ uint64 │     int64     │
├────────┼───────────────┤
│      0 │        221229 │
│      1 │        221827 │
│      2 │        222387 │
│      3 │        222034 │
└────────┴───────────────┘
┌────────┬──────────────┐
│  node  │ rows_by_shop │
│ uint64 │    int64     │
├────────┼──────────────┤
│      0 │       643004 │
│      1 │        60805 │
│      2 │       183668 │
└────────┴──────────────┘
```

**By order number, the four nodes get between 221,229 and 222,387 rows each**: a spread of half a
percent. There are 572,439 different order numbers, so the hash has plenty of values to scatter, and the
law of large numbers does the rest.

**By shop, one node gets 643,004 rows, one gets 60,805, one gets 183,668, and the fourth gets none.**
There are only seven shops, so the hash has seven values to place on four nodes, and it placed them
unevenly, as seven values usually land. A query on this layout runs as slow as the node with 643,004
rows, which is 72% of the table, while one node sits idle.

The lesson from the two results is the first rule of choosing a distribution key: **it needs many
distinct values, spread evenly.** An order number, a customer number, a line id. Never a status, a
country, a shop or a date with a handful of values. The next section shows the second rule, which is about
the values being *spread evenly*, and why seven shops would be uneven even with seven nodes.
