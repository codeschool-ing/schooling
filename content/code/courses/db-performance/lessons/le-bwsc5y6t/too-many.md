---
title: Too many partitions
version: 1
---

If one partition a month is good, one a day must be better: a query about one day would read a
thirtieth of what it reads now. That is the reasoning that ends with thousands of partitions, and
it leaves out the cost lesson 17 named and section 04 showed: **every query that cannot prune pays
for every partition**, and the planner pays for them even when the query can.

## The same events, one partition a day

This file makes `events_by_day`: the same columns, the same rows, cut into 365 partitions, one for
each day of 2025. Nobody writes 365 `CREATE TABLE` statements by hand, so a `DO` block writes them
in a loop. Save it as `~/events_by_day.sql`:

```sql
-- events_by_day.sql: the same events, one partition a day for all of 2025.
-- Run it on market after events_by_month.sql:  psql market -f events_by_day.sql
DROP TABLE IF EXISTS events_by_day;

CREATE TABLE events_by_day (LIKE events_by_month) PARTITION BY RANGE (at);

-- 365 partitions, named events_d20250101 to events_d20251231.
DO $$
BEGIN
    FOR d IN 0..364 LOOP
        EXECUTE format(
            'CREATE TABLE %I PARTITION OF events_by_day FOR VALUES FROM (%L) TO (%L)',
            'events_d' || to_char(date '2025-01-01' + d, 'YYYYMMDD'),
            date '2025-01-01' + d, date '2025-01-01' + d + 1);
    END LOOP;
END $$;

INSERT INTO events_by_day SELECT * FROM events_by_month;
ALTER TABLE events_by_day ADD PRIMARY KEY (id, at);
CREATE INDEX ON events_by_day (customer_id);
VACUUM ANALYZE events_by_day;
```

It builds the 365 tables, copies the five million rows from `events_by_month`, and adds the primary
key and the index on `customer_id` afterwards, which is quicker than keeping them up to date row by
row during the copy:

```
ana@vm:~$ psql market -v ON_ERROR_STOP=1 -f events_by_day.sql
psql:events_by_day.sql:3: NOTICE:  table "events_by_day" does not exist, skipping
DROP TABLE
Time: 0.518 ms
CREATE TABLE
Time: 16.039 ms
DO
Time: 680.298 ms
INSERT 0 5000000
Time: 6046.334 ms (00:06.046)
ALTER TABLE
Time: 3257.952 ms (00:03.258)
CREATE INDEX
Time: 3254.463 ms (00:03.254)
VACUUM
Time: 9987.892 ms (00:09.988)
```

Under a second for the 365 empty tables and about twenty-three seconds in all. Ninety of the
partitions hold the rows, from the 3rd of October to the 31st of December; the other 275 are empty, the way a table looks
when partitions are created a year ahead.

## What a query that cannot prune costs now

Customer 42's events, which section 04 showed cannot prune, on each table. `EXPLAIN (ANALYZE,
SUMMARY)` prints the planning and execution times; with 365 partitions the plan itself is hundreds
of lines, so `grep` keeps the `Append` line and the two times. Twice each, to see that the
numbers repeat:

```
ana@vm:~$ psql market -c "EXPLAIN (ANALYZE, SUMMARY) SELECT count(*) FROM events_by_month WHERE customer_id = 42" | grep -E 'Append|Planning|Execution'
   ->  Append  (cost=0.43..13.76 rows=22 width=0) (actual time=0.045..0.125 rows=20 loops=1)
 Planning Time: 1.147 ms
 Execution Time: 0.232 ms
ana@vm:~$ psql market -c "EXPLAIN (ANALYZE, SUMMARY) SELECT count(*) FROM events_by_month WHERE customer_id = 42" | grep -E 'Append|Planning|Execution'
   ->  Append  (cost=0.43..13.76 rows=22 width=0) (actual time=0.026..0.067 rows=20 loops=1)
 Planning Time: 0.851 ms
 Execution Time: 0.159 ms
```

```
ana@vm:~$ psql market -c "EXPLAIN (ANALYZE, SUMMARY) SELECT count(*) FROM events_by_day WHERE customer_id = 42" | grep -E 'Append|Planning|Execution'
   ->  Append  (cost=0.00..389.50 rows=365 width=0) (actual time=1.114..2.874 rows=20 loops=1)
 Planning Time: 30.321 ms
 Execution Time: 5.702 ms
ana@vm:~$ psql market -c "EXPLAIN (ANALYZE, SUMMARY) SELECT count(*) FROM events_by_day WHERE customer_id = 42" | grep -E 'Append|Planning|Execution'
   ->  Append  (cost=0.00..389.50 rows=365 width=0) (actual time=1.133..2.411 rows=20 loops=1)
 Planning Time: 32.494 ms
 Execution Time: 5.009 ms
```

The monthly plan has four children under its `Append` and the daily one **365**. The planner spent
**about 1 millisecond** on the monthly table and **30.3 and 32.5** on the daily one, around thirty times as long, and execution went
from about 0.2 milliseconds to 5, for the same 20 rows. Most of the daily partitions are empty, and
the query still had to plan an index probe or a scan for each of them and run it.

Thirty milliseconds of planning on a query that executes in five is the shape of the problem: the
time goes into the plan, not the data, so faster disks and more memory do nothing for it. A query
run a thousand times a second spends thirty processor-seconds a second planning, which is more
processors than this machine has.

## And a query that prunes

The day query from section 02, on the daily table, reads exactly one partition, the 10th of
November:

```
ana@vm:~$ psql market -c "EXPLAIN (ANALYZE, SUMMARY) SELECT count(*) FROM events_by_day WHERE at >= '2025-11-10' AND at < '2025-11-11'" | grep -E 'Scan|Planning|Execution'
   ->  Seq Scan on events_d20251110 events_by_day  (cost=0.00..1564.41 rows=55683 width=0) (actual time=0.022..9.242 rows=55694 loops=1)
 Planning Time: 3.173 ms
 Execution Time: 11.804 ms
```

**One scan**, and execution at 11.8 milliseconds, faster than the monthly table's 48.3, because it
reads a day instead of a month. But planning took **3.2 milliseconds** against 0.6 for the monthly
version in section 02. Pruning removes partitions from the plan. It does not make the planner's
work free: finding which partitions survive still means looking at their bounds, and some
of what the planner does for a partitioned table grows with the count however many survive.

## How many is too many

There is no number that is right everywhere, and the measurement above is how to find yours. The
reasoning is three questions:

- **What is the slice that ages?** Lesson 17's job was dropping old data. If data is kept for a
  year and dropped by the month, a partition a month is twelve, and a partition a day buys nothing
  that dropping needs.
- **What do the queries that cannot prune cost?** Every one of them pays per partition, in planning
  and in execution. A daily table with one important query by `customer_id` pays thirty times over
  for it.
- **What do the queries that can prune gain?** Reading a day instead of a month is real, and it is
  also what an index on `at` gives inside a monthly partition.

Hundreds are workable and thousands are rarely worth it; recent PostgreSQL versions have made
planning with many partitions much cheaper than it was, and this server, version 16, still shows
the cost plainly. Leave `events_by_day` in place: the next section uses it once more.
