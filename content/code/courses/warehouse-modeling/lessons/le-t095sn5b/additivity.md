---
title: What you may add up
version: 1
---

A warehouse exists to be summed, so the first question to ask of any measure is **across which
dimensions it can be added and still mean something.** There are three answers, and a measure has
exactly one of them.

## Additive: across everything

Quantity, gross, discount and net add up across every dimension. Sum them by shop, by month, by book
or over the whole table, and the result is a true total:

```sql
SELECT s.shop_name,
       sum(f.quantity)                                   AS books,
       sum(f.net_cents)                                  AS net_cents,
       round(100.0 * sum(f.discount_cents) / sum(f.gross_cents), 2) AS discount_pct
FROM fact_sales f JOIN dim_shop s USING (shop_key)
GROUP BY ALL ORDER BY net_cents DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < additive.sql
┌───────────┬────────┬────────────┬──────────────┐
│ shop_name │ books  │ net_cents  │ discount_pct │
│  varchar  │ int128 │   int128   │    double    │
├───────────┼────────┼────────────┼──────────────┤
│ Online    │ 415722 │ 4066937959 │         1.32 │
│ Paulista  │ 162288 │ 1591634703 │         0.44 │
│ Pinheiros │ 128815 │ 1266135132 │         0.43 │
│ Savassi   │  94250 │  925370751 │         0.41 │
│ Cambuí    │  80577 │  792418486 │         0.41 │
│ Batel     │  66780 │  656724950 │         0.44 │
│ Moinhos   │  26895 │  275167871 │         0.49 │
└───────────┴────────┴────────────┴──────────────┘
```

The seven `net_cents` add up to the 9,574,389,852 of the previous section, and the `books` column to
the number of books sold. **Additive measures are the ones to store**, because every other number a
report wants can be built from them.

## Non-additive: never directly

The last column, `discount_pct`, is a ratio, and a ratio cannot be added. Not even averaged, as it
turns out:

```sql
-- The discount rate of the whole chain, worked out two ways.
WITH by_shop AS (
    SELECT shop_key, sum(discount_cents) AS discount, sum(gross_cents) AS gross
    FROM fact_sales GROUP BY shop_key
)
SELECT round(100.0 * sum(discount) / sum(gross), 2) AS chain_rate,
       round(avg(100.0 * discount / gross), 2)       AS average_of_shop_rates
FROM by_shop;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < ratio.sql
┌────────────┬───────────────────────┐
│ chain_rate │ average_of_shop_rates │
│   double   │        double         │
├────────────┼───────────────────────┤
│       0.81 │                  0.56 │
└────────────┴───────────────────────┘
```

The chain gave away **0.81%** of its gross sales in discounts. Average the seven shops' rates and
you get **0.56%**, which is the rate of no shop and of no chain. The average weighs Moinhos, with
its 26,895 books, the same as the website with its 415,722, and the website discounts three times as
much as the shops do.

**The rule: store the parts, compute the ratio last.** `discount_cents` and `gross_cents` are both
additive. Sum each over whatever the report groups by, and divide at the end. The same goes for an
average price (sum of net over sum of quantity), a margin, a conversion rate, or any percentage.
A table that stores `discount_pct` per row has stored a number that every report will be tempted to
average.

The third answer, a measure that adds up across some dimensions and not others, is the next
section.
