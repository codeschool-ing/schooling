---
title: By range: one partition a month
version: 1
---

Range partitioning gives each partition **an interval of the key**: from this instant up to, but not
including, that one. It is the kind that matches the job of section 02, because time comes in
intervals and old rows leave by interval. The table below is `events` again, with the same columns
and the same five million rows, cut into one partition a month. Save it as `~/events_by_month.sql`:

```sql
-- events_by_month.sql: the events table again, cut into one partition a month.
-- Run it on market:  psql market -f events_by_month.sql
-- It starts by dropping the table, so running it twice builds it afresh.
DROP TABLE IF EXISTS events_by_month;

CREATE TABLE events_by_month (
    id          bigint      NOT NULL,
    at          timestamptz NOT NULL,
    customer_id integer,
    kind        text        NOT NULL,
    payload     jsonb       NOT NULL,
    PRIMARY KEY (id, at)
) PARTITION BY RANGE (at);

-- Each month runs from its first instant up to, not including, the next one.
CREATE TABLE events_2025_10 PARTITION OF events_by_month
    FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
CREATE TABLE events_2025_11 PARTITION OF events_by_month
    FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
CREATE TABLE events_2025_12 PARTITION OF events_by_month
    FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');
CREATE TABLE events_2026_01 PARTITION OF events_by_month
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

INSERT INTO events_by_month SELECT * FROM events;

CREATE INDEX ON events_by_month (customer_id);
VACUUM ANALYZE events_by_month;
```

Read it in three parts. **The parent** is a `CREATE TABLE` like any other, plus `PARTITION BY RANGE
(at)`, which names the key. It holds no rows and never will. **The partitions** are tables of their
own, each attached with `PARTITION OF` and the interval it accepts. The upper bound is exclusive, so
`2025-11-01 00:00` belongs to November and not October, and the months meet without a gap or an
overlap — the server refuses two partitions whose intervals overlap. January 2026 is empty and
there on purpose: the month after the data ends has to exist **before** its first row arrives.
**The rows** come from `events` in one `INSERT`, and each one is routed to its partition by its `at`.

The primary key is `(id, at)` rather than `id` alone, which section 06 explains, and the index on
`customer_id` is declared once, on the parent. Run it:

```
ana@vm:~$ psql market -v ON_ERROR_STOP=1 -f events_by_month.sql
psql:events_by_month.sql:4: NOTICE:  table "events_by_month" does not exist, skipping
DROP TABLE
Time: 1.103 ms
CREATE TABLE
Time: 8.159 ms
CREATE TABLE
Time: 6.025 ms
CREATE TABLE
Time: 4.305 ms
CREATE TABLE
Time: 3.368 ms
CREATE TABLE
Time: 3.133 ms
INSERT 0 5000000
Time: 22026.298 ms (00:22.026)
CREATE INDEX
Time: 4306.158 ms (00:04.306)
VACUUM
Time: 2186.480 ms (00:02.186)
```

Twenty-two seconds to copy five million rows and route each to its month. `\d+` shows the result as
one table with four partitions, and a count by `tableoid`, the hidden column that says which table
a row physically lives in, shows where the rows went:

```
market=# \d+ events_by_month
                                          Partitioned table "public.events_by_month"
   Column    |           Type           | Collation | Nullable | Default | Storage  | Compression | Stats target | Description 
-------------+--------------------------+-----------+----------+---------+----------+-------------+--------------+-------------
 id          | bigint                   |           | not null |         | plain    |             |              | 
 at          | timestamp with time zone |           | not null |         | plain    |             |              | 
 customer_id | integer                  |           |          |         | plain    |             |              | 
 kind        | text                     |           | not null |         | extended |             |              | 
 payload     | jsonb                    |           | not null |         | extended |             |              | 
Partition key: RANGE (at)
Indexes:
    "events_by_month_pkey" PRIMARY KEY, btree (id, at)
    "events_by_month_customer_id_idx" btree (customer_id)
Partitions: events_2025_10 FOR VALUES FROM ('2025-10-01 00:00:00-03') TO ('2025-11-01 00:00:00-03'),
            events_2025_11 FOR VALUES FROM ('2025-11-01 00:00:00-03') TO ('2025-12-01 00:00:00-03'),
            events_2025_12 FOR VALUES FROM ('2025-12-01 00:00:00-03') TO ('2026-01-01 00:00:00-03'),
            events_2026_01 FOR VALUES FROM ('2026-01-01 00:00:00-03') TO ('2026-02-01 00:00:00-03')

market=# SELECT tableoid::regclass AS partition, count(*), pg_size_pretty(pg_relation_size(tableoid)) AS size FROM events_by_month GROUP BY 1 ORDER BY 1;
   partition    |  count  |  size  
----------------+---------+--------
 events_2025_10 | 1611210 | 165 MB
 events_2025_11 | 1667081 | 170 MB
 events_2025_12 | 1721709 | 176 MB
(3 rows)

Time: 353.448 ms
```

