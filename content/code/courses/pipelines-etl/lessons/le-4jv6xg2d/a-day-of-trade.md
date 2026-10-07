---
title: A day of trade, on demand
version: 1
---

**A pipeline exists because the source keeps changing.** A lab whose database never moved would
teach you to copy a table once, which is not the job. So the shop in this lab has a clock, and you
are the one who turns it.

When the lab is built, the shop's database stands where it stood on the night of 28 February
2026:

```
ana@vm:~/etl$ psql -c "SELECT (SELECT count(*) FROM customers) AS customers, (SELECT count(*) FROM orders) AS orders, (SELECT max(ordered_at) FROM orders) AS last_order"
 customers | orders |       last_order       
-----------+--------+------------------------
      5079 |  17012 | 2026-02-28 23:57:44-03
(1 row)
```

March has not happened yet. `shop day` plays one day of it:

```
ana@vm:~/etl$ sudo shop day 2026-03-01
ana@vm:~/etl$ psql -c "SELECT (SELECT count(*) FROM customers) AS customers, (SELECT count(*) FROM orders) AS orders, (SELECT max(ordered_at) FROM orders) AS last_order"
 customers | orders |       last_order       
-----------+--------+------------------------
      5098 |  17195 | 2026-03-01 23:50:30-03
(1 row)

ana@vm:~/etl$ ls -l landing/events inbox
inbox:
total 52
-rw-r--r-- 1 ana ana 51310 Oct  7 05:20 stock_2026-03-01.csv

landing/events:
total 316
-rw-r--r-- 1 ana ana 321982 Oct  7 05:20 2026-03-01.jsonl
```

Nineteen new customers and 183 new orders. Two files have also appeared: the website's click
events for the day, and the distributor's stock file, dropped in the inbox the way a supplier
would drop it on a server. Those are two more kinds of source, and lesson 3 is about all four.

## What a day is made of

The day is not a pile of rows. It is the transactions the tills, the website and the back office
ran, in the order they ran them, each with its own timestamps:

```
ana@vm:~/etl$ grep -c "^BEGIN" /var/lib/etl-data/days/2026-03-01.sql
211
ana@vm:~/etl$ grep -oE "^(INSERT INTO|UPDATE|DELETE FROM) [a-z_]+" /var/lib/etl-data/days/2026-03-01.sql | sort | uniq -c
     19 INSERT INTO customers
    272 INSERT INTO order_lines
    183 INSERT INTO orders
    183 INSERT INTO payments
      4 UPDATE customers
      5 UPDATE orders
```

**The two `UPDATE` lines are the ones that make this a pipeline course.** Four customers moved
city, and five orders from earlier days were cancelled or refunded. A copy taken on the 28th is now
wrong about rows nobody inserted today. On some days the back office also deletes a customer who
asked to be forgotten. Lessons 4 and 5 are about finding changes like these without reading the
whole database again.

## The clock only goes forward

```
ana@vm:~/etl$ sudo shop day 2026-03-01
the shop has lived up to 2026-03-01: the next day to play is 2026-03-02
```

A day can be played once, in order, as in the world. **To go back, you reset** — `sudo shop reset`
returns the shop to the 28th and empties everything the pipelines wrote. `sudo shop until
2026-03-07` plays a week in one go when a lesson needs history to work on.

This is the lab's answer to a problem no other course here has: **a scheduled job needs time to
pass**, and nobody waits a month to see a monthly report run. The shop's time moves when you say
so. Airflow's time, from lesson 9, is the date a run is *for*, which you also choose — so a month
of nightly runs can be lived in a few minutes and still be the month it says it is.
