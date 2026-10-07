---
title: Prefect: a pipeline is a Python function
version: 1
---

```
"""The nightly load as a Prefect flow: plain Python functions, called in order."""
import subprocess
import sys

from prefect import flow, task


@task(retries=2, retry_delay_seconds=10)
def load_raw():
    subprocess.run(["python", "load_raw.py"], check=True)


@task
def build_models():
    subprocess.run(["dbt", "build", "--project-dir", "shop", "--quiet"], check=True)


@task
def daily_report(day: str) -> str:
    query = ("COPY (SELECT shop_id, category, books, revenue_cents FROM dbt_marts.daily_sales "
             f"WHERE order_date = '{day}' ORDER BY 1, 2) TO STDOUT WITH (FORMAT csv, HEADER)")
    csv = subprocess.run(["psql", "-d", "wh", "-c", query], check=True,
                         capture_output=True, text=True).stdout
    path = f"reports/daily_{day}.csv"
    with open(path, "w") as out:
        out.write(csv)
    return path


@flow(log_prints=True)
def nightly(day: str):
    load_raw()
    build_models()
    path = daily_report(day)
    print(f"report written to {path}")


if __name__ == "__main__":
    nightly(sys.argv[1])
```

Prefect's pipeline is a **flow**, a Python function with `@flow` on it, and its steps are **tasks**,
functions with `@task`. There is no `>>` and no `requires`: the order is the order of the calls, and
when a task needs another's result it is simply passed as an argument. `retries` is a setting on the
task, as in Airflow. Anything Python can do between the calls — an `if`, a loop over shops — is part
of the flow, which is the main thing Prefect offers over writing the same steps for Airflow.

Every run is recorded by a Prefect server. With none configured, Prefect starts a temporary one for
the length of the run and stops it at the end. That server also tries to send usage statistics to
the internet, which the lab does not have; one setting turns it off, and is saved in Prefect's
profile:

```
ana@vm:~/etl$ prefect config set PREFECT_SERVER_ANALYTICS_ENABLED=false
Set 'PREFECT_SERVER_ANALYTICS_ENABLED' to 'false'.
Updated profile 'ephemeral'.
ana@vm:~/etl$ /opt/etl/prefect/bin/python nightly_prefect.py 2026-03-15
03:41:45.061 | INFO    | prefect - Starting temporary server on http://127.0.0.1:8147
See https://docs.prefect.io/v3/concepts/server#how-to-guides for more information on running a dedicated Prefect server.
03:41:54.655 | INFO    | Flow run 'burgundy-jackrabbit' - Beginning flow run 'burgundy-jackrabbit' for flow 'nightly'
raw.shops: 7 rows
raw.books: 1200 rows
raw.customers: 5366 rows
raw.orders: 21128 rows
raw.order_lines: 33047 rows
raw.payments: 21128 rows
raw.prices: 0 documents
raw.events: 38837 documents
03:41:55.273 | INFO    | Task run 'load_raw-626' - Finished in state Completed()
03:41:58.636 | INFO    | Task run 'build_models-8ec' - Finished in state Completed()
03:41:58.654 | INFO    | Task run 'daily_report-da6' - Finished in state Completed()
03:41:58.655 | INFO    | Flow run 'burgundy-jackrabbit' - report written to reports/daily_2026-03-15.csv
03:41:59.687 | INFO    | Flow run 'burgundy-jackrabbit' - Finished in state Completed()
03:41:59.700 | INFO    | prefect - Stopping temporary server on http://127.0.0.1:8147
```

Each task's state is logged as it finishes, with a name Prefect made up for the run. The `print`
inside the flow is logged too, because of `log_prints=True`. Now the same flow, same day, again:

```
ana@vm:~/etl$ /opt/etl/prefect/bin/python nightly_prefect.py 2026-03-15 2>&1 | grep -E "Task run|Flow run"
03:42:07.274 | INFO    | Flow run 'voracious-pug' - Beginning flow run 'voracious-pug' for flow 'nightly'
03:42:07.839 | INFO    | Task run 'load_raw-1ab' - Finished in state Completed()
03:42:11.178 | INFO    | Task run 'build_models-a5d' - Finished in state Completed()
03:42:11.196 | INFO    | Task run 'daily_report-7f1' - Finished in state Completed()
03:42:11.197 | INFO    | Flow run 'voracious-pug' - report written to reports/daily_2026-03-15.csv
03:42:11.303 | INFO    | Flow run 'voracious-pug' - Finished in state Completed()
```

**Everything ran again.** Prefect does not ask whether a task's work is already there; a flow run is
a call, and calling a function twice runs it twice. That is the opposite trade from Luigi's: no
marker can go stale, because there are none, and nothing is ever skipped by mistake. But nothing is
skipped on purpose either, and a flow that failed at its last step repeats its first ones on the next
call. Prefect can **cache** a task's result under a key, which brings back the skipping when it is
wanted; this lesson does not use it.

Scheduling a flow — every night at 02:00 — is a **deployment**, which needs a Prefect server running
all the time and a worker to pick up the runs. The lab runs neither, so none is shown here.
