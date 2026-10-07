#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of pipelines-etl, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: `lab.sh reset` and the first nine days
# of March before the first block; Ana's project from lessons 6 to 9, copied
# into ~/etl from ../../lab/project; the price API and Airflow started with
# `lab.sh api` and `lab.sh airflow`; the price API's outage, switched on and
# off from here with `lab.sh outage` where the lesson says the API went down
# or came back; alerts.log emptied after the `fail-fast` block, whose test
# runs wrote to it; and the waits between blocks, which give the scheduler
# time to act. THE NIGHT IS STAGED TOO: the lab cannot wait for three in the
# morning, so the run for 03:00 on 10 March is triggered by hand with the API
# already down. The files are written by `put` and shown in the lesson.
#
# Clock times, run ids, and the seconds between one try and the next are the
# recording's own, and move from run to run.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, Apache Airflow 3.3.2,
# 4 cores, TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "$0")/../../capture.sh"
P=$(cd "$(dirname "$0")/../../lab/project" && pwd)
lab reset >/dev/null
lab until 2026-03-09 >/dev/null
for f in $(cd "$P" && find . -type f ! -name README | sed 's|^\./||'); do put "$f" < "$P/$f"; done
lab exec 'touch landing/prices.jsonl; python load_raw.py >/dev/null; sh run_sql.sh >/dev/null'
lab api >/dev/null
lab airflow >/dev/null

lab exec 'mkdir -p ~/airflow/plugins'
lab exec 'cat > ~/airflow/plugins/oncall.py' <<'PY'
"""Ponto Final's on-call helpers, imported by the DAGs.

In Airflow's plugins folder rather than in dags/, because a deadline's callback
runs in the triggerer, and the triggerer can import from here and not from dags/."""
import pendulum

ALERTS = "/home/ana/etl/alerts.log"


def note(text):
    now = pendulum.now("America/Sao_Paulo").strftime("%Y-%m-%d %H:%M:%S")
    with open(ALERTS, "a") as f:
        f.write(f"{now} {text}\n")


def failed(context):
    """A task has failed for good: no tries left, or none allowed."""
    ti = context["ti"]
    note(f"FAILED {ti.dag_id}.{ti.task_id} run={ti.run_id} try={ti.try_number} "
         f"error={context.get('exception')!r}")


async def late(context, **kwargs):
    """A run has not finished by its deadline, whatever it is doing."""
    run = context["dag_run"]
    note(f"LATE {run['dag_id']} run={run['dag_run_id']} state={run['state']}")
PY
put dags/prices_daily.py <<'PY'
"""The publishers' prices, every night at 03:00, and what to do when the API is down."""
import datetime as dt
import json
import os
import time

import pendulum
import requests
from airflow.sdk import AsyncCallback, DeadlineAlert, DeadlineReference, dag, task
from airflow.sdk.exceptions import AirflowFailException
from oncall import failed, late

URL = "http://127.0.0.1:8081/v1/prices"


@dag(
    schedule="0 3 * * *",
    start_date=pendulum.datetime(2026, 3, 2, tz="America/Sao_Paulo"),
    catchup=False,
    default_args={
        "retries": 4,
        "retry_delay": dt.timedelta(seconds=15),
        "retry_exponential_backoff": 2.0,              # 15 s, then 30, 60, 120
        "execution_timeout": dt.timedelta(minutes=2),
        "on_failure_callback": failed,
    },
    deadline=DeadlineAlert(
        reference=DeadlineReference.DAGRUN_QUEUED_AT,
        interval=dt.timedelta(minutes=2),
        callback=AsyncCallback(late),
    ),
)
def prices_daily():
    @task
    def fetch() -> int:
        headers = {"X-Api-Key": os.environ["PRICES_API_KEY"]}
        params, rows = {"page_size": 200}, []
        while True:
            r = requests.get(URL, headers=headers, params=params, timeout=10)
            if r.status_code == 429:                  # too fast: wait as told, ask again
                time.sleep(float(r.headers.get("Retry-After", "1")))
                continue
            if r.status_code in (400, 401, 403):      # asking again will not change the answer
                raise AirflowFailException(f"the API refused the request: {r.status_code} {r.text}")
            r.raise_for_status()                      # 5xx: worth another try, later
            body = r.json()
            rows += body["data"]
            if body["next_cursor"] is None:
                break
            params["cursor"] = body["next_cursor"]
        with open("/home/ana/etl/landing/prices.jsonl", "w") as out:
            out.writelines(json.dumps(row) + "\n" for row in rows)
        return len(rows)

    fetch()


prices_daily()
PY
code oncall-py ../airflow/plugins/oncall.py
code prices-py dags/prices_daily.py

