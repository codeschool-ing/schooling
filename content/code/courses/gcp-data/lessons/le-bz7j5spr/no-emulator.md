---
title: No emulator, and what stands in for one
version: 1
---

**BigQuery has no emulator.** Google publishes emulators for Pub/Sub, Firestore, Bigtable and
Spanner, and this course runs all four; it publishes none for BigQuery, and there is no setting of
the command line that sends a `bq` command anywhere but Google. Community projects that imitate its
API do exist, and none of them implements the three things this lesson and the next five are about:
**how BigQuery bills a query, how it schedules slots, and how it stores a table**. A lab that
answered `bq query` with the right rows and the wrong bill would teach the wrong half, so this
course does not use one.

The command line says the same thing in its own words. Your terminal sends `gcloud` to the emulators
and no credentials to anybody, and `bq` is the one tool with nowhere to go:

```
ana@laptop:~/gcp$ bq query --dry_run --use_legacy_sql=false 'SELECT 1' 2>&1 | head -2
ERROR: (bq) You do not currently have an active account selected.
Please run:
```

**`bq` refused before it sent anything**, because it wants an account and lesson 1 made sure there
is none. Even the dry run, which costs nothing on Google Cloud and is lesson 16's main tool, needs
the real service to answer it. Every `bq` command in these six lessons is printed in a plain `sh`
block as the command you would type, and none of them was run.

## What stands in: DuckDB, on the same files

**DuckDB is a database engine that runs inside a Python program**, with no server, and it reads
Parquet files directly. Lesson 1 installed it in the virtual environment, with PyArrow to write the
files:

```
ana@laptop:~/gcp$ python3 -c "import duckdb, pyarrow; print('duckdb', duckdb.__version__, '/ pyarrow', pyarrow.__version__)"
duckdb 1.5.6 / pyarrow 25.0.1
```

**What DuckDB gives these lessons is the SQL, run for real, on the same files BigQuery would load.**
In the next section you write Quitanda's orders as Parquet, one folder per day, and upload the same
files to the Cloud Storage emulator. From then on every query in the course runs twice in your head:
once in DuckDB, where it returns real rows from real data in a fraction of a second, and once in
BigQuery, where it would return the same rows and send a bill.

**A good deal of what BigQuery does with a query, DuckDB does too**, and that is why it is a fair
stand-in rather than a toy. It is columnar, so it reads only the columns a query names. It reads the
date out of a folder called `dt=2026-08-01` and skips the folders a filter on `dt` rules out, which
is exactly what partition pruning is in BigQuery. It keeps the minimum and maximum of each column for
each group of rows in a Parquet file and skips the groups a filter cannot match, which is the idea
behind clustering. And it prints its plan, with the time each step took, which lesson 16 sets beside
BigQuery's.

## What it cannot stand in for

| | DuckDB, here | BigQuery |
|---|---|---|
| the SQL | runs, on your laptop | runs, on Google's slots |
| which columns and folders a query reads | measured | the same idea, computed |
| the bill for a query | **nothing**: it is free | bytes by type, rounded, with a minimum |
| slots, stages and shuffle | one process, your cores | thousands of slots, Google's scheduler |
| the stored size of a table | Parquet files you can measure | Capacitor files you cannot see |
| time travel, fail-safe, caching, quotas | none of them | all of them |

**The bill is the first thing it cannot give, and the most important.** DuckDB costs nothing to run,
so every number of dollars in these lessons is computed, not measured. The computation is not a
guess: BigQuery documents exactly how many bytes each type of value counts for, and the pricing page
documents the price per TiB, the rounding and the minimum. Two sections on, this lesson starts that
arithmetic, and lesson 16 turns it into a program.

**Slots are the second.** DuckDB runs a query on the cores of your laptop, and BigQuery spreads it
over as many slots as it decides to give it. How long a query takes in DuckDB says nothing about how
many slot-hours it would use in BigQuery, so no lesson here quotes a slot count as if it had been
measured. Lesson 14 prices slots from the pricing page, and lesson 16 reads BigQuery's execution
graph from the documentation.

**The storage is the third.** Parquet and Capacitor are both columnar and both compressed, and they
are not the same format. When the last section of this lesson compares the size of the Parquet files
with the size BigQuery would bill, the Parquet size is a clue to how well these columns compress,
and never the number BigQuery would print.

**And the dialect differs at the edges.** BigQuery's SQL is called GoogleSQL, and DuckDB's follows
PostgreSQL. Most of a `SELECT` with `WHERE`, `GROUP BY` and `JOIN` is the same in both. Some
functions are not: GoogleSQL writes `DATE_TRUNC(dt, MONTH)` and DuckDB writes
`date_trunc('month', dt)`, with the arguments the other way round. Where a lesson shows GoogleSQL
that would not run in DuckDB, it says so, and shows it in a block nobody ran.

**So every number in these lessons carries its source.** A row count, a file size, a plan or a time
is DuckDB's and was measured. A number of bytes billed, a price or a slot is computed from Google's
documentation, and the arithmetic is shown so you can check it. Nothing is presented as BigQuery's
output, because nothing here is BigQuery.
