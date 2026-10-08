---
title: Dates in templates, and whose day `ds` is
version: 1
---

Templated arguments can use the run's dates directly, which is why most Airflow examples load "the
day" with `{{ ds }}` and never write a function like `day_to_load`. `ds` is the run's logical date
as `YYYY-MM-DD`, and there are cousins for everything around it: `ds_nodash`, `data_interval_start`,
`macros.ds_add(ds, -1)` for the day before.

**`ds` is a date in UTC.** Ana's runs happen at 02:00 in São Paulo, which is 05:00 in UTC, on the
same day, so `ds` and the São Paulo date agree and nobody notices. Move a run late into the evening
and they stop agreeing:

```
"""What {{ ds }} says for a run late in the evening, São Paulo time."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag


@dag(schedule=None, start_date=pendulum.datetime(2026, 3, 1, tz="America/Sao_Paulo"))
def ds_demo():
    BashOperator(task_id="show", bash_command=(
        "echo ds={{ ds }}; "
        "echo logical_date={{ logical_date }}; "
        "echo in_sao_paulo={{ logical_date.in_timezone('America/Sao_Paulo') }}"))


ds_demo()
```

```
ana@vm:~/etl$ airflow dags reserialize >/dev/null 2>&1; airflow dags test ds_demo 2026-03-02T23:30:00-03:00 2>&1 | grep -oE "(ds|logical_date|in_sao_paulo)=[0-9-]+( [0-9:+-]+)?" | sort -u
ds=2026-03-03
in_sao_paulo=2026-03-02 23:30:00-03:00
logical_date=2026-03-03 02:30:00+00:00
```

A run at 23:30 on 2 March in São Paulo has a `ds` of 3 March, because in UTC it is already 02:30 on
the 3rd. A DAG that loaded `{{ ds }}` from such a run would load tomorrow, with nothing in it yet —
and succeed.

This is lesson 6's trouble with `::date`, arriving again through a template. The cure is the same:
**write the time zone where the date is made**. Ana's DAG does it in `day_to_load`, and her sensor
in the next section does it in the template itself, with
`logical_date.in_timezone('America/Sao_Paulo')`. Either is fine; what matters is that the zone is
written down rather than inherited.
