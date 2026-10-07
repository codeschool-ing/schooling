---
title: A minute is a day: the lab's fast clock
version: 1
---

A nightly pipeline is only really tested by nights, and nights are slow. Everything so far has used
a shortcut: the lab plays a day when asked, and Airflow is told which logical date a run is for. The
scheduler itself — the process that decides, on its own, that a run is due — has done almost
nothing, because its next decision is at 02:00 tomorrow, and the shop's tomorrow is in March.

**This is a problem no other course in the catalogue has**: every other blocked course needs a
machine, and this one needs a clock. The lab's answer is to make the shop's calendar and Airflow's
calendar two different things, and to join them in a DAG that says how:

```
"""The lab's fast clock: every minute, one more day of March, loaded.

Not a pipeline anybody would run. It exists because a nightly schedule needs a
night to pass, and here a minute has to do."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag

ETL = "/home/ana/etl"
PSQL = "psql -q -v ON_ERROR_STOP=1 -d wh"


@dag(schedule="* * * * *", start_date=pendulum.datetime(2026, 3, 1, tz="America/Sao_Paulo"),
     catchup=False, max_active_runs=1)
def shop_minute():
    play = BashOperator(task_id="play_a_day",
                        bash_command="bash ~/lab/lab.sh until $(date -d \"$(cat /var/lib/etl-run/clock) + 1 day\" +%F) && cat /var/lib/etl-run/clock")
    load = BashOperator(task_id="nightly",
                        bash_command="sh nightly.sh {{ ti.xcom_pull(task_ids='play_a_day') }} ",
                        cwd=ETL)
    play >> load


shop_minute()
```

Every minute, Airflow's own clock schedules a run. The run asks the lab what day the shop has lived
up to, plays the next one, and loads it with lesson 7's `nightly.sh`. **A minute of the machine's
time is a day of the shop's**, and the scheduler is the one keeping time.

Ana unpauses it and waits a little over three minutes:

```
ana@vm:~/etl$ cat /var/lib/etl-run/clock; airflow dags reserialize >/dev/null 2>&1; airflow dags unpause shop_minute
2026-03-09
dag_id      | is_paused
============+==========
shop_minute | True     
                       
ana@vm:~/etl$ airflow dags pause shop_minute; cat /var/lib/etl-run/clock
dag_id      | is_paused
============+==========
shop_minute | False    
                       
2026-03-13
ana@vm:~/etl$ airflow dags list-runs shop_minute -o plain | cut -c1-118
dag_id       run_id                                state    run_after                  logical_date               star
shop_minute  scheduled__2026-10-07T05:25:00+00:00  success  2026-10-07T05:25:00+00:00  2026-10-07T05:25:00+00:00  2026
shop_minute  scheduled__2026-10-07T05:24:00+00:00  success  2026-10-07T05:24:00+00:00  2026-10-07T05:24:00+00:00  2026
shop_minute  scheduled__2026-10-07T05:23:00+00:00  success  2026-10-07T05:23:00+00:00  2026-10-07T05:23:00+00:00  2026
shop_minute  scheduled__2026-10-07T05:22:00+00:00  success  2026-10-07T05:22:00+00:00  2026-10-07T05:22:00+00:00  2026
ana@vm:~/etl$ psql -d wh -c "SELECT order_date, count(*) FROM marts.fact_sales WHERE order_date > '2026-03-08' GROUP BY 1 ORDER BY 1"
 order_date | count 
------------+-------
 2026-03-09 |   431
 2026-03-10 |   368
 2026-03-11 |   416
 2026-03-12 |   419
 2026-03-13 |   448
(5 rows)
```

The shop's clock moved from 9 March to 13 March while Ana waited, one day per run, every run
scheduled by the scheduler at the top of a minute, and the fact table gained a day each time. Nothing
here was started by hand.

## What the fast clock is for, and what it is not

**It is for watching the scheduler do its job**: runs appearing on time, `max_active_runs=1` holding
the next run until the last one ends, a sensor waiting, an alert firing at the wrong moment, which
lesson 10 needs. None of that can be seen with `dags test`.

**It is not a model of production.** Its logical dates are October; the day it loads comes from the
lab's clock, not from the run. A real DAG takes its day from its run, as `shop_nightly` does, and
that is the property every backfill depends on. The fast clock breaks it on purpose, in a DAG whose
docstring says so, and the lesson pauses it before moving on.
