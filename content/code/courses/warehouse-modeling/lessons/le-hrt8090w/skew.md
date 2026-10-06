---
title: Skew, when one machine gets half the work
version: 1
---

Suppose the cluster had seven nodes and each shop got its own. Every node would hold one shop, which
sounds even. It is not, because the shops are not:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT s.shop_name, count(*) AS rows, round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct FROM fact_sales f JOIN dim_shop s USING (shop_key) GROUP BY ALL ORDER BY rows DESC LIMIT 2"
┌───────────┬────────┬────────┐
│ shop_name │  rows  │  pct   │
│  varchar  │ int64  │ double │
├───────────┼────────┼────────┤
│ Online    │ 378374 │   42.6 │
│ Paulista  │ 147474 │   16.6 │
└───────────┴────────┴────────┘
```

**The website has 42.6% of all sale lines.** The node holding it would do 42.6% of the work of every query,
while the node holding Moinhos did a few per cent. With seven nodes, a query that could finish in a
seventh of the time takes nearly half of it, because the website's node finishes last and everybody waits.

This is **skew**: work spread unevenly across nodes, so that adding nodes stops helping. It comes from two
places, and only the first is visible in advance:

- **Skewed keys.** A distribution key with few values, or with values of very different weight: shops,
  countries, a customer column where one wholesale customer has a third of the orders, or a column where
  most rows are empty and every empty value hashes to the same node.
- **Skewed queries.** A key that spreads rows evenly can still spread *work* unevenly, if every query
  filters for the same few values. Spread by date, the data is even; but if everyone asks about the last
  week, the nodes holding the last week do all the work.

How it is caught: MPP products report rows per node for a table and time per node for a query, and
Redshift's `SVV_TABLE_INFO` view has a `skew_rows` column for exactly this. **The ratio of the fullest node
to the average is the number to watch.** A ratio near 1 is healthy. The order-number layout of the previous section
has a ratio of 1.002; the shop layout, 643,004 against an average of 221,869, has 2.9.
