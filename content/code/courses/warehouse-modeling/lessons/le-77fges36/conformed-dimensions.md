---
title: Conformed dimensions: one shop for every fact table
version: 1
---

Ana's warehouse has five fact tables, and `fact_sales` and `fact_inventory` both point at
`dim_shop`. Not at two copies that happen to look alike: at the same table, with the same keys and
the same attribute values. A dimension used that way is **conformed**.

It matters the moment a question needs two business processes at once. How many months of stock did
each shop hold at the end of 2025, at December's rate of sale? That is sales from one fact table and
stock from another:

```sql
-- Two fact tables, one conformed shop dimension: December 2025 sales against
-- the stock counted at the end of that month.
WITH sold AS (
    SELECT f.shop_key, sum(f.quantity) AS books_sold
    FROM fact_sales f JOIN dim_date d USING (date_key)
    WHERE d.year = 2025 AND d.month = 12
    GROUP BY f.shop_key
),
counted AS (
    SELECT i.shop_key, sum(i.on_hand) AS books_on_shelf
    FROM fact_inventory i
    WHERE i.date_key = 20251231
    GROUP BY i.shop_key
)
SELECT s.shop_name, sold.books_sold, counted.books_on_shelf,
       round(counted.books_on_shelf / sold.books_sold, 1) AS months_of_stock
FROM sold
JOIN counted USING (shop_key)
JOIN dim_shop s USING (shop_key)
ORDER BY months_of_stock;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < drill-across.sql
┌───────────┬────────────┬────────────────┬─────────────────┐
│ shop_name │ books_sold │ books_on_shelf │ months_of_stock │
│  varchar  │   int128   │     int128     │     double      │
├───────────┼────────────┼────────────────┼─────────────────┤
│ Online    │      33931 │          34092 │             1.0 │
│ Pinheiros │       8879 │          14529 │             1.6 │
│ Paulista  │      10771 │          18337 │             1.7 │
│ Savassi   │       6461 │          10888 │             1.7 │
│ Batel     │       4593 │           7989 │             1.7 │
│ Cambuí    │       5292 │           9528 │             1.8 │
│ Moinhos   │       3994 │           7471 │             1.9 │
└───────────┴────────────┴────────────────┴─────────────────┘
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Drilling across two fact tables. fact_sales is summed for December 2025 to one row per shop, books sold. fact_inventory is summed at 31 December 2025 to one row per shop, books on the shelf. The two results, each one row per shop, are joined on shop_key, the key of the conformed dimension dim_shop, giving months of stock per shop.\"><defs><marker id=\"ah-drill-across\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fact_sales</text><rect x=\"20\" y=\"160\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fact_inventory</text><line x1=\"170\" y1=\"60\" x2=\"230\" y2=\"60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-drill-across)\"></line><line x1=\"170\" y1=\"180\" x2=\"230\" y2=\"180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-drill-across)\"></line><rect x=\"235\" y=\"35\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"335\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sum per shop, December</text><text x=\"335\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">7 rows: books_sold</text><rect x=\"235\" y=\"155\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"335\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sum per shop, 31 December</text><text x=\"335\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">7 rows: books_on_shelf</text><line x1=\"435\" y1=\"60\" x2=\"500\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-drill-across)\"></line><line x1=\"435\" y1=\"180\" x2=\"500\" y2=\"130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-drill-across)\"></line><rect x=\"505\" y=\"95\" width=\"195\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"602\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">join on shop_key</text><text x=\"602\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">7 rows: months of stock</text><text x=\"360\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sum each fact table to the shared grain first, then join</text></svg>", "caption": "Drilling across: each fact table is summed to the same grain before the conformed key joins them."}
```

**Each fact table is summed on its own first, to the same grain, and the two results are joined on the
conformed key.** That is called **drilling across**. Joining the two fact tables row to row instead
would multiply every sale by every stock line of the same shop and produce a number with no meaning;
summing first and then joining on `shop_key` gives one row per shop from each side.

The answer is useful: the website holds about one month of stock and every physical shop between 1.6
and 1.9, which is what a warehouse that ships the next day and shops that have to fill shelves would
look like.

## What conforming requires

- **The same keys.** `shop_key` 5 is the website in every fact table that mentions a shop.
- **The same attribute values.** If the sales team's region said `South` and the stock team's said
  `Sul`, a report comparing the two would show two regions with half the data each.
- **The same grain, or a rolled-up copy of it.** A monthly fact table can share a dimension of months
  that agrees with `dim_date` on every attribute it keeps. That is still conformed.

Lesson 11 comes back to this, because conformed dimensions are what make a warehouse one warehouse
rather than several marts that cannot be compared, and Kimball's **bus matrix** is the table that plans
them.
