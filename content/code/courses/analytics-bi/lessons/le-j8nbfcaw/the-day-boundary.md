---
title: Where a day begins
version: 1
---

The time part of a definition has a detail that produces more disagreements than any other: **a
day is a period in some time zone**, and a timestamp belongs to a different day depending on which.
Lantern's database is set to São Paulo. Here is the first full week of May 2026, counted by São
Paulo's days:

```
lantern=# SELECT ordered_at::date AS day, to_char(ordered_at, 'Dy') AS name, count(*) AS orders
lantern-# FROM orders WHERE ordered_at::date BETWEEN '2026-05-04' AND '2026-05-10'
lantern-# GROUP BY 1, 2 ORDER BY 1;
    day     | name | orders 
------------+------+--------
 2026-05-04 | Mon  |     42
 2026-05-05 | Tue  |     23
 2026-05-06 | Wed  |     33
 2026-05-07 | Thu  |     23
 2026-05-08 | Fri  |     31
 2026-05-09 | Sat  |     34
 2026-05-10 | Sun  |     15
(7 rows)
```

And the same orders, counted by UTC's days, as a tool running on a server in UTC would count them
unless told otherwise:

```
lantern=# SET timezone = 'UTC';
SET

lantern=# SELECT ordered_at::date AS day, to_char(ordered_at, 'Dy') AS name, count(*) AS orders
lantern-# FROM orders WHERE ordered_at::date BETWEEN '2026-05-04' AND '2026-05-10'
lantern-# GROUP BY 1, 2 ORDER BY 1;
    day     | name | orders 
------------+------+--------
 2026-05-04 | Mon  |     35
 2026-05-05 | Tue  |     32
 2026-05-06 | Wed  |     24
 2026-05-07 | Thu  |     28
 2026-05-08 | Fri  |     29
 2026-05-09 | Sat  |     35
 2026-05-10 | Sun  |     21
(7 rows)
```

Every single day is different, and even the week's total moves, from 201 to 204, because the week
itself starts and ends at a different moment. Monday falls from 42 to 35, Tuesday
rises from 23 to 32. **The weekly pattern lesson 1 found, the busy Monday, is partly an artefact
of which clock is used.** The reason is that São Paulo is three hours behind UTC, so every order
placed after 21:00 local time is already the next day in UTC, and Lantern's customers order late:

```
lantern=# SELECT count(*) FILTER (WHERE extract(hour FROM ordered_at) >= 21) AS after_21h,
lantern-#        count(*) AS orders
lantern-# FROM orders;
 after_21h | orders 
-----------+--------
      2278 |   7102
(1 row)
```

2,278 of 7,102 orders, almost a third, change day between the two clocks. The same thing happens
at the edge of every month and every quarter, more gently because the edge is a smaller share of
a longer period:

```
lantern=# SELECT current_setting('timezone') AS zone, count(*) AS orders,
lantern-#        round(sum(gross_cents) / 100.0, 2) AS gross
lantern-# FROM order_totals WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01';
       zone        | orders |   gross   
-------------------+--------+-----------
 America/Sao_Paulo |   1963 | 329036.20
(1 row)

lantern=# SET timezone = 'UTC';
SET

lantern=# SELECT current_setting('timezone') AS zone, count(*) AS orders,
lantern-#        round(sum(gross_cents) / 100.0, 2) AS gross
lantern-# FROM order_totals WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01';
 zone | orders |   gross   
------+--------+-----------
 UTC  |   1962 | 329250.80
(1 row)
```

The count differs by one order and the value by R$ 214.60: orders cross the boundary in both
directions, at both ends of the quarter, and what is left is the net of the crossings. That is the
size of a difference that makes two people who should agree spend an afternoon
finding it.

The fix is a sentence in the definition — **days are São Paulo days** — and a mechanism that
enforces it. Lantern's mechanism is the setting on the database from lesson 1, which applies to
every session; a BI tool has its own report time zone, and lesson 3 checks that Metabase's agrees.
A timestamp column that stores the moment with its zone, `timestamptz` in PostgreSQL, is what
makes the choice possible at all: a column that stores a local time with no zone has already made
the choice, and nobody wrote down which.
