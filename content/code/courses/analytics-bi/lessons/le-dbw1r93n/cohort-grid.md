---
title: The cohort grid, done wrong first
version: 1
---

A **cohort grid** puts one cohort on each row and the months since it started on the columns. Each cell
is the share of the cohort that ordered again in that month: `m1` is the month after the first order,
`m3` three months later. Read across a row and you follow one generation as it ages; read down a column
and you compare generations at the same age.

The query has three steps. `paid` keeps one row per customer per month in which they paid for an order;
`cohort` finds each customer's first month; `activity` measures how many months after it each later
month is, as `k`. The grid then counts, for each cohort, the customers active at each `k`. Here it is for
the cohorts from October 2025 on:

```
lantern=# WITH paid AS (
lantern(#   SELECT DISTINCT customer_id, date_trunc('month', order_date)::date AS month
lantern(#   FROM semantic.orders WHERE status = 'paid'),
lantern-# cohort AS (SELECT customer_id, min(month) AS cohort FROM paid GROUP BY customer_id),
lantern-# activity AS (
lantern(#   SELECT c.cohort, p.customer_id,
lantern(#          (12 * (extract(year FROM p.month) - extract(year FROM c.cohort))
lantern(#           + extract(month FROM p.month) - extract(month FROM c.cohort))::int AS k
lantern(#   FROM paid p JOIN cohort c USING (customer_id))
lantern-# SELECT cohort, count(*) FILTER (WHERE k = 0) AS size,
lantern-#        round(100.0 * count(*) FILTER (WHERE k = 1) / count(*) FILTER (WHERE k = 0), 1) AS m1,
lantern-#        round(100.0 * count(*) FILTER (WHERE k = 2) / count(*) FILTER (WHERE k = 0), 1) AS m2,
lantern-#        round(100.0 * count(*) FILTER (WHERE k = 3) / count(*) FILTER (WHERE k = 0), 1) AS m3,
lantern-#        round(100.0 * count(*) FILTER (WHERE k = 6) / count(*) FILTER (WHERE k = 0), 1) AS m6
lantern-# FROM activity
lantern-# WHERE cohort >= '2025-10-01'
lantern-# GROUP BY cohort ORDER BY cohort;
   cohort   | size |  m1  |  m2  |  m3  |  m6  
------------+------+------+------+------+------
 2025-10-01 |  158 | 43.7 | 37.3 | 29.1 | 14.6
 2025-11-01 |  355 | 31.8 | 25.1 | 14.1 |  8.5
 2025-12-01 |  184 | 41.3 | 32.6 | 34.8 |  9.8
 2026-01-01 |  201 | 42.3 | 35.3 | 28.4 |  0.0
 2026-02-01 |  203 | 48.3 | 37.9 | 29.1 |  0.0
 2026-03-01 |  250 | 43.6 | 33.6 | 22.8 |  0.0
 2026-04-01 |  237 | 46.4 | 23.2 |  0.0 |  0.0
 2026-05-01 |  258 | 25.6 |  0.0 |  0.0 |  0.0
 2026-06-01 |  165 |  0.0 |  0.0 |  0.0 |  0.0
(9 rows)
```

Read the November row against its neighbours: 31.8% came back in the first month, against 43.7% for
October and 41.3% for December; 14.1% in the third month, against 29.1% and 34.8%. **Black Friday's
customers stayed less, and by the third month about half as well.** That is the answer the cohort was built for, and it is right.

The rest of the grid has a problem, and it is in the corner. Look at the bottom rows: June 2026 shows
**0.0** in every column, May shows 0.0 from the second month, and every cohort from January shows 0.0 at
six months. Read as numbers, the newest customers are the worst Lantern has ever had — nobody comes back
at all.

They have not had the chance. A customer whose first order was in May 2026 cannot have ordered in
August 2026, because August has not happened yet; the data ends on 17 June. The query counted *no
orders* where the truth is *no time*. And May's first month, 25.6%, is not wrong in the same way but is
wrong too: its first month is June, which is only seventeen days old.

**A cell that has not finished happening is not zero. It is unknown.** The next section makes the grid
say so.
