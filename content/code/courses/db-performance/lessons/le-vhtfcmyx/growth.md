---
title: Growth, measured from what is already there
version: 1
---

The first question of capacity planning sounds like it needs a crystal ball — how big will this
database be next year? — and almost never does. **The database already contains its own history.**
Every row with a date on it is a record of when it arrived, and counting them by month is the
growth rate, measured rather than guessed.

`orders` has `placed_at`. Count the last year by month:

```
market=# SELECT date_trunc('month', placed_at)::date AS month, count(*) AS orders FROM orders WHERE placed_at >= '2025-01-01' GROUP BY 1 ORDER BY 1;
   month    | orders 
------------+--------
 2025-01-01 |  77177
 2025-02-01 |  73093
 2025-03-01 |  82945
 2025-04-01 |  84240
 2025-05-01 |  89903
 2025-06-01 |  89500
 2025-07-01 |  95909
 2025-08-01 |  99337
 2025-09-01 |  99072
 2025-10-01 | 105273
 2025-11-01 | 105503
 2025-12-01 | 107780
(12 rows)

Time: 511.996 ms
```

From 77177 orders in January to 107780 in December: the shop is growing, and not by a fixed
percentage — the months go up by roughly the same **two to three thousand orders** each, with
February's dip because February is short. That is a linear trend, and a linear trend is the easy
kind: next December is about another 30 thousand orders a month higher. A shop growing by a
percentage, doubling every year, would curve upwards on the same table, and the forecast below would
have to be done with that curve rather than a straight line.

Two warnings about reading a table like this. **A month is not a unit of work**: a Black Friday
weekend can carry a month's orders in three days, and a database that copes with the average month
can still fall over on the peak. And **the history only covers what the application records**: a
new feature that writes a table nobody had before has no history to measure, and its growth has to
be estimated from the feature instead.

## From rows to bytes

Rows are not what fills a disk. Bytes are, and the conversion is a measurement too:

```
market=# SELECT relname, reltuples::bigint AS rows, pg_size_pretty(pg_total_relation_size(oid)) AS with_indexes, round(pg_total_relation_size(oid) / reltuples) AS bytes_per_row FROM pg_class WHERE relname IN ('orders', 'order_lines', 'events') ORDER BY relname;
   relname   |  rows   | with_indexes | bytes_per_row 
-------------+---------+--------------+---------------
 events      | 4999827 | 618 MB       |           130
 order_lines | 4999992 | 432 MB       |            91
 orders      | 2000000 | 247 MB       |           130
(3 rows)

Time: 3.596 ms
```

**130 bytes per order** and 91 per order line, counting each table's indexes along with it. That is
the number to multiply by: it includes the row itself, the bookkeeping PostgreSQL keeps on every
row, the free space inside pages, and every index — which is why it is more than the five columns of
an order would suggest. Measured on the table as it is, it already includes whatever indexes the
application has built, and it changes when somebody adds another.

So the shop's orders grow by about 108 thousand rows a month, and order lines by two and a half
times that:

| table | rows a month | bytes a row | a month |
|---|---|---|---|
| `orders` | 108 000 | 130 | 14 MB |
| `order_lines` | 270 000 | 91 | 25 MB |
| `events` | 1 670 000 | 130 | 217 MB |

The events are the surprise, and the reason to do the sum rather than assume. They are a log of
clicks: five million in ninety days, a million and two-thirds a month, and **they grow the database
more than everything else together**. A forecast built on orders alone would be off by a factor of
six.

## How long until the disk is full

```
ana@vm:~$ df -h /var/lib/postgresql
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   17G   23G  43% /
```

This is the recording computer, not a virtual machine like yours, and its disk is shared with
everything else on it, so the numbers are only an example: 23 GB available. At about 256 MB a month,
the database fills that in **about ninety months** — seven and a half years, if nothing else
changes. Your virtual machine's 30 GB disk, with Ubuntu, the database and its copy on it, will show
a different `Avail`, and the same sum works on it.

"If nothing else changes" is doing a lot of work in that sentence, and the next three sections are
about what it hides. Write-ahead log, temporary files from a large sort, a copy made by a lesson
like `market_base`, and a backup written to the same disk all take space that grows with the
database without being rows in it. A forecast on rows is a lower bound; the alert in this lesson's
last section is what keeps it honest.
