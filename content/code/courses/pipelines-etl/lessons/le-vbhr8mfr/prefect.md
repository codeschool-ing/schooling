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
05:49:57.107 | INFO    | prefect - Starting temporary server on http://127.0.0.1:8146
See https://docs.prefect.io/v3/concepts/server#how-to-guides for more information on running a dedicated Prefect server.
05:50:07.106 | INFO    | Flow run 'fiery-sloth' - Beginning flow run 'fiery-sloth' for flow 'nightly'
raw.shops: 7 rows
raw.books: 1200 rows
raw.customers: 5366 rows
raw.orders: 21128 rows
raw.order_lines: 33047 rows
raw.payments: 21128 rows
raw.prices: 0 documents
raw.events: 38837 documents
05:50:07.636 | INFO    | Task run 'load_raw-851' - Finished in state Completed()
05:50:10.976 | INFO    | Task run 'build_models-1e7' - Finished in state Completed()
05:50:10.993 | INFO    | Task run 'daily_report-c31' - Finished in state Completed()
05:50:10.994 | INFO    | Flow run 'fiery-sloth' - report written to reports/daily_2026-03-15.csv
05:50:11.135 | INFO    | Flow run 'fiery-sloth' - Finished in state Completed()
05:50:11.149 | INFO    | prefect - Stopping temporary server on http://127.0.0.1:8146
```

Each task's state is logged as it finishes, with a name Prefect made up for the run. The `print`
inside the flow is logged too, because of `log_prints=True`. Now the same flow, same day, again:

```
ana@vm:~/etl$ /opt/etl/prefect/bin/python nightly_prefect.py 2026-03-15 2>&1 | grep -E "Task run|Flow run"
05:50:18.995 | INFO    | Flow run 'spry-coati' - Beginning flow run 'spry-coati' for flow 'nightly'
05:50:19.520 | INFO    | Task run 'load_raw-64a' - Finished in state Completed()
05:50:23.043 | INFO    | Task run 'build_models-6b4' - Finished in state Completed()
05:50:23.059 | INFO    | Task run 'daily_report-195' - Finished in state Completed()
05:50:23.060 | INFO    | Flow run 'spry-coati' - report written to reports/daily_2026-03-15.csv
05:50:24.023 | INFO    | Flow run 'spry-coati' - Finished in state Completed()
```

**Everything ran again.** Prefect does not ask whether a task's work is already there; a flow run is
a call, and calling a function twice runs it twice. That is the opposite trade from Luigi's: no
marker can go stale, because there are none, and nothing is ever skipped by mistake. But nothing is
skipped on purpose either, and a flow that failed at its last step repeats its first ones on the next
call. Prefect can **cache** a task's result under a key, which brings back the skipping when it is
wanted; this lesson does not use it.

Scheduling a flow — every night at 02:00 — is a **deployment**, which needs a Prefect server running
all the time and a worker to pick up the runs. The lab runs neither, so none is shown here.
