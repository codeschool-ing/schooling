---
title: What partitioning is for, and what it is not
version: 1
---

The belief to replace first: **partitioning makes a big table fast.** It sounds right: a query
on one month should be quicker in a table that holds one month than in a table that holds three.
It is the reason most people reach for it. It is also wrong often enough to cost a project. A
partitioned table is several tables behind one name, and that buys two things: **dropping or moving
a whole slice is cheap**, and **a query that names the slice can skip the others**. Everything else
it does costs something, and some queries get slower.

## The job it does best: getting rid of old rows

`events` holds ninety days of clicks. A real one would hold more every day, and the oldest days
would have to go: the privacy policy says how long a click may be kept, or the disk says it for
you. On a table that is one table, removing a month is a `DELETE`. Try it inside a transaction, so
that it can be undone, and measure how much WAL it writes — the server's log of every change, which
`db-administration` covers and which every replica and backup has to receive:

```
market=# BEGIN;
BEGIN
Time: 0.501 ms

market=*# SELECT pg_current_wal_lsn() AS before \gset
Time: 0.716 ms

market=*# DELETE FROM events WHERE at < '2025-11-01';
DELETE 1611210
Time: 2968.929 ms (00:02.969)

market=*# SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before')) AS wal_written;
 wal_written 
-------------
 251 MB
(1 row)

Time: 1.116 ms

market=*# ROLLBACK;
ROLLBACK
Time: 0.734 ms
```

**1611210 rows, three seconds, 251 MB of WAL**, and the `ROLLBACK` put them all back. Had it been
committed, the three seconds and the 251 MB would only have been the start. Each deleted row is
a dead version that `VACUUM` has to visit and remove, lesson 15's subject. The indexes still point
at every one of them until it does. And the table's file does not shrink: the space is reused by
later rows rather than returned. On a table that grows every day, that `DELETE` runs every day.

On a table partitioned by month, October is its own table, and removing it is removing a table.
Section 05 of this lesson does it and measures it against these numbers.

## The other job: not reading what the question does not need

When a query's `WHERE` says which slice it wants, the planner can leave the other partitions out
of the plan altogether. That is **partition pruning**, and it is lesson 18's whole subject, including
the queries that cannot do it. Here it is enough to know that it is the second reason, and that it
only helps a query whose condition is on the column the table is partitioned by.

## What it costs

A partitioned table has no storage of its own. Every row lives in exactly one partition, chosen by
the **partition key**, and every query is planned against the partitions it might touch. Three
costs follow, and this lesson meets each of them:

- **A query that does not name the key reads every partition.** Looking an event up by its `id`
  is one index probe on `events`; on a table cut by month it is one probe per month, because nothing
  in the `id` says which month it belongs to. Section 03 measures it.
- **Uniqueness only works through the key.** A primary key on a partitioned table has to include
  the partition key, so an `id` that is unique on its own can no longer be declared so. Section 06
  shows the error.
- **More partitions, more planning.** The planner works out which partitions a query needs before
  it runs it, and that work grows with the count. Lesson 18 measures four against three hundred and
  sixty-five.

## When it is worth it

Partitioning earns its costs when a table has **a natural slice that is also how it ages**: events,
logs, readings, orders by month — rows that arrive in time order and leave in time order, and that
most questions ask about a recent window of. It rarely earns them on a table like `customers`,
whose rows do not age and whose questions are about one customer at a time; an index answers
those better.

The size people quote, "partition above some number of gigabytes", is a proxy for the same
question. The useful version is concrete: **what is the `DELETE` you run every night, and how long
does it take?** If the answer is "none", or "a few seconds", partitioning is a cost without the
benefit it is for. If the answer is "an hour, and it fights with everything else", the next section
is how the table should have been built.
