#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of pipelines-etl, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: `lab.sh reset` and two days of March
# before the first block, and Ana's project from lessons 6 and 7, copied into
# ~/etl from ../../lab/project. The DAG files are written by `put` and shown in
# the lesson as they are. The version of the DAG without the space after
# run_sql.sh is the one in ../../lab/project with that space removed.
#
# Clock times, run ids and durations are the recording's own and move from run
# to run.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, Apache Airflow 3.3.2,
# 4 cores, TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "$0")/../../capture.sh"
P=$(cd "$(dirname "$0")/../../lab/project" && pwd)
lab reset >/dev/null
lab until 2026-03-02 >/dev/null
for f in $(cd "$P" && find . -type f ! -name README ! -path './dags/*' | sed 's|^\./||'); do put "$f" < "$P/$f"; done
lab exec 'touch landing/prices.jsonl'

block start
root 'airflow'
on 'pgrep -u ana -fa "bin/airflow [a-z-]*$|airflow api_server"'
on 'curl -s http://127.0.0.1:8080/api/v2/version; echo'

block env
on 'grep "^AIRFLOW" /etc/etl.env | grep -v -e JWT -e CONN'
block conn
on 'grep "^AIRFLOW_CONN" /etc/etl.env'

put trace.sh <<'SH'
#!/bin/sh
# airflow dags test prints every line of every task's log. Keep the lines that
# say what ran, how it ended, and any error.
grep -oE "\[DAG TEST\] end task task_id=[a-z_]+|Running command: \[[^]]*\]|Command exited with return code [0-9]+|[A-Za-z0-9.]*(Error|NotFound): .*|DagRun Finished: dag_id=[a-z_]+, logical_date=[^,]+|state=[a-z]+, run_type=[a-z]+"
SH
code trace-sh trace.sh

sed 's/"sh run_sql.sh "/"sh run_sql.sh"/' "$P/dags/shop_nightly.py" | grep -v "The space after run_sql.sh\|read as the name of a template" | put dags/shop_nightly.py
code first-dag dags/shop_nightly.py
block first-run
on 'airflow dags reserialize >/dev/null 2>&1; airflow dags list'
on 'airflow dags test shop_nightly 2026-03-03 2>&1 | wc -l'
on 'airflow dags test shop_nightly 2026-03-03 2>&1 | sh trace.sh'

put dags/shop_nightly.py < "$P/dags/shop_nightly.py"
code fixed-dag dags/shop_nightly.py
block second-run
on 'airflow dags test shop_nightly 2026-03-03 2>&1 | sh trace.sh'
on 'psql -d wh -c "SELECT order_date, count(*) FROM marts.fact_sales GROUP BY 1"'

block shape
on 'airflow dags show shop_nightly 2>/dev/null | grep -- "->"'

block runs
on 'airflow dags list-runs shop_nightly -o plain'

put xcom.sh <<'SH'
#!/bin/sh
# The value a task returned in the latest run of a DAG, asked of Airflow's API.
dag=$1 task=$2
run=$(airflow dags list-runs "$dag" -o json | python -c 'import json, sys; print(json.load(sys.stdin)[0]["run_id"])')
curl -s "http://127.0.0.1:8080/api/v2/dags/$dag/dagRuns/$run/taskInstances/$task/xcomEntries/return_value" |
  python -c 'import json, sys; x = json.load(sys.stdin); print(x["logical_date"], x["task_id"], "returned", repr(x["value"]))'
SH
code xcom-sh xcom.sh
block xcom
on 'sh xcom.sh shop_nightly day_to_load'

put dags/by_shop.py <<'PY'
"""One task per shop, worked out by asking the shop's database which shops exist."""
import pendulum
import psycopg
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag

with psycopg.connect("dbname=shop") as shop:                 # runs on every parse
    SHOPS = shop.execute("SELECT shop_id, name FROM shops ORDER BY shop_id").fetchall()


@dag(schedule=None, start_date=pendulum.datetime(2026, 3, 1, tz="America/Sao_Paulo"))
def by_shop():
    for shop_id, name in SHOPS:
        BashOperator(task_id=f"report_shop_{shop_id}", bash_command=f"echo '{name}'")


by_shop()
PY
code by-shop-py dags/by_shop.py
block parse
on 'airflow dags reserialize >/dev/null 2>&1; airflow dags report'
on 'psql -d shop -Atc "SELECT xact_commit FROM pg_stat_database WHERE datname = current_database()"; sleep 120; psql -d shop -Atc "SELECT xact_commit FROM pg_stat_database WHERE datname = current_database()"'
