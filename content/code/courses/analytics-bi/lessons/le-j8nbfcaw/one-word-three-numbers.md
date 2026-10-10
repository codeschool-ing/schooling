---
title: Revenue, as three teams compute it
version: 1
---

The commonest picture of a metric is that it is a number: revenue was so much last quarter, and
anybody who computes it correctly gets the same answer. **A metric is not a number. It is a
definition, and the number is what the definition produces on a given day.** Two people who agree
on the word and disagree on the definition will both compute correctly and get different numbers,
and each will think the other made a mistake.

Here is Lantern's first quarter of 2026, as three teams would compute "revenue" from the same
table, each with a reason:

```
lantern=# SELECT round(sum(gross_cents) / 100.0, 2) AS marketing,
lantern-#        round(sum(gross_cents - gross_cents * discount_pct / 100) / 100.0, 2) AS ecommerce,
lantern-#        round(sum(gross_cents - gross_cents * discount_pct / 100)
lantern(#          FILTER (WHERE status = 'paid' AND customer_id <> 1) / 100.0, 2) AS finance
lantern-# FROM order_totals
lantern-# WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01';
 marketing | ecommerce |  finance  
-----------+-----------+-----------
 329036.20 | 305267.62 | 294209.60
(1 row)
```

**Marketing** reports R$ 329,036.20: the value of every order placed, because what it wants to
know is how much demand its campaigns produced, and a refunded order was still demand. The
**e-commerce manager** reports R$ 305,267.62: what customers were charged after their coupons,
because that is what the checkout took. **Finance** reports R$ 294,209.60: only orders that stayed
paid, without the shop's test account, because that is the money that arrived and stayed.

None of the three is wrong. Each answers a different question, and the gap between the first and
the last is R$ 34,826.60, more than one order in ten of the quarter's value. The defect is not in
any query. **It is that the same word names all three**, so a slide that says "revenue: R$ 329k"
and a board report that says "revenue: R$ 294k" look like a contradiction, and a meeting is spent
finding out that they are not.

This lesson is about removing that meeting: naming what a metric is made of, writing its
definition where every tool and every person reads the same sentence, and reconciling two numbers
when they disagree.
