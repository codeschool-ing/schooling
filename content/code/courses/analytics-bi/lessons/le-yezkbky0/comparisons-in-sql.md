---
title: Comparisons in SQL, and the right one to make
version: 1
---

A BI tool computes comparisons with a setting; it is worth seeing once what the setting does. The
previous month's value beside each month is a window function, `lag`, which reads the row before in
the order you give it:

```sql
WITH m AS (
  SELECT date_trunc('month', order_date)::date AS month, sum(net_revenue) AS net_revenue
  FROM semantic.orders GROUP BY 1
)
SELECT month, net_revenue,
       lag(net_revenue) OVER (ORDER BY month) AS previous_month,
       round(100 * (net_revenue / lag(net_revenue) OVER (ORDER BY month) - 1), 1) AS change_pct
FROM m
WHERE month >= '2026-01-01'
ORDER BY month;
```

```
lantern=# WITH m AS (
lantern(#   SELECT date_trunc('month', order_date)::date AS month, sum(net_revenue) AS net_revenue
lantern(#   FROM semantic.orders GROUP BY 1
lantern(# )
lantern-# SELECT month, net_revenue,
lantern-#        lag(net_revenue) OVER (ORDER BY month) AS previous_month,
lantern-#        round(100 * (net_revenue / lag(net_revenue) OVER (ORDER BY month) - 1), 1) AS change_pct
lantern-# FROM m
lantern-# WHERE month >= '2026-01-01'
lantern-# ORDER BY month;
   month    | net_revenue | previous_month | change_pct 
------------+-------------+----------------+------------
 2026-01-01 |    87883.56 |                |           
 2026-02-01 |    88361.90 |       87883.56 |        0.5
 2026-03-01 |   117964.14 |       88361.90 |       33.5
 2026-04-01 |   119821.78 |      117964.14 |        1.6
 2026-05-01 |   140097.06 |      119821.78 |       16.9
 2026-06-01 |    75811.94 |      140097.06 |      -45.9
(6 rows)
```

Every month of 2026 in one view, with its change. March jumped 33.5%; February barely moved. And then
June: **−45.9%**. Hold that number; the next section takes it apart.

## Days, and the week inside them

A daily comparison has its own trap, which lesson 1 found: Sundays carry about half a weekday's
orders. Comparing a day with the day before compares the calendar:

```
lantern=# SELECT k.day, to_char(k.day, 'Dy') AS name, count(o.order_id) AS orders
lantern-# FROM semantic.calendar k LEFT JOIN semantic.orders o ON o.order_date = k.day
lantern-# WHERE k.day IN ('2026-06-07', '2026-06-08', '2026-06-14', '2026-06-15')
lantern-# GROUP BY k.day ORDER BY k.day;
    day     | name | orders 
------------+------+--------
 2026-06-07 | Sun  |     15
 2026-06-08 | Mon  |     38
 2026-06-14 | Sun  |     10
 2026-06-15 | Mon  |     43
(4 rows)
```

Monday 15 June against Sunday 14 June is 43 against 10, more than four times as many — and means
nothing. Against the previous Monday, 8 June, it is 43 against 38, which is a real if small rise.
**Compare a day with the same weekday a week earlier**, and a week with the same week a year
earlier when there is a year to compare with. A tool's built-in comparison is usually with the
previous period, and the previous period is not always the right one.
