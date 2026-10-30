---
title: Reading a plan, on DuckDB
version: 1
---

**A query plan is the engine's answer to "how will you do this", written as a tree of steps.** Each
step takes rows from the steps below it and hands rows to the step above it, so a plan is read from the
bottom, where the table is read, to the top, where the answer leaves. DuckDB prints one with `EXPLAIN`,
which plans and does not run, and with `EXPLAIN ANALYZE`, which runs the query and writes beside each
step how many rows it produced and how long it took. Every plan in this section is DuckDB's, measured
on your laptop; BigQuery's equivalent is the next section, and it is drawn differently for a reason
that section gives.

## September, per district

`ask.py` from lesson 13 prints the plan as text when a question starts with `EXPLAIN`:

```
ana@laptop:~/gcp$ python3 ask.py "EXPLAIN ANALYZE SELECT district, sum(total_cents) AS sales FROM orders WHERE dt BETWEEN DATE '2026-09-01' AND DATE '2026-09-29' GROUP BY district ORDER BY sales DESC"
┌─────────────────────────────────────┐
│┌───────────────────────────────────┐│
││    Query Profiling Information    ││
│└───────────────────────────────────┘│
└─────────────────────────────────────┘
EXPLAIN ANALYZE SELECT district, sum(total_cents) AS sales FROM orders WHERE dt BETWEEN DATE '2026-09-01' AND DATE '2026-09-29' GROUP BY district ORDER BY sales DESC
┌────────────────────────────────────────────────┐
│┌──────────────────────────────────────────────┐│
││              Total Time: 0.0126s             ││
│└──────────────────────────────────────────────┘│
└────────────────────────────────────────────────┘
┌───────────────────────────┐
│           QUERY           │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│      EXPLAIN_ANALYZE      │
│    ────────────────────   │
│                           │
│           0 rows          │
│           0.00s           │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│          ORDER_BY         │
│    ────────────────────   │
│   sum(memory.main.orders  │
│     .total_cents) DESC    │
│                           │
│                           │
│                           │
│           8 rows          │
│           0.00s           │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│       HASH_GROUP_BY       │
│    ────────────────────   │
│         Groups: #0        │
│    Aggregates: sum(#1)    │
│                           │
│                           │
│                           │
│           8 rows          │
│           0.01s           │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│         PROJECTION        │
│    ────────────────────   │
│          district         │
│        total_cents        │
│                           │
│                           │
│                           │
│        594,882 rows       │
│           0.00s           │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│         TABLE_SCAN        │
│    ────────────────────   │
│         Function:         │
│        READ_PARQUET       │
│                           │
│        Projections:       │
│          district         │
│        total_cents        │
│                           │
│       File Filters:       │
│ (dt BETWEEN '2026-09-01': │
│  :DATE AND '2026-09-29':  │
│           :DATE)          │
│                           │
│   Scanning Files: 29/60   │
│    Total Files Read: 29   │
│                           │
│        Filename(s):       │
│  warehouse/orders/dt=2026 │
│  -09-01/part-000.parquet, │
│  warehouse/orders/dt=2026 │
│  -09-02/part-000.parquet, │
│  warehouse/orders/dt=2026 │
│  -09-03/part-000.parquet, │
│  warehouse/orders/dt=2026 │
│  -09-04/part-000.parquet, │
│  warehouse/orders/dt=2026 │
│ -09-05/part-000.parquet, .│
│             ..            │
│                           │
│                           │
│                           │
│        594,882 rows       │
│           0.02s           │
└───────────────────────────┘
```

**Read it from the bottom.** `TABLE_SCAN` is the read: the `READ_PARQUET` function, the two columns it
**projects**, `district` and `total_cents`, and the **file filter** on `dt` that kept 29 of the 60
files. It read the files it names and produced 594,882 rows, which is every order of September. Note
what it does not list: `dt` is not among the projections, because DuckDB took the date from the folder
names and needed no column for it. BigQuery would bill `dt` as a column, which the last section of this
lesson comes back to.

**`PROJECTION` passes the two columns up**, and **`HASH_GROUP_BY` is the aggregation**: it groups by
`#0`, the first column it was given, `district`, and sums `#1`, `total_cents`. 594,882 rows go in and 8
come out, one per district, which is the moment a query stops being large. **`ORDER_BY` sorts those 8
rows** by the sum, and `EXPLAIN_ANALYZE` at the top is the wrapper that measured the rest; it returns no
rows of its own.

**The times say where the work was.** The scan took most of it, and the grouping and the sorting of 8
rows took almost none. That is the normal shape of an analytical query, and it is the same in BigQuery:
reading is the expensive step, which is why both pricing models of lesson 14 come back to how much a
query reads, one by billing the bytes and the other by billing the slots that read them. The total at
the top, a few hundredths of a second, is the cost of 29 files on one laptop and says nothing about
BigQuery's speed.

## What the plan proves, and what it cannot

**The plan is evidence of the two things this course bills by.** The projections list is the columns
read, and the file count is the partitions read. If a query that was supposed to read one day says
`Scanning Files: 60/60`, the plan has caught the expensive mistake before the bill did, and that is the
habit worth keeping on any engine: read the plan of a query that will run often before it does.

**What it cannot prove is anything about BigQuery's plan.** DuckDB is one process on one machine, with a
plan of operators handing rows to each other in memory. BigQuery splits the same query across many
slots and many stages, with the rows moving between them across a network, and its plan has a shape
DuckDB's does not have. The steps are recognisably the same, a read, a projection, an aggregation, a
sort; how they are arranged and what they cost is the next section.
