---
title: Catch-up, and the runs nobody asked for
version: 1
---

`catchup=True` tells the scheduler that every schedule point between the start date and now
deserves a run. For a DAG written last week that is a handful of runs. For a DAG with an old start
date it is a flood, and the lab makes a good one, because the shop's March is seven months behind
the machine's October:

```
"""catchup=True, a start date in the past, and no end date."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag


@dag(schedule="0 2 * * *",
     start_date=pendulum.datetime(2026, 3, 2, tz="America/Sao_Paulo"), catchup=True)
def catchup_demo():
    BashOperator(task_id="load", bash_command="echo loading the day before {{ ds }}")


catchup_demo()
```

```
ana@vm:~/etl$ airflow dags reserialize >/dev/null 2>&1; airflow dags unpause catchup_demo
dag_id       | is_paused
=============+==========
catchup_demo | True     
                        
ana@vm:~/etl$ airflow dags list-runs catchup_demo -o plain | tail -n +2 | wc -l
220
ana@vm:~/etl$ airflow dags list-runs catchup_demo -o plain | tail -n +2 | tr -s " " | cut -d" " -f3 | sort | uniq -c
    220 success
ana@vm:~/etl$ airflow dags pause catchup_demo; airflow dags delete -y catchup_demo; rm dags/catchup_demo.py
dag_id       | is_paused
=============+==========
catchup_demo | False    
                        
2026-10-07T08:31:56.949638Z [info     ] Deleting Dag: catchup_demo     [airflow.api.common.delete_dag] loc=delete_dag.py:55
Removed 442 record(s)
```

**Two hundred and twenty runs**, one for every 02:00 from 2 March to the morning of the
recording, created and run in the twenty seconds after the DAG was unpaused. The second command
counts them by state, and every one of them is `success`: each was one `echo`, and the scheduler ran
them many at a time, sixteen runs of a DAG by default. Ana pauses the DAG and deletes it, with its
runs.

For this DAG the cost was two hundred and twenty `echo`s. For a real load it is two hundred and
twenty loads of days with no data, competing for the same tables at the same time, and every one
that survives the competition a success.

## When catch-up is right

- **The DAG's history matters, and each run is independent.** A daily export of the day's events
  to an archive should have one file per day, and a missing day should be filled.
- **The start date was set on purpose**, close to now, and catch-up only ever fills the gap of an
  outage.

And when it is not, which is the default this course takes: **`catchup=False`, and the past filled
deliberately, with a backfill**, for a range somebody chose. That is the next section. Airflow 3
agrees: `catchup` defaults to `False` unless a configuration says otherwise.
