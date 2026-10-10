---
title: An alert that arrives before the wall
version: 1
---

An alert is a promise that somebody will be woken up in time. Most capacity alerts break that
promise in the same way: they fire on a **percentage**. "Disk above 80%" sounds prudent and says
nothing about time. On a disk that took five years to reach 80%, it is a notice for next quarter's
budget; on one that went from 50% to 80% since Monday, the database will stop before anybody reads
the e-mail.

**What an alert should measure is the time left**: how far the thing is from its wall, divided by
how fast it is moving towards it. The growth section did that sum once, by hand, for the disk. An
alert does it every hour.

## One query for the walls the database can see

This file reads, in one pass, every wall the database can see from inside, with how much is used,
the limit and the percentage:


```sql
-- capacity.sql: how close market is to each wall it can see from inside.
-- Run it on a schedule, keep the rows, and alert on the trend.
SELECT wall, used, lim, round(100 * used / lim, 2) AS pct
FROM (
  SELECT 'connections' AS wall,
         (SELECT count(*) FROM pg_stat_activity
           WHERE backend_type = 'client backend')::numeric AS used,
         current_setting('max_connections')::numeric AS lim
  UNION ALL
  SELECT 'transaction id age', age(datfrozenxid), 2000000000
    FROM pg_database WHERE datname = current_database()
  UNION ALL
  SELECT 'sequence ' || sequencename, last_value, max_value
    FROM pg_sequences WHERE last_value IS NOT NULL
  UNION ALL
  SELECT 'largest total_cents', max(total_cents), 2147483647 FROM orders
) AS walls
ORDER BY pct DESC;
```

Save it in your home directory as `capacity.sql` and run it:

```
ana@vm:~$ psql market -f capacity.sql
           wall            |  used   |         lim         | pct  
---------------------------+---------+---------------------+------
 connections               |       1 |                 100 | 1.00
 transaction id age        |  526533 |          2000000000 | 0.03
 sequence customers_id_seq |  200000 |          2147483647 | 0.01
 sequence orders_id_seq    | 2016623 | 9223372036854775807 | 0.00
 sequence events_id_seq    | 5000000 | 9223372036854775807 | 0.00
 largest total_cents       |   50499 |          2147483647 | 0.00
 sequence sellers_id_seq   |    1000 |          2147483647 | 0.00
 sequence products_id_seq  |   50000 |          2147483647 | 0.00
(8 rows)

Time: 162.050 ms
EXIT 0
```

Everything is far from its wall on a database that has been running for an afternoon, and that is
the point of reading it now: the numbers you will compare against later have to be written down
while they are boring. `transaction id age` is measured against two billion, the point where the
server refuses new transactions, rather than against the 200 million where autovacuum steps in —
an alert on that one is about whether freezing is keeping up, and the trend is what matters.

## Turning a snapshot into a trend

One run of `capacity.sql` is a snapshot. The alert needs two snapshots and the time between them,
which means keeping them: a table in a database that is not the one being watched, filled by a job
every hour, or the monitoring system your company already has, which almost certainly can run a
query on a schedule and store what comes back. Then the rule for each wall is the same sum:

```localised
time left  =  (limit − used now)  ÷  (growth per day)
```

and the alert fires when the time left falls below **how long the fix takes plus a margin**. That
last clause is what makes each threshold different:

| wall | the fix | alert when time left is under |
|---|---|---|
| disk | order and attach a bigger disk, or archive | two to four weeks |
| connections | a pooler, or a code change in the application | days, so a second signal on the rate of refused connections |
| transaction counter | find what is stopping freezing, then vacuum | a week before the 200 million where autovacuum forces it |
| an `integer` sequence | migrate the key to `bigint` | a year |

The sequence's year is not a typo. Changing a key's type rewrites the table and everything that
refers to it, and doing that calmly takes planning, testing and a maintenance window: an alert
that gave a month's notice would be an alert that gave no notice at all.

## Two alerts that are not about walls

The knee from the headroom section is not a wall, and it needs a different alert. **Alert on the
latency users see** — the 95th or 99th percentile of the application's requests — rather than on
how busy the server is, because the server was running at nine tenths of its maximum rate when the
slowest transactions were already waiting two thirds of a second. And alert on **change**, not only on
level: a query that took 10 milliseconds yesterday and 40 today has not hit anything yet, and it
is the first sign of the statistics going stale (lesson 6) or a table growing past the point where
its plan made sense (lesson 4).

`db-reliability` lesson 13 alerts on replication lag the same way, and `db-administration` lesson
14 on autovacuum falling behind. What they share with this lesson is the rule: **an alert is worth
its noise only if it arrives while there is still time to do something calm**.
