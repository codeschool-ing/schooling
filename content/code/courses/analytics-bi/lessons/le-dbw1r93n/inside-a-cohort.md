---
title: Why the November cohort stayed less
version: 1
---

A cohort grid says *that* a generation is different. To say *why*, split the cohort by something its
customers have in common, and compare each piece with the same piece in the other months. Lantern knows
the channel that brought each customer, so the question becomes: did Black Friday bring worse customers
everywhere, or bring a lot of one kind?

The measure here is simpler than the grid: the share of customers who ordered again within 90 days of
their first order. Only cohorts up to February 2026 are counted, so that every customer has had the full
90 days before the data ends — the censoring rule of the last section, applied once:

```
lantern=# WITH first AS (
lantern(#   SELECT customer_id, min(order_date) AS first_order
lantern(#   FROM semantic.orders WHERE status = 'paid' GROUP BY customer_id)
lantern-# SELECT date_trunc('month', f.first_order) = '2025-11-01' AS november,
lantern-#        c.acquisition_channel, count(*) AS customers,
lantern-#        round(100.0 * count(*) FILTER (WHERE EXISTS (
lantern(#          SELECT 1 FROM semantic.orders o
lantern(#          WHERE o.customer_id = f.customer_id AND o.status = 'paid'
lantern(#            AND o.order_date > f.first_order AND o.order_date <= f.first_order + 90))
lantern(#          / count(*), 1) AS again_within_90_days
lantern-# FROM first f JOIN semantic.customers c USING (customer_id)
lantern-# WHERE f.first_order < '2026-03-01'
lantern-# GROUP BY 1, 2 ORDER BY 1, 2;
 november | acquisition_channel | customers | again_within_90_days 
----------+---------------------+-----------+----------------------
 f        | email               |       193 |                 64.8
 f        | referral            |       276 |                 76.4
 f        | search              |       535 |                 66.2
 f        | social              |       355 |                 66.5
 t        | email               |        20 |                 65.0
 t        | referral            |        19 |                 68.4
 t        | search              |        53 |                 75.5
 t        | social              |       263 |                 43.0
(8 rows)
```

The answer is in one row. In every other month, customers who came from social media came back within
90 days 66.5% of the time, like those from e-mail and search. **In November, 263 of the 355 new customers
came from social media, and only 43.0% of them came back.** November's customers from search, e-mail and
referrals came back as well as anybody's.

So Black Friday did not bring worse customers in general. It brought a large number of customers through
one channel, in one campaign, and those stayed much less. That is a sentence somebody can act on — judge
the next campaign on its 90-day return rate by channel, not on the number of first orders — where *the
November cohort is weaker* was only a sentence somebody could worry about.

Two cautions about the small rows. November's e-mail and referral customers are 20 and 19 people; a
68.4% on 19 people is 13 people, and one more or one fewer moves it by five points. They say "no sign of
a problem", not "better than usual".
