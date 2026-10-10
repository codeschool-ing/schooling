---
title: A cohort is a generation of customers
version: 1
---

A **cohort** is a group of customers who started at the same time — here, the month of their first paid
order. The point of grouping them that way is that it separates two things a total mixes: how many
customers arrive, and how well they stay. A shop can grow every month while each new generation stays
less than the last, and the total will not show it until the arrivals slow down.

Lantern's cohorts, by size:

```
lantern=# SELECT date_trunc('month', first_order)::date AS cohort, count(*) AS customers
lantern-# FROM (SELECT customer_id, min(order_date) AS first_order
lantern(#       FROM semantic.orders WHERE status = 'paid' GROUP BY customer_id) f
lantern-# GROUP BY 1 ORDER BY 1;
   cohort   | customers 
------------+-----------
 2025-01-01 |         8
 2025-02-01 |        19
 2025-03-01 |        38
 2025-04-01 |        45
 2025-05-01 |        68
 2025-06-01 |        85
 2025-07-01 |       113
 2025-08-01 |       119
 2025-09-01 |       118
 2025-10-01 |       158
 2025-11-01 |       355
 2025-12-01 |       184
 2026-01-01 |       201
 2026-02-01 |       203
 2026-03-01 |       250
 2026-04-01 |       237
 2026-05-01 |       258
 2026-06-01 |       165
(18 rows)
```

The shop grows steadily through 2025 and into 2026, with one exception: **November 2025 has 355 new
customers**, twice October's 158 and almost twice December's 184. That is the Black Friday campaign
lesson 1 found in the orders and lesson 2 promised to follow: *how many of them stayed?*

Two other cohorts need a warning before anything is read from them. **January and February 2025 are
tiny** — 8 and 19 customers — so a percentage computed on them moves by 5 or 12 points for every customer
who returns or does not. And **June 2026 is not a whole month**: the data ends on 17 June, so the cohort
is the customers of seventeen days, and it has had no time to come back at all.

There are other ways to cut a cohort — by the week of sign-up, by the first product bought, by the
channel that brought them — and the choice depends on the question. *Did Black Friday bring good
customers?* is a question about the month of the first order, so that is the cut here.
