---
title: Reconciling them
version: 1
---

Reconciling two numbers means explaining their difference exactly, to the centavo, rather than declaring one of
them wrong. Finance and sales differ by what finance includes and sales does not, and shipping is the first
suspect:

```sql
-- Where do finance and sales part company? Shipping is the obvious suspect.
SET TimeZone = 'America/Sao_Paulo';
SELECT sum(shipping_cents) AS shipping,
       count(*) FILTER (WHERE paid_at IS NULL) AS orders_never_paid_online,
       count(*) FILTER (WHERE paid_at IS NULL AND status = 'completed') AS of_which_in_a_shop
FROM read_csv('extract/orders.csv')
WHERE CAST(ordered_at AS DATE) BETWEEN '2025-12-01' AND '2025-12-31'
  AND status <> 'cancelled';
```

```
ana@lab:~/wh$ duckdb wh.duckdb < reconcile.sql
┌──────────┬──────────────────────────┬────────────────────┐
│ shipping │ orders_never_paid_online │ of_which_in_a_shop │
│  int128  │          int64           │       int64        │
├──────────┼──────────────────────────┼────────────────────┤
│ 17924700 │                    23405 │              23405 │
└──────────┴──────────────────────────┴────────────────────┘
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT 773739182 - 755814482 AS finance_minus_sales"
┌─────────────────────┐
│ finance_minus_sales │
│        int32        │
├─────────────────────┤
│            17924700 │
└─────────────────────┘
```

**Shipping explains the whole difference.** Finance's December is sales' December plus 17,924,700 centavos of
shipping, and nothing else: the two marts agree about every order and every book, and disagree only about whether
shipping is revenue. That is a business decision, and it has an owner: finance, probably, or whoever signs the
accounts.

Marketing's number is further away for two reasons. Its date is the payment date, so an order placed on 30
November and paid on 1 December counts in December. And **23,405 December orders have no payment date at all**:
every one of them is `completed`, the status of a sale at a shop's till, where the money is taken as the book
changes hands and no separate payment time is recorded. Marketing's mart was built from the website's habits and silently leaves out every shop.
That one is not a definition; it is a defect, and nobody had seen it, because nobody had ever put the three
numbers side by side.

The lesson Kimball drew from meetings like this is that dimensions are not the only thing that must be shared.
**Measures need conforming too**: one definition for each, written down, with a distinct name. "Revenue" is a word
three teams use for three things. **Net sales** and **receipts** are two measures with two definitions, and both
can live in one warehouse without a meeting. Lesson 12's field dictionary is where those definitions are kept.
