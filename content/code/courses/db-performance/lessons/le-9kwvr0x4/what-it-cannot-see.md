---
title: What the tally cannot see
version: 1
---

A tool that answers quickly and confidently is the one whose blind spots matter most, because
nobody goes looking for them. `pg_stat_statements` has five, and each one has misled somebody.

## It does not know who waited

`total_exec_time` is time spent **executing**, from the server's side. Time a statement spent
queued behind a lock is inside it — the server was executing, it was just waiting — but time the
application spent waiting for a free connection, or for the network, is not. A statement can look
cheap in the tally while the users of the screen behind it wait seconds, because the queue was in
front of the server rather than inside it. Lesson 16 is about exactly that queue.

## It does not keep the values

The constants are taken out on purpose, and with them goes the answer to "slow for whom?". In
`market`, seller 1 has a quarter of all orders and the other 999 share the rest: a dashboard query
for seller 1 reads hundreds of times more rows than one for seller 42, and the tally stores them
as one statement with one mean. The `stddev_exec_time` and `max_exec_time` columns are the hint
that a mean is hiding two populations; the log, which keeps the values, is how you find which.
That is why the workload's `seller-dashboard.sql` draws its seller from 2 to 1000 and leaves seller
1 out: lesson 7 is about what that one seller does to the planner's estimates.

## It forgets

The view holds a fixed number of distinct statements, set by `pg_stat_statements.max`:

```
market=# SHOW pg_stat_statements.max;
 pg_stat_statements.max 
------------------------
 5000
(1 row)

Time: 0.770 ms

market=# SELECT dealloc, stats_reset FROM pg_stat_statements_info;
 dealloc |          stats_reset          
---------+-------------------------------
       0 | 2026-10-10 04:25:37.909729-03
(1 row)

Time: 1.187 ms
```

**5000**, and when a new statement arrives with the table full, the least-used entries are thrown
away, and `dealloc` in `pg_stat_statements_info` counts how many times that happened. Zero here. On
an application that builds SQL by gluing values into strings instead of passing parameters, every
different value can be a different statement, the table churns, and the rare expensive query is
exactly the kind that gets evicted. A `dealloc` that keeps climbing is a symptom worth chasing for
its own sake.

`stats_reset` is the other half of the same caution: the moment the tally started. Two numbers
read from it are comparable only if they count from the same moment.

## It does not see the machine

The tally says a statement read 1181 pages from the operating system; it does not say whether
those came from the operating system's cache in memory or from the disk, which lesson 1 section 06
showed can be a factor of three or more. Nor does it see a backup running at the same time, or
another program on the same machine taking the processors. For the third suspect you look at the
machine itself, which lessons 16 and 23 do.

## It counts what reached the server

A statement that never ran is not in it. An application that gives up after two seconds and shows
an error has a complaint and possibly no row at all, if the server cancelled the statement before
it finished. And an application that runs a hundred tiny queries to draw one page — the N+1 shape
`sql-databases` lesson 11 described — shows up as one cheap statement with a very large `calls`,
which sorting by total puts near the top only if the total is large. **Read `calls` as well as
time**: a cheap statement called a hundred times per page is a design problem, and no index will
make it go away.
