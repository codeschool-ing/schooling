#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of gcp-data (Cloud Composer, and
# Workflows with Cloud Scheduler), as a script that produces them. Every
# transcript in the lesson was copied from its output.
#
#   sudo WHEELS=DIR bash ../../lab.sh run captures.sh
#
# THE LAB IS LESSON 1'S, and this script starts where a student is after "Every
# time you open a terminal", with no emulator running. There is no emulator and
# no control plane for Composer, Workflows or Cloud Scheduler, and the lesson
# marks every command that would need one as not run. What runs is Apache
# Airflow 3.3.2 itself, in a virtual environment of its own, with SQLite as its
# metadata database: the engine Composer manages, not the service.
#
# fake-gcs-server is started in the background with lesson 1's command, and so
# are `airflow api-server` and `airflow scheduler` in block catchup, which the
# student runs in terminals of their own.
#
# The files the student saves are read out of the lessons: quitanda_nightly.py
# and composer_bill.py from their examples here, two_clocks.py from the fence
# introduced by its name, and lesson 23's make_orders.py, daily_orders.py and
# check_daily.py from lesson 23, where the student saved them.
#
# STAGED: pip inside the run has no network, so both installs read WHEELS,
# filled beforehand with `pip download apache-airflow==3.3.2 -c
# constraints-3.12.txt` and lesson 23's pyspark 4.2.0 wheel. The constraints
# file the student fetches with curl is copied in from WHEELS, where it was
# saved from the same URL. pyspark is installed into the course's environment
# before the first block, as lesson 23 had the student do.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
L="$LESSONS/le-mrm2x8n1"
L23="$LESSONS/le-z7erg782"

emu_start gcs || exit 1
pip install -q pyspark==4.2.0 > /dev/null || exit 1
file_fence "$L23/a-job-locally.md" make_orders.py > make_orders.py || exit 1
file_fence "$L23/a-job-locally.md" check_daily.py > check_daily.py || exit 1
example "$L23/a-job-locally.md" daily_orders.py daily_orders.py || exit 1
gcloud storage buckets create gs://quitanda-curated-prod --location=southamerica-east1 > /dev/null 2>&1

# ---- airflow-on-your-laptop ----------------------------------------------------
block af-install
cp "${WHEELS:?}/constraints-3.12.txt" . || exit 1
fence "$L/airflow-on-your-laptop.md" 1 | grep -v '^curl ' > install.sh
while IFS= read -r line; do run "$line"; done < install.sh
eval "$(fence "$L/airflow-on-your-laptop.md" 2)"
run 'airflow version'

block af-init
run 'airflow db migrate 2>&1 | tail -1'
example "$L/airflow-parts.md" quitanda_nightly.py quitanda_nightly.py || exit 1
run 'mkdir -p $AIRFLOW_HOME/dags && cp quitanda_nightly.py $AIRFLOW_HOME/dags/'
run 'airflow dags reserialize > /dev/null 2>&1; airflow dags list -o plain 2>/dev/null | awk '\''{print $1, $4}'\'''

block af-render
run "airflow tasks render quitanda_nightly export_orders 2026-10-30T06:00:00+00:00 2>/dev/null | grep -A2 'property: bash_command'"

block af-test
run 'airflow dags test quitanda_nightly 2026-10-30T06:00:00+00:00 > test.log 2>&1; echo "exit $?"'
run "grep -o 'Running command: .*' test.log | cut -c1-110"
run "grep -oE '([0-9]+ orders read|│ +[0-9]).*' test.log | sed 's/ *\\[airflow.*//'"
run 'gcloud storage ls gs://quitanda-curated-prod/daily_orders/'
run 'airflow dags list-runs quitanda_nightly -o plain 2>/dev/null | cut -c1-120'

# ---- scheduling -------------------------------------------------------------------
file_fence "$L/scheduling.md" two_clocks.py > "$AIRFLOW_HOME/dags/two_clocks.py" || exit 1
block catchup
run 'airflow dags reserialize > /dev/null 2>&1; airflow dags unpause clock_trigger > /dev/null 2>&1; airflow dags unpause clock_interval > /dev/null 2>&1'
( airflow api-server > api.log 2>&1 & echo $! > api.pid )
for _ in $(seq 120); do (exec 3<>/dev/tcp/127.0.0.1/8090) 2>/dev/null && break; sleep 0.5; done
( timeout 60 airflow scheduler > scheduler.log 2>&1 )
kill "$(cat api.pid)" 2>/dev/null
run "airflow dags list-runs clock_trigger -o plain 2>/dev/null | awk '{print \$3, \$4}'"
run "airflow dags list-runs clock_interval -o plain 2>/dev/null | awk '{print \$3, \$4}'"
run "grep -rhoE '\"event\":\"clock_[a-z]+ ds=[^\"]*' \$AIRFLOW_HOME/logs | cut -d'\"' -f4 | sort"

block backfill
run 'airflow backfill create --dag-id clock_interval --from-date 2026-10-20 --to-date 2026-10-23 --dry-run 2>/dev/null | grep -A20 "Runs to be"'

block help-tz
run "gcloud scheduler jobs create http --help | grep -A1 -E -- '^ +--time-zone'"

# ---- the-idle-bill -----------------------------------------------------------------
example "$L/the-idle-bill.md" composer_bill.py composer_bill.py || exit 1
block bill
run 'python3 composer_bill.py'
