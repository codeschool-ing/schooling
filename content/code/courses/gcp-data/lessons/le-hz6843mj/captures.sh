#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of gcp-data (external tables and
# BigLake), as a script that produces them. Every transcript in the lesson was
# copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# BIGQUERY IS NOT RUN, and neither is BigLake: no external table, connection,
# metadata cache, object table or Iceberg table exists here, and the lesson
# shows their DDL as statements nobody ran. What runs is fake-gcs-server,
# started as the student starts it in the other terminal, holding lesson 13's
# Parquet files, and external.py (read out of reading-back.md), which reads
# them back through the google-cloud-storage client with ranged requests, as
# a reader of an external table does, and queries them with DuckDB.
#
# STAGED: lesson 13's data set, rebuilt first with lesson 13's own
# make_orders.py, out of sight; the bucket and the upload are the lesson's own
# commands, shown.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
L="$LESSONS/le-hz6843mj"
L13="$LESSONS/le-bz7j5spr"

example "$L13/the-orders.md" make_orders.py make_orders.py || exit 1
python3 make_orders.py > /dev/null || exit 1
emu_start gcs || exit 1

block upload
run 'gcloud storage buckets create gs://quitanda-curated-prod --location=southamerica-east1'
run 'gcloud storage cp --recursive warehouse/orders gs://quitanda-curated-prod/ 2>&1 | tail -1'
run "gcloud storage ls -l 'gs://quitanda-curated-prod/orders/dt=2026-09-2*/*' | tail -4"

example "$L/reading-back.md" external.py external.py || exit 1
block read
run 'python3 external.py 2026-09-01 2026-09-29 district,total_cents'
run 'python3 external.py 2026-09-29 2026-09-29 order_id,customer_id,store_id,district,items,total_cents,payment,created_at'
run 'python3 external.py 2026-08-01 2026-09-29 district,total_cents'
block ops
run "python3 -c 'q = 87 / 1000 * 0.0004 + 1 / 1000 * 0.005; print(round(1000 * q, 4), round(720 * q, 4))'"
run "python3 -c 'print(round(1024 / 3 * 0.035, 2), round(1024 / 3 * 0.035 * 12, 2))'"
