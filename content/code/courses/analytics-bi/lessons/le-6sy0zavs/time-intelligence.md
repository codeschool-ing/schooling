---
title: Time intelligence, and what it needs
version: 1
---

The comparisons a business asks for most are against time: the year so far, the same month last
year. DAX has functions for both, and they work only with a marked date table, which is why the
model's `calendar` matters:

```
Net Revenue YTD = TOTALYTD ( [Net Revenue], calendar[day] )

Net Revenue Same Month Last Year =
    CALCULATE ( [Net Revenue], SAMEPERIODLASTYEAR ( calendar[day] ) )
```

(Not run.) `TOTALYTD` changes the filter context to "every day from the first of January up to the
last day in the current context"; `SAMEPERIODLASTYEAR` shifts the current days back a year. The SQL
for the first is a running sum, a window function ordered by month:

```
lantern=# SELECT k.month,
lantern-#        sum(o.net_revenue) AS net_revenue,
lantern-#        sum(sum(o.net_revenue)) OVER (ORDER BY k.month) AS net_revenue_ytd
lantern-# FROM semantic.orders o JOIN semantic.calendar k ON k.day = o.order_date
lantern-# WHERE k.month >= '2026-01-01'
lantern-# GROUP BY k.month ORDER BY k.month;
   month    | net_revenue | net_revenue_ytd 
------------+-------------+-----------------
 2026-01-01 |    87883.56 |        87883.56
 2026-02-01 |    88361.90 |       176245.46
 2026-03-01 |   117964.14 |       294209.60
 2026-04-01 |   119821.78 |       414031.38
 2026-05-01 |   140097.06 |       554128.44
 2026-06-01 |    75811.94 |       629940.38
(6 rows)
```

The year-to-date column reaches R$ 294,209.60 at the end of March, the quarter finance and Metabase
both reached. And the comparison with last year:

```
lantern=# SELECT k.month,
lantern-#        sum(o.net_revenue) AS net_revenue,
lantern-#        (SELECT sum(o2.net_revenue) FROM semantic.orders o2
lantern(#          WHERE o2.order_date >= k.month - interval '1 year'
lantern(#            AND o2.order_date < k.month - interval '1 year' + interval '1 month') AS same_month_last_year
lantern-# FROM semantic.orders o JOIN semantic.calendar k ON k.day = o.order_date
lantern-# WHERE k.month BETWEEN '2026-03-01' AND '2026-05-01'
lantern-# GROUP BY k.month ORDER BY k.month;
   month    | net_revenue | same_month_last_year 
------------+-------------+----------------------
 2026-03-01 |   117964.14 |              9769.26
 2026-04-01 |   119821.78 |             10706.84
 2026-05-01 |   140097.06 |             21811.31
(3 rows)
```

March 2026 is more than twelve times March 2025. That is not a misprint: the shop opened in January
2025, so every comparison with last year compares a business with its own first months. **A
year-on-year growth figure from a business that is barely a year old describes its birth, not its
performance**, and a dashboard that shows it in large type invites a celebration nobody should have.
Lesson 10 returns to it.

Two things the functions do that the SQL above makes you decide explicitly:

- **What "same period" means in a partial month.** `SAMEPERIODLASTYEAR` in a context of 1 to 17 June
  2026 returns 1 to 17 June 2025. The SQL above compares whole months; in June that would compare 17
  days with 30.
- **Where the year starts.** `TOTALYTD` takes an optional year-end date for a fiscal year that does
  not end in December. Lantern's ends in December, and the default is right.
