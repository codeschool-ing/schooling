---
title: The centre and the spread, and why the mean is the wrong first number
version: 1
---

Ask for "the average order" and most people, and most tools, compute the **mean**: the sum
divided by the count. On a skewed distribution the mean is pulled towards the tail, and the
**median** — the value with half the rows below it and half above — is not:

```
lantern=# SELECT round(avg(gross_cents) / 100.0, 2) AS mean_brl,
lantern-#        percentile_cont(0.5) WITHIN GROUP (ORDER BY gross_cents) / 100 AS median_brl
lantern-# FROM order_totals;
 mean_brl | median_brl 
----------+------------
   170.23 |       95.8
(1 row)

lantern=# SELECT percentile_cont(ARRAY[0.25, 0.5, 0.75]) WITHIN GROUP (ORDER BY gross_cents)
lantern-#        AS quartiles_cents
lantern-# FROM order_totals;
  quartiles_cents  
-------------------
 {4790,9580,16865}
(1 row)
```

The mean order is R$ 170.23 and the median is R$ 95.80. **Fewer than half of Lantern's orders
are anywhere near the "average" order**: the mean is nearly twice what a typical customer spends,
because a minority of large orders pulls it up. If a campaign were planned around a typical order
of R$ 170, it would be planned around a customer the shop barely has.

`percentile_cont` takes the fraction of rows that should fall below the answer, and given a list
it answers a list. The three **quartiles** split the orders into four groups of equal size: a
quarter are below R$ 47.90, half below R$ 95.80, three quarters below R$ 168.65. The distance
between the first and the third, R$ 120.75, is the **interquartile range**, or IQR: how wide the
middle half of the orders is. Unlike the range from smallest to largest, it does not move when
one absurd row arrives.

## The same question, asked of each group

The jump at the end of the histogram suggested two groups. Lantern sells to people at home and to
offices, and the `segment` column says which:

```
lantern=# SELECT c.segment, count(*) AS orders,
lantern-#        round(avg(t.gross_cents) / 100.0, 2) AS mean_brl,
lantern-#        percentile_cont(0.5) WITHIN GROUP (ORDER BY t.gross_cents) / 100 AS median_brl
lantern-# FROM order_totals t JOIN customers c USING (customer_id)
lantern-# GROUP BY c.segment;
 segment | orders | mean_brl | median_brl 
---------+--------+----------+------------
 home    |   6418 |   120.22 |       85.8
 office  |    684 |   639.51 |     456.25
(2 rows)
```

Two different businesses. The 6,418 home orders have a median of R$ 85.80; the 684 office orders
have a median of R$ 456.25, more than five times as much. **A single mean over both describes
neither**: R$ 170.23 is far above what a home customer spends and far below what an office
spends.

This is the first habit exploratory analysis builds: before summarising a column, ask whether it
holds one population or several. A number that mixes them is not wrong arithmetic, and it can be
wrong about everybody in the table.
