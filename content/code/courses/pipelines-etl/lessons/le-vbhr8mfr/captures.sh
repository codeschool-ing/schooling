#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of pipelines-etl, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: `lab.sh reset` and the first fourteen
# days of March before the first block; Ana's project from lessons 6 to 9,
# copied into ~/etl from ../../lab/project, with what lessons 11 and 12 added
# to it copied over it from ../../lab/after-11 and ../../lab/after-12; raw
# loaded and the dbt project built once with `dbt build --full-refresh`. The
# files are written by `put` and shown in the lesson. Airflow is not started:
# this lesson is about the three tools that are not Airflow.
#
# Each tool lives in its own virtual environment under /opt/etl, as the lab's
# header explains; luigi and dagster are on PATH as commands, and a Prefect
# flow is a Python script run with Prefect's own interpreter.
#
# Clock times, run ids, process ids and durations are the recording's own.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, Luigi 3.8.1,
# Prefect 3.8.8, Dagster 1.13.25, dbt-core 1.12.5, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "$0")/../../capture.sh"
P=$(cd "$(dirname "$0")/../../lab/project" && pwd)
A=$(cd "$(dirname "$0")/../../lab/after-11" && pwd)
B=$(cd "$(dirname "$0")/../../lab/after-12" && pwd)
lab reset >/dev/null
lab until 2026-03-14 >/dev/null
for f in $(cd "$P" && find . -type f ! -name README | sed 's|^\./||'); do put "$f" < "$P/$f"; done
for f in $(cd "$A" && find load_raw.py shop -type f); do put "$f" < "$A/$f"; done
for f in $(cd "$B" && find shop -type f); do put "$f" < "$B/$f"; done
lab exec 'rm -rf ~/.dbt ~/.prefect ~/dagster; mkdir -p ~/.dbt && cat > ~/.dbt/profiles.yml' < "$A/profiles.yml"
lab exec 'touch landing/prices.jsonl; python load_raw.py >/dev/null; cd shop && dbt build --full-refresh >/dev/null'
lab exec 'mkdir -p reports'

put nightly_luigi.py <<'PY'
"""The nightly load as three Luigi tasks. A task is done when its output exists."""
import subprocess

import luigi


class LoadRaw(luigi.Task):
    day = luigi.DateParameter()

    def output(self):
        return luigi.LocalTarget(f"marks/raw_{self.day}.done")

    def run(self):
        subprocess.run(["python", "load_raw.py"], check=True)
        with self.output().open("w") as mark:
            mark.write("loaded\n")


class BuildModels(luigi.Task):
    day = luigi.DateParameter()

    def requires(self):
        return LoadRaw(self.day)

    def output(self):
        return luigi.LocalTarget(f"marks/models_{self.day}.done")

    def run(self):
        subprocess.run(["dbt", "build", "--project-dir", "shop", "--quiet"], check=True)
        with self.output().open("w") as mark:
            mark.write("built\n")


class DailyReport(luigi.Task):
    day = luigi.DateParameter()

    def requires(self):
        return BuildModels(self.day)

    def output(self):
        return luigi.LocalTarget(f"reports/daily_{self.day}.csv")

    def run(self):
        query = ("COPY (SELECT shop_id, category, books, revenue_cents FROM dbt_marts.daily_sales "
                 f"WHERE order_date = '{self.day}' ORDER BY 1, 2) TO STDOUT WITH (FORMAT csv, HEADER)")
        csv = subprocess.run(["psql", "-d", "wh", "-c", query], check=True,
                             capture_output=True, text=True).stdout
        with self.output().open("w") as out:      # written to a temporary file, renamed at the end
            out.write(csv)
PY
put nightly_prefect.py <<'PY'
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
PY
put nightly_dagster.py <<'PY'
"""The nightly load as three Dagster assets: what should exist, and what it is made from."""
import subprocess

import dagster as dg


class Day(dg.Config):
    day: str


@dg.asset
def raw_tables():
    """The shop's tables, copied into raw by load_raw.py."""
    subprocess.run(["python", "load_raw.py"], check=True)