block import-error
sleep 15
on 'airflow dags list-import-errors -o plain | grep -oE "Error: .*"'
root 'airflow-down'
root 'airflow'
on 'airflow dags reserialize >/dev/null 2>&1; airflow dags list-import-errors'

block fail-fast
on 'PRICES_API_KEY=wrong airflow tasks test prices_daily fetch 2026-03-09 2>&1 | grep -oE "new_state=[a-z_]+|[A-Za-z.]*(Exception|Error): .*" | uniq'
lab outage on
on 'airflow tasks test prices_daily fetch 2026-03-09 2>&1 | grep -oE "new_state=[a-z_]+|[A-Za-z.]*(Exception|Error): .*" | uniq'
lab outage off
lab exec 'rm -f alerts.log'

put dags/timeout_demo.py <<'PY'
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
PY
code timeout-py dags/timeout_demo.py
block timeout
on 'airflow dags reserialize >/dev/null 2>&1; airflow dags test timeout_demo 2>&1 | grep -oE "[0-9:]{8}\.[0-9]+Z.*(connected|Process timed out|Sending SIGTERM[^[]*)|AirflowTaskTimeout: .*|new_state=[a-z_]+" | grep -v "Running command" | sed -E "s/^([0-9:]{8})\.[0-9]+Z *\[[a-z ]*\] */\1 UTC /; s/ +$//"'
on 'rm dags/timeout_demo.py; airflow dags delete -y timeout_demo >/dev/null 2>&1'

put tries.sh <<'SH'
#!/bin/sh
# Every try of one task in one run, from Airflow's API: when it ran and how it ended.
curl -s "http://127.0.0.1:8080/api/v2/dags/$1/dagRuns/$2/taskInstances/$3/tries" |
  python -c 'import json, sys
for t in json.load(sys.stdin)["task_instances"]:
    print("try", t["try_number"], t["state"], (t["start_date"] or "")[11:19], "to", (t["end_date"] or "")[11:19])'
SH
code tries-sh tries.sh

block retries
lab outage on
on 'airflow dags unpause prices_daily'
for i in $(seq 120); do lab exec "psql -d airflow -Atc \"SELECT try_number, state FROM task_instance WHERE dag_id = 'prices_daily'\"" | grep -q '^2|up_for_retry' && break; sleep 2; done
lab outage off
for i in $(seq 120); do lab exec 'airflow dags list-runs prices_daily -o plain' | grep -q "success\|failed" && break; sleep 5; done
on 'airflow dags list-runs prices_daily -o plain | cut -c1-118'
on 'sh tries.sh prices_daily $(airflow dags list-runs prices_daily -o plain | grep -o "scheduled__[^ ]*") fetch'
on 'cat alerts.log'

block night
lab outage on
on 'airflow dags trigger prices_daily --logical-date 2026-03-10T03:00:00-03:00 -o plain >/dev/null; airflow dags list-runs prices_daily -o plain | cut -c1-118'
for i in $(seq 120); do lab exec 'airflow dags list-runs prices_daily -o plain' | grep "manual__" | grep -q "success\|failed" && break; sleep 5; done
sleep 5
block alerts
on 'cat alerts.log'

block investigate
on 'airflow dags list-runs prices_daily -o plain | cut -c1-118'
on 'RUN=$(airflow dags list-runs prices_daily -o plain | grep -o "manual__[^ ]*"); sh tries.sh prices_daily $RUN fetch'
on 'grep -ho "\"exc_type\":\"[A-Za-z]*\",\"exc_value\":\"[^\"]*\"" ~/airflow/logs/dag_id=prices_daily/run_id=manual__*/task_id=fetch/attempt=*.log | sort | uniq -c'
on 'curl -s -o /dev/null -w "%{http_code}\n" -H "X-Api-Key: $PRICES_API_KEY" http://127.0.0.1:8081/v1/prices'
lab outage off
block back
on 'curl -s -o /dev/null -w "%{http_code}\n" -H "X-Api-Key: $PRICES_API_KEY" http://127.0.0.1:8081/v1/prices'

block clear
on 'airflow tasks clear prices_daily -t fetch -s 2026-03-10T03:00:00-03:00 -e 2026-03-10T03:00:00-03:00 --only-failed -y 2>&1 | tail -n 3 | cut -c1-118'
for i in $(seq 120); do lab exec 'airflow dags list-runs prices_daily -o plain' | grep "manual__" | grep -q "success\|failed" && break; sleep 5; done
on 'airflow dags list-runs prices_daily -o plain | cut -c1-118'
on 'RUN=$(airflow dags list-runs prices_daily -o plain | grep -o "manual__[^ ]*"); sh tries.sh prices_daily $RUN fetch'
on 'wc -l < landing/prices.jsonl; cat alerts.log'