The bounds print with `-03` because they were written as dates and read in the session's time zone,
São Paulo here. A month boundary is an instant, so a server and an application that disagree about
the time zone disagree about which month a click at ten at night belongs to. Write bounds with an
explicit offset, or keep the server and the application on one zone, and know which.

**Three partitions of about 170 MB each, and an empty fourth.** The empty one does not show in the
count, which only lists tables with rows.

## A row with nowhere to go

A row whose key falls outside every interval is refused, not stored somewhere approximate:

```
market=# INSERT INTO events_by_month VALUES (0, '2026-03-01', NULL, 'view', '{}');
ERROR:  no partition of relation "events_by_month" found for row
DETAIL:  Partition key of the failing row contains (at) = (2026-03-01 00:00:00-03).
Time: 1.549 ms
```

March 2026 has no partition, so the insert fails. That is the failure range partitioning brings
with it, and it arrives on a date: **somebody has to create next month before next month**. A job
that creates partitions some months ahead, monitored like a backup, is the usual answer; section 05
shows the other one, a default partition, and what it costs.

## Not faster by itself

Here is the cost from section 02, measured. The same lookup by `id`, on `events` and on
`events_by_month`:

```
market=# EXPLAIN (ANALYZE, COSTS OFF) SELECT * FROM events WHERE id = 2500000;
                                    QUERY PLAN                                    
----------------------------------------------------------------------------------
 Index Scan using events_pkey on events (actual time=0.127..0.128 rows=1 loops=1)
   Index Cond: (id = 2500000)
 Planning Time: 0.824 ms
 Execution Time: 0.218 ms
(4 rows)

Time: 3.445 ms

market=# EXPLAIN (ANALYZE, COSTS OFF) SELECT * FROM events_by_month WHERE id = 2500000;
                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 Append (actual time=0.144..0.221 rows=1 loops=1)
   ->  Index Scan using events_2025_10_pkey on events_2025_10 events_by_month_1 (actual time=0.080..0.080 rows=0 loops=1)
         Index Cond: (id = 2500000)
   ->  Index Scan using events_2025_11_pkey on events_2025_11 events_by_month_2 (actual time=0.062..0.063 rows=1 loops=1)
         Index Cond: (id = 2500000)
   ->  Index Scan using events_2025_12_pkey on events_2025_12 events_by_month_3 (actual time=0.070..0.070 rows=0 loops=1)
         Index Cond: (id = 2500000)
   ->  Seq Scan on events_2026_01 events_by_month_4 (actual time=0.005..0.005 rows=0 loops=1)
         Filter: (id = 2500000)
 Planning Time: 1.560 ms
 Execution Time: 0.279 ms
(11 rows)

Time: 2.626 ms
```

On `events` it is **one index scan**. On `events_by_month` it is an `Append` of **four scans**, one
per partition, because nothing in `id = 2500000` says which month the row is in: three index scans,
and a sequential scan of the empty January, which costs nothing. Execution is 0.218 against 0.279
milliseconds, and planning 0.824 against 1.560, nearly twice as long, because the planner had four
tables to plan for instead of one.

Small numbers, both. The point is their direction: on a query that does not name the key, the
partitioned table did **more** work, never less. A query that names it, with `at` in a range, is lesson
18's subject, and it is where partitioning earns back costs like this one. This table stays in
`market` for lesson 18; the end of this lesson says how to leave it exactly as lesson 18 expects.