@dg.asset(deps=[raw_tables])
def dbt_models():
    """Every model of the dbt project, built and tested."""
    subprocess.run(["dbt", "build", "--project-dir", "shop", "--quiet"], check=True)


@dg.asset(deps=[dbt_models])
def daily_report(config: Day) -> dg.MaterializeResult:
    """One day of daily_sales as a CSV file, for the managers."""
    query = ("COPY (SELECT shop_id, category, books, revenue_cents FROM dbt_marts.daily_sales "
             f"WHERE order_date = '{config.day}' ORDER BY 1, 2) TO STDOUT WITH (FORMAT csv, HEADER)")
    csv = subprocess.run(["psql", "-d", "wh", "-c", query], check=True,
                         capture_output=True, text=True).stdout
    path = f"reports/daily_{config.day}.csv"
    with open(path, "w") as out:
        out.write(csv)
    return dg.MaterializeResult(metadata={"path": path, "rows": csv.count("\n") - 1})


defs = dg.Definitions(assets=[raw_tables, dbt_models, daily_report])
PY
code luigi-py nightly_luigi.py
code prefect-py nightly_prefect.py
code dagster-py nightly_dagster.py

block luigi-run
on 'PYTHONPATH=. luigi --module nightly_luigi DailyReport --day 2026-03-14 --local-scheduler 2>&1 | sed -n "/Execution Summary/,/Execution Summary/p"'
on 'ls marks reports'
on 'head -4 reports/daily_2026-03-14.csv'
block luigi-again
on 'PYTHONPATH=. luigi --module nightly_luigi DailyReport --day 2026-03-14 --local-scheduler 2>&1 | sed -n "/Execution Summary/,/Execution Summary/p"'
block luigi-fail
root 'day 2026-03-15'
on 'PYTHONPATH=. luigi --module nightly_luigi DailyReport --day 2026-03-15 --local-scheduler 2>&1 | sed -n "/Execution Summary/,/Execution Summary/p"'
on 'ls marks'
block why
on 'dbt build --project-dir shop 2>&1 | grep -E "FAIL|Done"'
on 'dbt build --project-dir shop -s fact_sales+ --full-refresh 2>&1 | grep -E "Done"'
block luigi-resume
on 'PYTHONPATH=. luigi --module nightly_luigi DailyReport --day 2026-03-15 --local-scheduler 2>&1 | sed -n "/Execution Summary/,/Execution Summary/p"'

block prefect-run
on 'prefect config set PREFECT_SERVER_ANALYTICS_ENABLED=false'
on '/opt/etl/prefect/bin/python nightly_prefect.py 2026-03-15'
block prefect-again
on '/opt/etl/prefect/bin/python nightly_prefect.py 2026-03-15 2>&1 | grep -E "Task run|Flow run"'

block dagster-run
on 'mkdir -p ~/dagster && printf "telemetry:\n  enabled: false\n" > ~/dagster/dagster.yaml'
on 'export DAGSTER_HOME=~/dagster; dagster asset materialize -m nightly_dagster --select "*" --config-json "{\"ops\": {\"daily_report\": {\"config\": {\"day\": \"2026-03-15\"}}}}" 2>&1 | grep -oE "(STEP_SUCCESS|STEP_FAILURE|RUN_SUCCESS|RUN_FAILURE) - .*"'
put latest.py <<'PY'
"""What Dagster remembers: the last time each asset was materialized, and what it said."""
import datetime as dt

import dagster as dg

instance = dg.DagsterInstance.get()
for name in ["raw_tables", "dbt_models", "daily_report"]:
    event = instance.get_latest_materialization_event(dg.AssetKey(name))
    when = dt.datetime.fromtimestamp(event.timestamp).strftime("%H:%M:%S")
    meta = event.asset_materialization.metadata
    print(f"{name:<13}{when}  " + "  ".join(f"{k}={v.value}" for k, v in meta.items()))
PY
code latest-py latest.py
on 'DAGSTER_HOME=~/dagster /opt/etl/dagster/bin/python latest.py'
