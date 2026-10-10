---
title: Targets, and the colours that judge them
version: 1
---

The second comparison on the list is the target. A target is not in the data: it is a decision the
business made, and it has to be stored somewhere a query can read it. A small table in the layer,
typed by whoever owns the plan, is enough:

```sql
CREATE TABLE semantic.revenue_target (month date PRIMARY KEY, target numeric(12,2) NOT NULL);
INSERT INTO semantic.revenue_target VALUES
  ('2026-01-01', 90000), ('2026-02-01', 95000), ('2026-03-01', 110000),
  ('2026-04-01', 125000), ('2026-05-01', 135000), ('2026-06-01', 145000);
```
```
lantern=# CREATE TABLE semantic.revenue_target (month date PRIMARY KEY, target numeric(12,2) NOT NULL);
CREATE TABLE

lantern=# INSERT INTO semantic.revenue_target VALUES
lantern-#   ('2026-01-01', 90000), ('2026-02-01', 95000), ('2026-03-01', 110000),
lantern-#   ('2026-04-01', 125000), ('2026-05-01', 135000), ('2026-06-01', 145000);
INSERT 0 6
```

The numbers are the business's, invented for Lantern like everything else. Then actual against target,
month by month:

```sql
SELECT t.month, t.target, sum(o.net_revenue) AS actual,
       round(100 * sum(o.net_revenue) / t.target) AS attainment_pct
FROM semantic.revenue_target t
JOIN semantic.orders o ON date_trunc('month', o.order_date) = t.month
GROUP BY t.month, t.target
ORDER BY t.month;
```
```
lantern=# SELECT t.month, t.target, sum(o.net_revenue) AS actual,
lantern-#        round(100 * sum(o.net_revenue) / t.target) AS attainment_pct
lantern-# FROM semantic.revenue_target t
lantern-# JOIN semantic.orders o ON date_trunc('month', o.order_date) = t.month
lantern-# GROUP BY t.month, t.target
lantern-# ORDER BY t.month;
   month    |  target   |  actual   | attainment_pct 
------------+-----------+-----------+----------------
 2026-01-01 |  90000.00 |  87883.56 |             98
 2026-02-01 |  95000.00 |  88361.90 |             93
 2026-03-01 | 110000.00 | 117964.14 |            107
 2026-04-01 | 125000.00 | 119821.78 |             96
 2026-05-01 | 135000.00 | 140097.06 |            104
 2026-06-01 | 145000.00 |  75811.94 |             52
(6 rows)
```

March and May beat their targets; January, February and April fell a little short. June stands at
52%, and you know why: seventeen days of thirty. A tile showing June's attainment against the whole
month's target would turn red every month until its last days. Pro-rated to 17 of 30 days, June's target is
about R$ 82,167, and the R$ 75,811.94 so far is roughly 92% of it — short, and nothing like 52%.

## Colours that judge

Dashboards like to colour attainment: green above target, amber near it, red below. Three cautions,
and the first is about people rather than numbers:

- **Never rely on colour alone.** About one man in twelve has some form of colour vision deficiency,
  and red against green is the pair most often confused. Put the number or a word beside the colour:
  *104% — above target*.
- **Thresholds are definitions.** Who decided that 95% is amber and 90% is red? Write it on the card
  next to the target, with the owner, or two people will read the same amber differently.
- **A colour on a partial period lies.** June is red at 52% and on track at 92% pro rata. Either
  compare like with like, or colour nothing until the period closes.
