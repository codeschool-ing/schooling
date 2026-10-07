---
title: Handing the DAG to the scheduler
version: 1
---

In lesson 8 every run was started by hand, with `dags test`. **This lesson hands the DAG to the
scheduler**, which creates runs on its own, and the first thing it does is a surprise.

Before unpausing, Ana asks Airflow when the next run is due:

```
ana@vm:~/etl$ airflow dags next-execution shop_nightly 2>/dev/null
2026-10-07T05:00:00+00:00
ana@vm:~/etl$ airflow dags unpause shop_nightly
dag_id       | is_paused
=============+==========
shop_nightly | True     
                        
ana@vm:~/etl$ airflow dags list-runs shop_nightly -o plain
dag_id        run_id                                state    run_after                  logical_date               start_date                        end_date
shop_nightly  scheduled__2026-10-07T05:00:00+00:00  success  2026-10-07T05:00:00+00:00  2026-10-07T05:00:00+00:00  2026-10-07T05:17:06.862828+00:00  2026-10-07T05:17:15.159934+00:00
ana@vm:~/etl$ psql -d wh -c "SELECT order_date, count(*) FROM marts.fact_sales GROUP BY 1 ORDER BY 1"
 order_date | count 
------------+-------
(0 rows)

ana@vm:~/etl$ airflow dags pause shop_nightly
dag_id       | is_paused
=============+==========
shop_nightly | False
```

Four things in that transcript are worth stopping on.

**The next run was in the past.** `next-execution` answered with the most recent 02:00 in São Paulo
before the moment of the recording, written in UTC. With `catchup=False`, the scheduler does not
create a run for every 02:00 since the start date; it creates the latest one it missed, at once, and
waits for the next.

**The tables printed by `unpause` and `pause` show the DAG as it was *before* the command**:
`True` after unpausing, `False` after pausing. It reads as the opposite of what happened, and the
first time you see it, it is worth knowing it is Airflow's habit and not your mistake.

**The run succeeded.** It ran all six tasks, every command exited with 0, and the state is
`success`.

**And it loaded nothing.** The run for that October morning loads the October day before it, and
the shop in the lab lives in March: there were no orders on that day, so the fact table holds no
rows. Nothing failed, because
nothing was wrong with the code. **A run that loads an empty day is a success to Airflow**, and on a
production system the same shape appears when a source silently stops sending data: every night
green, every night empty. Lesson 16 adds the check that turns "zero rows" into a failure.

Ana pauses the DAG again. The rest of this lesson is about what the scheduler does with dates, and
how to make it load the days the lab actually has.
