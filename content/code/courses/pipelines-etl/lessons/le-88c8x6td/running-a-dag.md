---
title: Running it, and reading what happened
version: 1
---

With the space in place, the test run succeeds:

```
ana@vm:~/etl$ airflow dags test shop_nightly 2026-03-03 2>&1 | sh trace.sh
Running command: ['/usr/bin/bash', '-c', 'python load_raw.py']
Command exited with return code 0
[DAG TEST] end task task_id=extract
[DAG TEST] end task task_id=day_to_load
Running command: ['/usr/bin/bash', '-c', 'sh run_sql.sh ']
Command exited with return code 0
[DAG TEST] end task task_id=transform
Running command: ['/usr/bin/bash', '-c', 'psql -q -v ON_ERROR_STOP=1 -d wh -f load/dim_customer.sql']
Command exited with return code 0
[DAG TEST] end task task_id=dim_customer
Running command: ['/usr/bin/bash', '-c', 'psql -q -v ON_ERROR_STOP=1 -d wh -f load/dim_book.sql']
Command exited with return code 0
[DAG TEST] end task task_id=dim_book
Running command: ['/usr/bin/bash', '-c', 'psql -q -v ON_ERROR_STOP=1 -d wh -v day=2026-03-02 -f load/fact_sales.sql']
Command exited with return code 0
[DAG TEST] end task task_id=fact_sales
DagRun Finished: dag_id=shop_nightly, logical_date=2026-03-03 03:00:00+00:00
state=success, run_type=manual
ana@vm:~/etl$ psql -d wh -c "SELECT order_date, count(*) FROM marts.fact_sales GROUP BY 1"
 order_date | count 
------------+-------
 2026-03-02 |   415
(1 row)
```

Every task ran the command it was given, and every command exited with code 0. The last line of the
filter is the run's verdict, `state=success`. The fact table holds 415 lines for 2 March, the day the
run for 3 March was supposed to load, and the same number `nightly.sh` loaded in lesson 7.

`fact_sales` ran `psql ... -v day=2026-03-02`. **The `{day}` in the DAG file was rendered to
`2026-03-02` just before the task ran**, from `day_to_load`'s answer — so the value in the command is
the value of this run, not a value fixed when the file was written.

## What `dags test` is, and is not

- **It is a real run.** It creates a DAG run in the metadata database, runs every task, and records
  their states; the run is in `list-runs` afterwards, as the last section showed.
- **It does not need the scheduler**, and it ignores whether the DAG is paused. It is how a DAG is
  tried before it is unpaused.
- **It runs the tasks in the terminal's process**, one after another. Two tasks with no arrow
  between them run in sequence here; under the scheduler, with `LocalExecutor`, they run at the same
  time. A DAG that works in `dags test` because two tasks happened to run in a convenient order may
  not work under the scheduler — which is the missing-dependency trap from the section on dependencies.

`airflow tasks test DAG TASK DATE` runs a single task the same way, without its upstream tasks,
which is the fastest way to try a change to one of them.
