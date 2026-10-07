---
title: Backfill: filling the past on purpose
version: 1
---

A **backfill** asks Airflow for runs over a range of logical dates that somebody chose — the week a
bug was in production, the month before a DAG existed, or, in the lab, the days the shop has lived
that no run has loaded yet. Ana plays the first week of March and asks for the runs that load it:

```
ana@vm:~/etl$ sudo bash ~/lab/lab.sh until 2026-03-07
ana@vm:~/etl$ airflow backfill create --dag-id shop_nightly --from-date 2026-03-03 --to-date 2026-03-08 2>&1 | grep -c "Created backfill Dag run"
5
ana@vm:~/etl$ airflow dags unpause shop_nightly
dag_id       | is_paused
=============+==========
shop_nightly | True     
                        
ana@vm:~/etl$ airflow dags list-runs shop_nightly -o plain | cut -c1-118
dag_id        run_id                                state    run_after                  logical_date               sta
shop_nightly  scheduled__2026-10-07T05:00:00+00:00  success  2026-10-07T05:00:00+00:00  2026-10-07T05:00:00+00:00  202
shop_nightly  backfill__2026-03-07T05:00:00+00:00   success  2026-03-07T05:00:00+00:00  2026-03-07T05:00:00+00:00  202
shop_nightly  backfill__2026-03-06T05:00:00+00:00   failed   2026-03-06T05:00:00+00:00  2026-03-06T05:00:00+00:00  202
shop_nightly  backfill__2026-03-05T05:00:00+00:00   success  2026-03-05T05:00:00+00:00  2026-03-05T05:00:00+00:00  202
shop_nightly  backfill__2026-03-04T05:00:00+00:00   failed   2026-03-04T05:00:00+00:00  2026-03-04T05:00:00+00:00  202
shop_nightly  backfill__2026-03-03T05:00:00+00:00   failed   2026-03-03T05:00:00+00:00  2026-03-03T05:00:00+00:00  202
ana@vm:~/etl$ psql -d wh -c "SELECT order_date, count(*) FROM marts.fact_sales GROUP BY 1 ORDER BY 1"
 order_date | count 
------------+-------
 2026-03-02 |   412
 2026-03-04 |   441
 2026-03-06 |   439
(3 rows)
```

Two surprises in one transcript.

**Five runs, not six.** The range was 3 March to 8 March, and the run that loads 7 March is the one
at 02:00 on 8 March. But `--to-date 2026-03-08` means *midnight* on 8 March, and 02:00 is after
midnight: that run was outside the range. **Dates on Airflow's command line are moments**, and a
range that should include a day's run has to reach past the time of day it runs.

**And runs failed.** The fact table holds only the days whose runs happened to succeed.
The reason is in the task logs:

```
ana@vm:~/etl$ grep -ho "ERROR: [^\\]*" ~/airflow/logs/dag_id=shop_nightly/run_id=backfill__*/task_id=*/attempt=1.log | sort | uniq -c
      2 ERROR:  duplicate key value violates unique constraint 
      1 ERROR:  relation
```

The backfill started its runs at the same time, and every run of this DAG rebuilds the same `raw`
and `staging` tables. Two runs creating `staging.books` at once collide in PostgreSQL's catalogue
— *duplicate key value violates unique constraint*. One run's `DROP TABLE` pulls a table out
from under another's query — *relation does not exist*. Which runs lose is a race, and it is a
different race every time.

## One at a time

A DAG whose runs share state must not run in parallel, and it has to say so. Ana adds
`max_active_runs=1` to the DAG, and gives the backfill the same limit, because a backfill carries a
limit of its own and in the recording it did not take the DAG's:

```
ana@vm:~/etl$ sed -i 's|    tags=\["shop"\],|    tags=["shop"],\n    max_active_runs=1,          # every run rebuilds raw and staging: one at a time|' dags/shop_nightly.py
ana@vm:~/etl$ grep -n -B1 -A1 max_active_runs dags/shop_nightly.py
14-    tags=["shop"],
15:    max_active_runs=1,          # every run rebuilds raw and staging: one at a time
16-)
ana@vm:~/etl$ airflow dags reserialize >/dev/null 2>&1; airflow backfill create --dag-id shop_nightly --from-date 2026-03-03 --to-date 2026-03-08T12:00:00-03:00 --reprocess-behavior failed --max-active-runs 1 2>&1 | grep -c "Created backfill Dag run"
6
ana@vm:~/etl$ airflow dags list-runs shop_nightly -o plain | cut -c1-118
dag_id        run_id                                state    run_after                  logical_date               sta
shop_nightly  scheduled__2026-10-07T05:00:00+00:00  success  2026-10-07T05:00:00+00:00  2026-10-07T05:00:00+00:00  202
shop_nightly  backfill__2026-03-08T05:00:00+00:00   success  2026-03-08T05:00:00+00:00  2026-03-08T05:00:00+00:00  202
shop_nightly  backfill__2026-03-07T05:00:00+00:00   success  2026-03-07T05:00:00+00:00  2026-03-07T05:00:00+00:00  202
shop_nightly  backfill__2026-03-06T05:00:00+00:00   success  2026-03-06T05:00:00+00:00  2026-03-06T05:00:00+00:00  202
shop_nightly  backfill__2026-03-05T05:00:00+00:00   success  2026-03-05T05:00:00+00:00  2026-03-05T05:00:00+00:00  202
shop_nightly  backfill__2026-03-04T05:00:00+00:00   success  2026-03-04T05:00:00+00:00  2026-03-04T05:00:00+00:00  202
shop_nightly  backfill__2026-03-03T05:00:00+00:00   success  2026-03-03T05:00:00+00:00  2026-03-03T05:00:00+00:00  202
ana@vm:~/etl$ psql -d wh -c "SELECT order_date, count(*) FROM marts.fact_sales GROUP BY 1 ORDER BY 1"
 order_date | count 
------------+-------
 2026-03-02 |   412
 2026-03-03 |   476
 2026-03-04 |   441
 2026-03-05 |   464
 2026-03-06 |   439
 2026-03-07 |   539
(6 rows)
```

The second backfill reaches to noon on 8 March, so it includes the 02:00 run, and
`--reprocess-behavior failed` asks for the failed runs to be run again. Six runs, one after another,
all successful, and the fact table has every day from 2 to 7 March.

## What makes a backfill safe

- **The DAG loads the day its run is for**, not the day it happens to run — lesson 8's
  `day_to_load`. A backfill of March run in October loads March.
- **Each run replaces its period** rather than appending to it — lesson 7's delete-then-insert. A
  backfill that reruns a day that was already loaded must not double it, and lesson 15 makes that a
  property you test rather than hope for.
- **Runs that share state do not overlap** — `max_active_runs=1`, on the DAG and on the backfill.

Without all three, a backfill is the fastest way there is to damage a warehouse: many runs, at once,
over history, while nobody is watching.
