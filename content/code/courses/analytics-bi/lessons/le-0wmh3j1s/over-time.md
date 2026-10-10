---
title: Time, and the day that is not there
version: 1
---

Almost every business number is a number per period, so the last column to explore is time. Two
things are worth knowing before any report is built on it: the **trend**, and the **holes**.

## The trend

```
lantern=# SELECT to_char(date_trunc('month', ordered_at), 'YYYY-MM') AS month,
lantern-#        count(*) AS orders, repeat('#', count(*)::int / 20) AS bar
lantern-# FROM orders GROUP BY 1 ORDER BY 1;
  month  | orders |                    bar                     
---------+--------+--------------------------------------------
 2025-01 |     12 | 
 2025-02 |     28 | #
 2025-03 |     62 | ###
 2025-04 |     86 | ####
 2025-05 |    143 | #######
 2025-06 |    178 | ########
 2025-07 |    237 | ###########
 2025-08 |    281 | ##############
 2025-09 |    325 | ################
 2025-10 |    412 | ####################
 2025-11 |    636 | ###############################
 2025-12 |    592 | #############################
 2026-01 |    619 | ##############################
 2026-02 |    598 | #############################
 2026-03 |    746 | #####################################
 2026-04 |    779 | ######################################
 2026-05 |    855 | ##########################################
 2026-06 |    513 | #########################
(18 rows)
```

Lantern grows almost every month, from 12 orders in January 2025 to 855 in May 2026. Three months
break the pattern, and each is a question for later rather than a conclusion now.

November 2025 jumps to 636, above the 592 of December after it: the shop ran a Black Friday
campaign, and lesson 9 follows the customers it brought. January 2026 barely moves. And June 2026
falls to 513 — **because the data ends on 17 June**. A month cut in half looks like a collapse on
every chart that draws it as a whole one, and lesson 10 treats it as the misleading picture it is.

## The holes

A day with no orders is either a quiet day or a day the data never arrived. Generating every date
in the period with `generate_series` and keeping the ones no order falls on finds them:

```
lantern=# SELECT d::date AS day, extract(isodow FROM d) AS weekday
lantern-# FROM generate_series(date '2025-04-01', date '2026-06-17', interval '1 day') AS d
lantern-# WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.ordered_at::date = d::date)
lantern-# ORDER BY 1;
    day     | weekday 
------------+---------
 2025-04-24 |       4
 2025-08-14 |       4
(2 rows)
```

Two days since April 2025. Neither is suspicious until you ask what a normal day looked like at
the time. In late April 2025 the shop took about three orders a day, so a Thursday with none is
plausible. The middle of August is another matter:

```
lantern=# SELECT ordered_at::date AS day, count(*) AS orders
lantern-# FROM orders
lantern-# WHERE ordered_at::date BETWEEN '2025-08-07' AND '2025-08-21'
lantern-# GROUP BY 1 ORDER BY 1;
    day     | orders 
------------+--------
 2025-08-07 |     10
 2025-08-08 |     12
 2025-08-09 |      9
 2025-08-10 |      5
 2025-08-11 |     12
 2025-08-12 |     10
 2025-08-13 |      6
 2025-08-15 |     10
 2025-08-16 |     15
 2025-08-17 |      9
 2025-08-18 |     13
 2025-08-19 |     11
 2025-08-20 |     13
 2025-08-21 |      9
(14 rows)
```

Every other day of those two weeks has between 5 and 15 orders. A day with zero, on a Thursday, in
the middle of them, is not a quiet day. **It is a missing extract**: the pipeline that copies
orders into this database failed for 14 August 2025, and nobody noticed. Any monthly total for
August 2025 is short by roughly a day's orders, and a daily chart drawn from this table shows a
crash that never happened.

The fix is upstream, in the load. Your job, in exploratory analysis, is to find the hole and say
so before somebody reads it as a fact about customers.

## The week

```
lantern=# SELECT extract(isodow FROM ordered_at) AS weekday, to_char(ordered_at, 'Dy') AS name,
lantern-#        count(*) AS orders
lantern-# FROM orders GROUP BY 1, 2 ORDER BY 1;
 weekday | name | orders 
---------+------+--------
       1 | Mon  |   1495
       2 | Tue  |   1009
       3 | Wed  |   1070
       4 | Thu  |    962
       5 | Fri  |   1010
       6 | Sat  |   1019
       7 | Sun  |    537
(7 rows)
```

Sunday has about half the orders of a weekday, and Monday has about half as many again as any
other weekday. **A pattern like that changes what a daily comparison means**: over the whole period Mondays carry 178% more orders than
Sundays, so a report that compares a Monday with the day before it describes the calendar rather
than the business. Comparing a day with the same weekday a week earlier removes it — lesson 6 uses
exactly that comparison on a dashboard.
