---
title: Two kinds of schedule
version: 1
---

Lesson 8 said that Airflow 3 changed what a cron string means. Here are both meanings side by side,
in two DAGs that differ only in their `schedule`, each limited to the first three days of March:

```
"""A cron string: in Airflow 3, a run at each time, for that time."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag


@dag(schedule="0 0 * * *",
     start_date=pendulum.datetime(2026, 3, 1, tz="America/Sao_Paulo"),
     end_date=pendulum.datetime(2026, 3, 3, tz="America/Sao_Paulo"), catchup=True)
def trigger_demo():
    BashOperator(task_id="show",
                 bash_command="echo {{ data_interval_start }} {{ data_interval_end }}")


trigger_demo()
```

```
"""A schedule with intervals: a run for each day, when the day is over."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag
from airflow.timetables.interval import CronDataIntervalTimetable


@dag(schedule=CronDataIntervalTimetable("0 0 * * *", timezone="America/Sao_Paulo"),
     start_date=pendulum.datetime(2026, 3, 1, tz="America/Sao_Paulo"),
     end_date=pendulum.datetime(2026, 3, 3, tz="America/Sao_Paulo"), catchup=True)
def interval_demo():
    BashOperator(task_id="show",
                 bash_command="echo {{ data_interval_start }} {{ data_interval_end }}")


interval_demo()
```

Unpaused, the scheduler creates their runs straight away, because the dates are in the past and
`catchup=True` asks for every one of them:

```
ana@vm:~/etl$ airflow dags reserialize >/dev/null 2>&1; airflow dags unpause trigger_demo; airflow dags unpause interval_demo
dag_id       | is_paused
=============+==========
trigger_demo | True     
                        
dag_id        | is_paused
==============+==========
interval_demo | True     
                         
ana@vm:~/etl$ airflow dags list-runs trigger_demo -o plain | cut -c1-118
dag_id        run_id                                state    run_after                  logical_date               sta
trigger_demo  scheduled__2026-03-03T03:00:00+00:00  success  2026-03-03T03:00:00+00:00  2026-03-03T03:00:00+00:00  202
trigger_demo  scheduled__2026-03-02T03:00:00+00:00  success  2026-03-02T03:00:00+00:00  2026-03-02T03:00:00+00:00  202
trigger_demo  scheduled__2026-03-01T03:00:00+00:00  success  2026-03-01T03:00:00+00:00  2026-03-01T03:00:00+00:00  202
ana@vm:~/etl$ airflow dags list-runs interval_demo -o plain | cut -c1-118
dag_id         run_id                                state    run_after                  logical_date               st
interval_demo  scheduled__2026-03-04T03:00:00+00:00  success  2026-03-04T03:00:00+00:00  2026-03-03T03:00:00+00:00  20
interval_demo  scheduled__2026-03-03T03:00:00+00:00  success  2026-03-03T03:00:00+00:00  2026-03-02T03:00:00+00:00  20
interval_demo  scheduled__2026-03-02T03:00:00+00:00  success  2026-03-02T03:00:00+00:00  2026-03-01T03:00:00+00:00  20
```

Read the `run_after` and `logical_date` columns of each:

- **`trigger_demo`**: each run's logical date *is* its `run_after`. The run at midnight on 1 March is
  for midnight on 1 March. Its data interval, asked of the API, starts and ends at the same moment:
  it covers nothing but an instant.
- **`interval_demo`**: each run happens at the **end** of a day and its logical date is the
  **start** of that day. The run allowed to start at midnight on 2 March is for 1 March, and its
  interval runs from midnight to midnight — the whole of 1 March.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l09-two-schedules\" aria-label=\"Three days on a time line, 1 to 3 March. Above, the trigger schedule: a run at each midnight, for that midnight, covering an instant. Below, the interval schedule: a run at the end of each day, for that day, covering it from midnight to midnight; its first run happens at midnight on 2 March and is for 1 March.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M40.0 240.0 L700.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M80.0 235.0 L80.0 245.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 March</text><path d=\"M270.0 235.0 L270.0 245.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"270.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 March</text><path d=\"M460.0 235.0 L460.0 245.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"460.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 March</text><path d=\"M650.0 235.0 L650.0 245.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"650.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 March</text><text x=\"40.0\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">cron string: a trigger</text><circle cx=\"80.0\" cy=\"60.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M80.0 68.0 L80.0 100.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"270.0\" cy=\"60.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M270.0 68.0 L270.0 100.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"460.0\" cy=\"60.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><path d=\"M460.0 68.0 L460.0 100.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"40.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CronDataIntervalTimetable: an interval</text><rect x=\"82.0\" y=\"140.0\" width=\"186.0\" height=\"22.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">is for 1 March</text><circle cx=\"270.0\" cy=\"186.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"270.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">runs at 2 March</text><rect x=\"272.0\" y=\"140.0\" width=\"186.0\" height=\"22.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">is for 2 March</text><circle cx=\"460.0\" cy=\"186.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"460.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">runs at 3 March</text><rect x=\"462.0\" y=\"140.0\" width=\"186.0\" height=\"22.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">is for 3 March</text><circle cx=\"650.0\" cy=\"186.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"650.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">runs at 4 March</text></svg>", "caption": "The same three days. One schedule runs at each midnight for that instant; the other runs when each day is over, for the whole day."}
```

The second is what Airflow 2 did with every cron string, and it is the shape a daily batch has: a
run for a period, after the period is over. The first is simpler to reason about — a run at a time,
for that time — and leaves the period to the DAG. **Neither is wrong.** What is wrong is a DAG that
assumes one and is given the other, and the symptom is always the same: every run loads the day
next to the one it should.

Ana's DAG uses the first kind and says which day it loads in its own code, `day_to_load`, so the
question never depends on which version of Airflow, or which configuration, it runs under. Had it
used the second kind, its tasks would have read `data_interval_start` and `data_interval_end`
instead, and those would have been the day.
