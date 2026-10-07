#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of pipelines-etl, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: `lab.sh reset` and the first two days of
# March before the first block; Ana's project from lessons 6 to 8, copied into
# ~/etl from ../../lab/project; Airflow started with `lab.sh airflow`; the
# waits between blocks, which give the scheduler time to act; and in the
# `sensor` block, the day of trade played from here in the background twelve
# seconds after the test run starts, which is how the stock file arrives while
# the sensor waits. The DAG files are written by `put` and shown in the lesson.
#
# Clock times, run ids and how many runs the scheduler had created by the
# moment a command looked are the recording's own, and move from run to run.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, Apache Airflow 3.3.2,
# 4 cores, TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "$0")/../../capture.sh"
P=$(cd "$(dirname "$0")/../../lab/project" && pwd)
lab reset >/dev/null
lab until 2026-03-02 >/dev/null
for f in $(cd "$P" && find . -type f ! -name README | sed 's|^\./||'); do put "$f" < "$P/$f"; done
lab exec 'touch landing/prices.jsonl; python load_raw.py >/dev/null; sh run_sql.sh >/dev/null'
lab airflow >/dev/null
lab exec 'airflow dags reserialize >/dev/null 2>&1'

block unpause
on 'airflow dags next-execution shop_nightly 2>/dev/null'
on 'airflow dags unpause shop_nightly'
sleep 40
on 'airflow dags list-runs shop_nightly -o plain'
on 'psql -d wh -c "SELECT order_date, count(*) FROM marts.fact_sales GROUP BY 1 ORDER BY 1"'
on 'airflow dags pause shop_nightly'

put dags/trigger_demo.py <<'PY'
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
PY
put dags/interval_demo.py <<'PY'
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
PY
code trigger-py dags/trigger_demo.py
code interval-py dags/interval_demo.py
block schedules
on 'airflow dags reserialize >/dev/null 2>&1; airflow dags unpause trigger_demo; airflow dags unpause interval_demo'
sleep 40
on "airflow dags list-runs trigger_demo -o plain | cut -c1-118"
on "airflow dags list-runs interval_demo -o plain | cut -c1-118"
put intervals.sh <<'SH'
#!/bin/sh
# The data interval each run of a DAG was given, read from Airflow's API.
curl -s "http://127.0.0.1:8080/api/v2/dags/$1/dagRuns?order_by=logical_date" |
  python -c 'import json, sys
for r in json.load(sys.stdin)["dag_runs"]:
    print(r["logical_date"], "covers", r["data_interval_start"], "to", r["data_interval_end"])'
SH
code intervals-sh intervals.sh
on 'sh intervals.sh trigger_demo'
on 'sh intervals.sh interval_demo'

put dags/catchup_demo.py <<'PY'
"""catchup=True, a start date in the past, and no end date."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag


@dag(schedule="0 2 * * *",
     start_date=pendulum.datetime(2026, 3, 2, tz="America/Sao_Paulo"), catchup=True)
def catchup_demo():
    BashOperator(task_id="load", bash_command="echo loading the day before {{ ds }}")


catchup_demo()
PY
code catchup-py dags/catchup_demo.py
block catchup
on 'airflow dags reserialize >/dev/null 2>&1; airflow dags unpause catchup_demo'
sleep 20
on 'airflow dags list-runs catchup_demo -o plain | tail -n +2 | wc -l'
on 'airflow dags list-runs catchup_demo -o plain | tail -n +2 | tr -s " " | cut -d" " -f3 | sort | uniq -c'
on 'airflow dags pause catchup_demo; airflow dags delete -y catchup_demo; rm dags/catchup_demo.py'

block backfill
root 'until 2026-03-07'
on 'airflow backfill create --dag-id shop_nightly --from-date 2026-03-03 --to-date 2026-03-08 2>&1 | grep -c "Created backfill Dag run"'
on 'airflow dags unpause shop_nightly'
for i in $(seq 120); do lab exec 'airflow dags list-runs shop_nightly -o plain 2>/dev/null' | grep -q "queued\|running" || break; sleep 5; done
sleep 60   # the backfill is closed, and the task logs written, a little after the runs end
on 'airflow dags list-runs shop_nightly -o plain | cut -c1-118'
on 'psql -d wh -c "SELECT order_date, count(*) FROM marts.fact_sales GROUP BY 1 ORDER BY 1"'
for i in $(seq 60); do lab exec 'grep -lq "ERROR:" ~/airflow/logs/dag_id=shop_nightly/run_id=backfill__*/task_id=*/attempt=1.log' && break; sleep 5; done
block collisions
on 'grep -ho "ERROR: [^\\]*" ~/airflow/logs/dag_id=shop_nightly/run_id=backfill__*/task_id=*/attempt=1.log | sort | uniq -c'
block one-at-a-time
on "sed -i 's|    tags=\\[\"shop\"\\],|    tags=[\"shop\"],\\n    max_active_runs=1,          # every run rebuilds raw and staging: one at a time|' dags/shop_nightly.py"
on 'grep -n -B1 -A1 max_active_runs dags/shop_nightly.py'
on 'airflow dags reserialize >/dev/null 2>&1; airflow backfill create --dag-id shop_nightly --from-date 2026-03-03 --to-date 2026-03-08T12:00:00-03:00 --reprocess-behavior failed --max-active-runs 1 2>&1 | grep -c "Created backfill Dag run"'
for i in $(seq 180); do lab exec 'airflow dags list-runs shop_nightly -o plain 2>/dev/null' | grep -q "queued\|running" || break; sleep 5; done
on 'airflow dags list-runs shop_nightly -o plain | cut -c1-118'
on 'psql -d wh -c "SELECT order_date, count(*) FROM marts.fact_sales GROUP BY 1 ORDER BY 1"'

put dags/ds_demo.py <<'PY'
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
PY
code ds-py dags/ds_demo.py
block ds
on 'airflow dags reserialize >/dev/null 2>&1; airflow dags test ds_demo 2026-03-02T23:30:00-03:00 2>&1 | grep -oE "(ds|logical_date|in_sao_paulo)=[0-9-]+( [0-9:+-]+)?" | sort -u'

block connection
on "airflow connections add fs_inbox --conn-type fs --conn-extra '{\"path\": \"/home/ana/etl/inbox\"}'"
put dags/stock_file.py <<'PY'
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
PY

code stock-py dags/stock_file.py
block sensor
lab exec 'airflow dags reserialize >/dev/null 2>&1; airflow dags list 2>/dev/null | grep -c stock_file' >/dev/null
(sleep 12; lab day 2026-03-08 >/dev/null) &
on 'airflow dags test stock_file 2026-03-08 2>&1 | grep -oE "Poking for file [^ ]*|Success criteria met|[0-9]+ rows loaded|[A-Za-z]*(Error|NotFound): .*|state=[a-z]+, run_type=[a-z]+" | uniq -c'
wait

put dags/sales_report.py <<'PY'
"""A report that runs whenever the fact table has been loaded, whoever loaded it."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import Asset, dag

