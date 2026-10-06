---
title: Semi-additive: the stock on the shelf
version: 1
---

Selling books is one business process. **Counting them is another**: at the end of each month
somebody at every shop counts the copies of every title on the shelves. Its grain is one row per shop,
per book it stocks, per month-end count, and it has one measure, `on_hand`.

```sql
-- Grain: one row per shop, per book it stocks, per month-end count.
CREATE TABLE fact_inventory AS
SELECT d.date_key, s.shop_key, b.book_key, sc.on_hand
FROM staging.stock_counts sc
JOIN dim_date d ON d.date = sc.count_date
JOIN dim_shop s ON s.shop_id = sc.shop_id
JOIN dim_book b ON b.book_id = sc.book_id
ORDER BY d.date_key, s.shop_key, b.book_key;
```

How many books were on Paulista's shelves in 2024? Sum it, and look at what comes out:

```sql
-- Books on the shelves of Paulista, two ways.
SELECT d.year,
       sum(i.on_hand)                                   AS summed_over_months,
       sum(i.on_hand) FILTER (WHERE d.month = 12)       AS at_year_end,
       round(sum(i.on_hand) / count(DISTINCT d.month))  AS average_month_end
FROM fact_inventory i
JOIN dim_date d USING (date_key)
JOIN dim_shop s USING (shop_key)
WHERE s.shop_name = 'Paulista'
GROUP BY d.year ORDER BY d.year;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < stock.sql
┌───────┬────────────────────┬─────────────┬───────────────────┐
│ year  │ summed_over_months │ at_year_end │ average_month_end │
│ int64 │       int128       │   int128    │      double       │
├───────┼────────────────────┼─────────────┼───────────────────┤
│  2024 │             170458 │       15635 │           14205.0 │
│  2025 │             205531 │       18337 │           17128.0 │
└───────┴────────────────────┴─────────────┴───────────────────┘
```

**170,458 is not a number of books.** It is twelve month-end counts added together, the same copy
counted again every month it stayed on the shelf. Paulista held 15,635 books at the end of December
2024, and 14,205 on an average month-end. Both are true answers; the sum is not an answer to
anything.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A grid of month-end stock counts, shops down the side and months across. Adding down a column, across shops at one month-end, gives the books in the chain on that date. Adding along a row, across the months for one shop, counts the same copies again and again: at Paulista, twelve counts of 2024 add to 170,458, while the shelves held 15,635 books at the end of December.\"><defs><marker id=\"ah-semi-additive\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"138.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Jan</text><text x=\"194.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Feb</text><text x=\"250.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Mar</text><text x=\"306.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">…</text><text x=\"362.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Nov</text><text x=\"418.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Dec</text><text x=\"98\" y=\"66.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Paulista</text><rect x=\"113\" y=\"53\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"169\" y=\"53\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"225\" y=\"53\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"281\" y=\"53\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"337\" y=\"53\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"393\" y=\"53\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"98\" y=\"98.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Pinheiros</text><rect x=\"113\" y=\"85\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"169\" y=\"85\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"225\" y=\"85\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"281\" y=\"85\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"337\" y=\"85\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"393\" y=\"85\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"98\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Cambuí</text><rect x=\"113\" y=\"117\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"169\" y=\"117\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"225\" y=\"117\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"281\" y=\"117\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"337\" y=\"117\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"393\" y=\"117\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"98\" y=\"162.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">…</text><rect x=\"113\" y=\"149\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"169\" y=\"149\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"225\" y=\"149\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"281\" y=\"149\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"337\" y=\"149\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"393\" y=\"149\" width=\"50\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"454\" y1=\"66.0\" x2=\"486\" y2=\"66.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#ah-semi-additive)\"></line><text x=\"494\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">across months: 170,458</text><text x=\"494\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the same copies, counted again</text><line x1=\"418.0\" y1=\"182\" x2=\"418.0\" y2=\"214\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah-semi-additive)\"></line><text x=\"418.0\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">across shops at one date: a true total</text><text x=\"418.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Paulista alone, end of December 2024: 15,635</text></svg>", "caption": "`on_hand` adds across shops at one date, and not across dates."}
```

`on_hand` is **semi-additive**: it adds across shops and across books, because the copies at
Paulista and the copies at Batel are different copies. It does not add across time, because a
balance at the end of March and a balance at the end of April count mostly the same copies.
Across time it needs a different aggregate: the value at the last date of the period, an average
over the period, or the minimum.

Any balance behaves this way: stock on hand, money in an account, seats left on a flight, students
enrolled. **A sales table measures a flow, what moved during the period; a stock table measures a
level, what was there at an instant.** Flows add over time. Levels do not.

A report tool cannot tell the two apart by looking at the column: both are integers called something
reasonable. That is one of the things lesson 12's dictionary records for every measure.
