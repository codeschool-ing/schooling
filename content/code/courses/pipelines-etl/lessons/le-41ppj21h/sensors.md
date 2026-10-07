---
title: Sensors: waiting for the world
version: 1
---

The distributor drops its stock file at about six in the morning — about. Some days at 05:40, some
days at 07:10, once in a while not at all. A task scheduled for 06:00 that reads the file is a task
that fails one morning in three. **A sensor is a task whose only job is to wait until something is
true**, and to let the tasks after it run when it is.

Airflow's `FileSensor` waits for a file, and finds it through a **connection** of type `fs` whose
`path` is the directory to look in. Ana adds one with the CLI, which stores it in Airflow's
metadata database:

```
ana@vm:~/etl$ airflow connections add fs_inbox --conn-type fs --conn-extra '{"path": "/home/ana/etl/inbox"}'
2026-10-07T05:21:32.889266Z [warning  ] ProvidersManager.hooks is deprecated. Use ProvidersManagerTaskRuntime.hooks from task-sdk instead. [py.warnings] category=DeprecatedImportWarning filename=/opt/etl/airflow/lib/python3.13/site-packages/airflow/cli/commands/connection_command.py lineno=240
Successfully added `conn_id`=fs_inbox
conn_id  | conn_type | host | login | port | extra                          
=========+===========+======+=======+======+================================
fs_inbox | fs        | None | None  | None | {'path': '/home/ana/etl/inbox'}
```

Then a DAG that waits for the day's stock file and loads it with lesson 3's loader:

```
"""Load the distributor's stock file for a day, once it has arrived."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.providers.standard.sensors.filesystem import FileSensor
from airflow.sdk import dag

DAY = "{{ logical_date.in_timezone('America/Sao_Paulo').strftime('%Y-%m-%d') }}"


@dag(schedule="0 6 * * *",
     start_date=pendulum.datetime(2026, 3, 2, tz="America/Sao_Paulo"), catchup=False)
def stock_file():
    arrived = FileSensor(
        task_id="arrived",
        fs_conn_id="fs_inbox",
        filepath=f"stock_{DAY}.csv",
        poke_interval=5,            # look every five seconds
        timeout=2 * 60 * 60,        # give up after two hours
        mode="poke",
    )
    load = BashOperator(task_id="load",
                        bash_command=f"python load_stock.py inbox/stock_{DAY}.csv",
                        cwd="/home/ana/etl")
    arrived >> load


stock_file()
```

Ana tests it for 8 March before the lab has played that day. The file is not there; twelve seconds
later the lab plays the day, and the distributor's file arrives:

```
ana@vm:~/etl$ airflow dags test stock_file 2026-03-08 2>&1 | grep -oE "Poking for file [^ ]*|Success criteria met|[0-9]+ rows loaded|[A-Za-z]*(Error|NotFound): .*|state=[a-z]+, run_type=[a-z]+" | uniq -c
      3 Poking for file /home/ana/etl/inbox/stock_2026-03-08.csv
      1 Success criteria met
      1 Poking for file /home/ana/etl/inbox/stock_2026-03-08.csv
      1 1200 rows loaded
      1 state=success, run_type=manual
```

Three pokes, five seconds apart, found nothing. Then the file was there, the sensor succeeded, and
the load ran: 1,200 rows. Nothing was scheduled at a lucky moment. **The DAG runs at 06:00 and the
data arrives when it arrives**, and the sensor is what joins the two.

## Three ways to wait

A sensor that waits is a task that runs, and a running task occupies a worker. That decides how it
should wait:

| mode | while waiting | right for |
|---|---|---|
| `poke` | holds its worker, checks every `poke_interval` | short waits, seconds to a few minutes |
| `reschedule` | releases its worker between checks; the scheduler starts it again | waits of minutes to hours |
| `deferrable=True` | hands the waiting to the triggerer, which watches thousands of conditions in one process | many sensors, long waits |

The test above used `poke`, because `dags test` runs in one process. **A nightly DAG that waits up
to two hours should not hold a worker for two hours**: with `poke` and sixteen such DAGs, every
worker would be asleep waiting for files and nothing else could run. `reschedule` or a deferrable
sensor is what production wants.

## The timeout is the point

`timeout=2 * 60 * 60` says: give up after two hours. Without it, a sensor waits for ever for a file
that will never come, and the run never finishes — **not failed, just running**, which nobody's
alert is looking for. With it, the sensor fails at 08:00 and lesson 10's alerts can say so. Every
sensor needs a timeout chosen by somebody who knows how late "late" is.
