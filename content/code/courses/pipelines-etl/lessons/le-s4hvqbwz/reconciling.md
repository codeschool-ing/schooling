---
title: Reconciling: three totals that must agree
version: 1
---

A transformation can be right in every file and wrong in total, and the cheapest way to find out
is to add something up in two ways that do not share any code. **Ponto Final's revenue can be
computed three ways**, from three different tables:

- the mart, after staging, joins and grouping;
- the lines, as quantity times unit price, straight from `raw`;
- the payments, the money the shop actually received, straight from `raw`.

```
ana@vm:~/etl$ psql -d wh -c "SELECT (SELECT sum(revenue_cents) FROM marts.daily_sales) AS mart, (SELECT sum(l.quantity * l.unit_price_cents) FROM raw.order_lines l JOIN raw.orders o USING (order_id) WHERE o.status = 'completed') AS lines, (SELECT sum(p.amount_cents) FROM raw.payments p JOIN raw.orders o USING (order_id) WHERE o.status = 'completed') AS payments"
   mart    |   lines   | payments  
-----------+-----------+-----------
 212162290 | 212162290 | 212162290
(1 row)
```

Three numbers, to the cent: R$ 2,121,622.90 from each. The mart has lost nothing in its joins and
counted nothing twice, the lines add up to what was charged, and every completed order was paid in
full. If the first number were higher than the third, the mart would have fanned out. If the second
differed from the third, the shop's own data would disagree with itself — a till that charged
something other than the sum of its lines — and that would be a question for the shop, not for the
pipeline.

## What a reconciliation is for

**It is not a test of a particular file. It is a test of the whole transformation against a fact
the transformation did not produce.** That is what makes it worth more than checking each step:
a bug anywhere between `raw` and `marts` shows up in the one number at the end.

Three habits make it routine:

- **pick totals that matter to somebody** — revenue, books sold, orders — so a mismatch is a
  conversation and not a curiosity;
- **reconcile against the source as well as the raw layer**, now and then, because the raw layer
  can be wrong too, as lesson 4's missing order showed;
- **run it every time**, after every build. Lesson 16 makes it part of the pipeline, so that a
  mismatch stops the load instead of being found by the person reading the report.
