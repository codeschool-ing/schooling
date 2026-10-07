---
title: Operators, hooks and connections
version: 1
---

Every task is an instance of an **operator**: a class that knows how to do one kind of work.
`BashOperator` runs a shell command; `@task` turns a Python function into a `PythonOperator`; and
providers add hundreds more — `SQLExecuteQueryOperator` runs SQL against any database Airflow has a
connection for, and there are operators for every cloud's storage, warehouse and queue.

**Choosing an operator is choosing where the work happens.** Ana's tasks are all `BashOperator`s
calling her own scripts, on purpose: the scripts run the same way from her terminal, from
`nightly.sh` and from Airflow, so a task that fails can be rerun by hand with the same command and
the same result. An operator that hides the work inside Airflow is harder to run anywhere else.

## Templates, and why `sh run_sql.sh` failed

Some of an operator's arguments are **templated**: before the task runs, Airflow renders them as
Jinja templates, so `{{ ds }}` becomes the run's date and `{{ ti.xcom_pull(...) }}` becomes another
task's answer. `bash_command` is one of them, and it has one more rule: **a value ending in `.sh` or
`.bash` is taken to be the name of a template file**, which Airflow loads from the DAG's folder and
renders. That is meant for long scripts kept beside the DAG. `sh run_sql.sh` ends in `.sh`, so Airflow
went looking for a file called `sh run_sql.sh` in `~/etl/dags`, found none, and failed before
running anything.

The fix that Airflow's own documentation gives is a trailing space, so the value no longer ends in
`.sh`:

```
"""Ponto Final's nightly load: the shop into raw, staging rebuilt, the marts loaded."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag, task

ETL = "/home/ana/etl"
PSQL = "psql -q -v ON_ERROR_STOP=1 -d wh"


@dag(
    schedule="0 2 * * *",
    start_date=pendulum.datetime(2026, 3, 2, tz="America/Sao_Paulo"),
    catchup=False,
    tags=["shop"],
)
def shop_nightly():
    @task
    def day_to_load(logical_date=None) -> str:
        """The run at 02:00 loads the day that has just ended, in São Paulo."""
        return logical_date.in_timezone("America/Sao_Paulo").subtract(days=1).to_date_string()

    day = day_to_load()
    extract = BashOperator(task_id="extract", bash_command="python load_raw.py", cwd=ETL)
    # The space after run_sql.sh is deliberate: a command ending in ".sh" is read
    # as the name of a template file to load, and fails before it runs.
    transform = BashOperator(task_id="transform", bash_command="sh run_sql.sh ", cwd=ETL)
    dim_customer = BashOperator(task_id="dim_customer",
                                bash_command=f"{PSQL} -f load/dim_customer.sql", cwd=ETL)
    dim_book = BashOperator(task_id="dim_book",
                            bash_command=f"{PSQL} -f load/dim_book.sql", cwd=ETL)
    fact_sales = BashOperator(task_id="fact_sales",
                              bash_command=f"{PSQL} -v day={day} -f load/fact_sales.sql",
                              cwd=ETL)

    extract >> transform >> [dim_customer, dim_book]
    [day, dim_customer] >> fact_sales


shop_nightly()
```

The comment above the line is part of the fix. A trailing space is invisible, and the next person
to tidy the file would remove it.

## Connections

A task that talks to a database needs to know where it is and how to log in, and **that belongs to
the machine, not to the DAG**. Airflow keeps it in a *connection* with an id, and an operator or hook
asks for the id. The lab declares two, as environment variables, which is one of the places Airflow
looks:

```
ana@vm:~/etl$ grep "^AIRFLOW_CONN" /etc/etl.env
AIRFLOW_CONN_SHOP=postgresql://ana@%2Frun%2Fetl-pg/shop
AIRFLOW_CONN_WH=postgresql://ana@%2Frun%2Fetl-pg/wh
```

`AIRFLOW_CONN_WH` is the connection `wh`: PostgreSQL, as `ana`, over the socket in `/run/etl-pg`, to
the database `wh`. A **hook** is the class that turns a connection id into a live connection —
`PostgresHook("wh")` — and every SQL operator uses one inside. Ana's tasks call `psql` instead, which
finds the same database through `PGHOST`; lesson 18 moves connections and secrets out of the
environment and says why that matters when there is more than one environment.
