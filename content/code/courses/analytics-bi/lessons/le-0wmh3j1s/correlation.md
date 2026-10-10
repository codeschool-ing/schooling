---
title: Correlation, and the group hiding behind it
version: 1
---

A **correlation** measures how closely two numeric columns move together, on a scale from −1 to
1. Near 1, when one is high the other tends to be high; near −1, the opposite; near 0, knowing one
tells you nothing about the other in a straight line. PostgreSQL computes Pearson's correlation
coefficient, usually written *r*, with `corr`.

Somebody in marketing has a theory: discounts make people buy more. The data seems to agree:

```
lantern=# SELECT round(corr(discount_pct, gross_cents)::numeric, 3) AS r FROM order_totals;
   r   
-------
 0.271
(1 row)

lantern=# SELECT c.segment, count(*) AS orders,
lantern-#        round(corr(t.discount_pct, t.gross_cents)::numeric, 3) AS r
lantern-# FROM order_totals t JOIN customers c USING (customer_id)
lantern-# GROUP BY c.segment;
 segment | orders |   r    
---------+--------+--------
 office  |    684 |       
 home    |   6418 | -0.005
(2 rows)

lantern=# SELECT c.segment, t.discount_pct, count(*) AS orders,
lantern-#        round(avg(t.gross_cents) / 100.0, 2) AS mean_brl
lantern-# FROM order_totals t JOIN customers c USING (customer_id)
lantern-# GROUP BY 1, 2 ORDER BY 1, 2;
 segment | discount_pct | orders | mean_brl 
---------+--------------+--------+----------
 home    |            0 |   4990 |   120.50
 home    |            5 |    317 |   138.71
 home    |           10 |   1111 |   113.65
 office  |           15 |    684 |   639.51
(4 rows)
```

Over all orders, *r* is 0.271: orders with a larger discount are larger. Asked inside each
segment, the relationship disappears. Among home orders *r* is −0.005, which is nothing at all.
Among office orders it is empty — `NULL` — and the last query says why: every office order has a
discount of exactly 15%, and a column that never varies cannot vary *with* anything.

The last table is the whole story. Home orders with no discount average R$ 120.50, with 5% R$
138.71, with 10% R$ 113.65: no pattern. Office orders all carry 15% and average R$ 639.51. **The
discount and the order size are both caused by the segment.** Offices get a volume discount and
place large orders; the discount does not make them place large orders.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"two-clouds\" aria-label=\"Mean order value against the discount on the order. Three home-segment points sit low and flat: no discount, 120.50 reais; 5 percent, 138.71; 10 percent, 113.65. One office point sits far above them at 15 percent, 639.51 reais. A dashed line fitted through all four points climbs steeply, which is what a correlation of 0.271 over all orders sees. A line through the home points alone is flat, which is what a correlation of -0.005 inside the home segment sees.\"><line x1=\"90\" y1=\"280\" x2=\"660\" y2=\"280\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"90\" y1=\"280\" x2=\"90\" y2=\"40\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"90.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0%</text><text x=\"280.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">5%</text><text x=\"470.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10%</text><text x=\"660.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">15%</text><text x=\"80\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">R$ 0</text><text x=\"80\" y=\"211.42857142857144\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">R$ 200</text><text x=\"80\" y=\"142.85714285714286\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">R$ 400</text><text x=\"80\" y=\"74.28571428571428\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">R$ 600</text><text x=\"375.0\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">discount on the order</text><text x=\"90\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mean order value</text><line x1=\"90.0\" y1=\"244.69942857142857\" x2=\"660.0\" y2=\"137.67657142857144\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"6 4\"></line><text x=\"637.2\" y=\"166.85714285714286\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">all orders: r = 0.271</text><line x1=\"90.0\" y1=\"238.5142857142857\" x2=\"470.0\" y2=\"238.5142857142857\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><text x=\"280.0\" y=\"264.51428571428573\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">home only: r = −0.005</text><circle cx=\"90.0\" cy=\"238.68571428571428\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"102.0\" y=\"224.68571428571428\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">home · R$ 120.50</text><circle cx=\"280.0\" cy=\"232.4422857142857\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"292.0\" y=\"218.4422857142857\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">home · R$ 138.71</text><circle cx=\"470.0\" cy=\"241.03428571428572\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"482.0\" y=\"227.03428571428572\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">home · R$ 113.65</text><circle cx=\"660.0\" cy=\"60.73942857142859\" r=\"6\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.5\"></circle><text x=\"648.0\" y=\"46.73942857142859\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">office · R$ 639.51</text></svg>", "caption": "The correlation over all orders is the line between two groups, not a line inside either of them."}
```

This shape has a name, a **confounder**: a third variable behind both of the two you measured. A
correlation computed over a mix of groups can be produced entirely by the difference between the
groups, which is why the habit from two sections ago — ask whether the column holds one
population — applies to every statistic you compute, not only to averages.

## What a correlation is good for in exploratory work

Not for proving anything. A correlation is a pointer: it tells you two columns are worth looking
at together, and the next query — split by a group, or plotted — tells you why. Three cautions,
each of which has cost somebody a wrong decision:

- **It measures a straight line.** Two columns related by a curve, say sales rising and then
  falling with price, can have an *r* near zero.
- **It is moved by a few extreme rows**, and the next query shows how much.
- **It says nothing about direction.** Customers who order often may receive more coupons, or
  coupons may make them order often; *r* is the same number either way.

Leave out the three mis-priced orders from the last section — three rows of 7,102 — and the same
correlation changes a great deal:

```
lantern=# SELECT round(corr(discount_pct, gross_cents)::numeric, 3) AS r
lantern-# FROM order_totals
lantern-# WHERE order_id NOT IN (412, 415, 431);
   r   
-------
 0.447
(1 row)
```

From 0.271 to 0.447. Three home orders with huge values and little or no discount were dragging the line
down. **Find the errors before you compute anything built on squared distances**, which a
correlation, a standard deviation and a regression all are.
