#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of gcp-data (Dataproc), as a script
# that produces them. Every transcript in the lesson was copied from its output.
#
#   sudo WHEELS=DIR bash ../../lab.sh run captures.sh
#
# THE LAB IS LESSON 1'S, and this script starts where a student is after "Every
# time you open a terminal", with no emulator running. There is no emulator and
# no control plane for Dataproc: no cluster, job or batch is created anywhere,
# and the lesson marks every `gcloud dataproc` command that would need one as
# not run. What runs is Apache Spark itself, PySpark 4.2.0 in local mode on
# Ubuntu's openjdk-21-jre-headless, which the first fence of lesson 1 installs.
# `gcloud dataproc ... --help` is read from the installed command line, which
# answers it with no network.
#
# fake-gcs-server is started in the background with lesson 1's command, as the
# student runs it in a terminal of its own.
#
# The programs the student saves are read out of the lesson: make_orders.py
# from the fence introduced by its name, daily_orders.py and
# dataproc_vs_dataflow.py from their examples.
#
# STAGED: pip inside the run has no network, so `pip install -q pyspark==4.2.0`
# installs from WHEELS, filled beforehand with `pip download pyspark==4.2.0`.
# PyPI publishes pyspark 4.2.0 as a source archive only, so that archive was
# built into a wheel with `pip wheel --no-deps` before the run; a student's pip
# does the same build itself, in about a minute.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
L="$LESSONS/le-z7erg782"

emu_start gcs || exit 1

# ---- the-cluster and secondary-workers: what the command line accepts --------
block help-secondary
run "gcloud dataproc clusters create --help | grep -A2 -- '--secondary-worker-type=TYPE; default'"
block help-delete
run "gcloud dataproc clusters create --help | grep -E -- '^ +--(delete|stop)-max-idle'"

# ---- a-job-locally: Spark on this laptop ---------------------------------------
block spark-install
run 'pip install -q pyspark==4.2.0'
run 'java -version 2>&1 | head -1'
run "spark-submit --version 2>&1 | grep -E 'version [0-9]|Using Scala'"

file_fence "$L/a-job-locally.md" make_orders.py > make_orders.py || exit 1
block orders
run 'python3 make_orders.py 2026-10-29'
run 'head -4 raw/orders/dt=2026-10-29/orders.csv'

example "$L/a-job-locally.md" daily_orders.py daily_orders.py || exit 1
block spark-run
run "time spark-submit --master 'local[2]' daily_orders.py --dt 2026-10-29 2> spark.log"
run 'ls -a curated/daily_orders/dt=2026-10-29/'
run 'grep -c . spark.log'

file_fence "$L/a-job-locally.md" check_daily.py > check_daily.py || exit 1
block duckdb-check
run 'python3 check_daily.py 2026-10-29'

block upload
run 'gcloud storage buckets create gs://quitanda-raw-prod gs://quitanda-curated-prod --location=southamerica-east1'
run 'gcloud storage cp raw/orders/dt=2026-10-29/orders.csv gs://quitanda-raw-prod/raw/orders/dt=2026-10-29/orders.csv'
run 'gcloud storage cp daily_orders.py gs://quitanda-raw-prod/jobs/daily_orders.py'
run 'gcloud storage cp curated/daily_orders/dt=2026-10-29/* gs://quitanda-curated-prod/daily_orders/dt=2026-10-29/'
run 'gcloud storage ls -r gs://quitanda-curated-prod/'

# ---- dataproc-or-dataflow: the program, read out of the lesson -----------------
example "$L/dataproc-or-dataflow.md" dataproc_vs_dataflow.py dataproc_vs_dataflow.py || exit 1
block price
run 'python3 dataproc_vs_dataflow.py'