FACT_SALES = Asset("postgres://localhost:5432/wh/marts/fact_sales")


@dag(schedule=[FACT_SALES], start_date=pendulum.datetime(2026, 3, 1, tz="America/Sao_Paulo"))
def sales_report():
    BashOperator(task_id="report", bash_command=(
        "psql -d wh -Atc \"SELECT max(order_date), sum(line_cents) FROM marts.fact_sales\""))


sales_report()
PY
code report-py dags/sales_report.py
block outlet
on "sed -i 's|^from airflow.sdk import dag, task|from airflow.sdk import Asset, dag, task|' dags/shop_nightly.py"
on "sed -i 's|-f load/fact_sales.sql\",|-f load/fact_sales.sql\",\n                              outlets=[Asset(\"postgres://localhost:5432/wh/marts/fact_sales\")],|' dags/shop_nightly.py"
on 'grep -n -A3 "fact_sales = " dags/shop_nightly.py'
block assets
on 'airflow dags reserialize >/dev/null 2>&1; airflow dags unpause sales_report; airflow assets list'
root 'day 2026-03-09'
on 'airflow backfill create --dag-id shop_nightly --from-date 2026-03-10 --to-date 2026-03-10T12:00:00-03:00 2>&1 | grep -c "Created backfill Dag run"'
for i in $(seq 60); do lab exec 'airflow dags list-runs sales_report -o plain 2>/dev/null' | grep -q "success\|failed" && break; sleep 5; done
on 'airflow dags list-runs sales_report -o plain | cut -c1-118'
on 'f=$(ls -d ~/airflow/logs/dag_id=sales_report/run_id=*/task_id=report | head -1); grep -oE "\"event\":\"[0-9-]+\|[0-9]+\"" $f/attempt=1.log'

put dags/shop_minute.py <<'PY'
"""The lab's fast clock: every minute, one more day of March, loaded.

Not a pipeline anybody would run. It exists because a nightly schedule needs a
night to pass, and here a minute has to do."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag

ETL = "/home/ana/etl"
PSQL = "psql -q -v ON_ERROR_STOP=1 -d wh"


@dag(schedule="* * * * *", start_date=pendulum.datetime(2026, 3, 1, tz="America/Sao_Paulo"),
     catchup=False, max_active_runs=1)
def shop_minute():
    play = BashOperator(task_id="play_a_day",
                        bash_command="bash ~/lab/lab.sh until $(date -d \"$(cat /var/lib/etl-run/clock) + 1 day\" +%F) && cat /var/lib/etl-run/clock")
    load = BashOperator(task_id="nightly",
                        bash_command="sh nightly.sh {{ ti.xcom_pull(task_ids='play_a_day') }} ",
                        cwd=ETL)
    play >> load


shop_minute()
PY
code minute-py dags/shop_minute.py
block minute
on 'cat /var/lib/etl-run/clock; airflow dags reserialize >/dev/null 2>&1; airflow dags unpause shop_minute'
sleep 200
on 'airflow dags pause shop_minute; cat /var/lib/etl-run/clock'
on 'airflow dags list-runs shop_minute -o plain | cut -c1-118'
on 'psql -d wh -c "SELECT order_date, count(*) FROM marts.fact_sales WHERE order_date > '"'"'2026-03-08'"'"' GROUP BY 1 ORDER BY 1"'
