---
title: A task that never ends
version: 1
---

A failure that raises is the easy kind, because it ends. The hard kind is a task that waits: a
connection that was opened and never answered, a query stuck behind a lock, a process waiting on
input that will not come. **A task that never ends never fails**, so no retry happens and no
callback runs, and the run sits in `running` until somebody notices that the prices are a day old.

`execution_timeout` puts a limit on a single try. Ana watches it work on a task built to hang:

```
"""A task that hangs, and the timeout that stops it."""
import datetime as dt

import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag


@dag(schedule=None, start_date=pendulum.datetime(2026, 3, 1, tz="America/Sao_Paulo"))
def timeout_demo():
    BashOperator(task_id="hangs", bash_command="echo connected; sleep 3600",
                 execution_timeout=dt.timedelta(seconds=20))


timeout_demo()
```

```
ana@vm:~/etl$ airflow dags reserialize >/dev/null 2>&1; airflow dags test timeout_demo 2>&1 | grep -oE "[0-9:]{8}\.[0-9]+Z.*(connected|Process timed out|Sending SIGTERM[^[]*)|AirflowTaskTimeout: .*|new_state=[a-z_]+" | grep -v "Running command" | sed -E "s/^([0-9:]{8})\.[0-9]+Z *\[[a-z ]*\] */\1 UTC /; s/ +$//"
08:40:07 UTC connected
08:40:27 UTC Process timed out
08:40:27 UTC Sending SIGTERM signal to process group
AirflowTaskTimeout: Timeout, PID: 13654
new_state=failed
ana@vm:~/etl$ rm dags/timeout_demo.py; airflow dags delete -y timeout_demo >/dev/null 2>&1
```

Twenty seconds after the command started, Airflow stopped waiting, sent `SIGTERM` to the task's
process group — the shell and the `sleep` inside it — and failed the try with `AirflowTaskTimeout`.
Had the task had retries, the timeout would have counted as one failed try, like any other
exception, and the next try would have started after the delay.

**The two timeouts in `prices_daily` guard different things.** `timeout=10` on each request is the
network's limit: one request that has heard nothing for ten seconds is abandoned, and raises, which
is a passing failure and is retried. `execution_timeout` of two minutes is the whole try's limit,
whatever it is doing — a hundred slow pages, a loop that never finds the last cursor, a `429` that
keeps coming. Setting one does not set the other, and a task with only the first can still run for
ever.

The value is a judgement about the job. Ana's fetch takes a couple of seconds on a good night, so
two minutes is generous and still short enough that a stuck try is noticed the same night. **A
timeout that is too close to the normal duration fails good runs on a slow night**; one that is
too far from it is a timeout in name only.
