#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of gcp-data (BigQuery: storage and
# compute), as a script that produces them. Every transcript in the lesson was
# copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# BIGQUERY ITSELF IS NOT RUN ANYWHERE IN THIS LESSON: there is no emulator for
# it. `bq` has nowhere to go and says so. What runs is DuckDB 1.5.6 over the
# Parquet files the lesson's own generator writes, and the files are uploaded
# to fake-gcs-server, started as the student starts it in the other terminal.
# The programs (make_orders.py, ask.py, logical.sql, storage.py) are read out of
# the lesson's .md files, so the code shown is the code that ran.
#
# STAGED: nothing.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
L="$LESSONS/le-bz7j5spr"

emu_start gcs || exit 1

block versions
run "python3 -c \"import duckdb, pyarrow; print('duckdb', duckdb.__version__, '/ pyarrow', pyarrow.__version__)\""
run "bq query --dry_run --use_legacy_sql=false 'SELECT 1' 2>&1 | head -2"

example "$L/the-orders.md" make_orders.py make_orders.py || exit 1
file_fence "$L/the-orders.md" ask.py > ask.py || exit 1
block generate
run 'time python3 make_orders.py'
run 'ls warehouse/orders | head -3; ls warehouse/orders | wc -l'
run 'du -sh warehouse/orders'

block upload
run 'gcloud storage buckets create gs://quitanda-curated-prod --location=southamerica-east1'
run 'gcloud storage cp --recursive warehouse/orders gs://quitanda-curated-prod/ 2>&1 | tail -1'
run 'gcloud storage ls gs://quitanda-curated-prod/orders/ | head -3'
run 'gcloud storage ls gs://quitanda-curated-prod/orders/** | wc -l'
run 'gcloud storage du --summarize gs://quitanda-curated-prod/orders/'

block ask
run 'python3 ask.py "SELECT count(*) AS orders, min(dt) AS first_day, max(dt) AS last_day FROM orders"'
run 'python3 ask.py "SELECT column_name, column_type FROM (DESCRIBE orders)"'
run 'python3 ask.py "SELECT order_id, customer_id, store_id, total_cents, created_at, dt FROM orders LIMIT 3"'

block strings
run 'python3 ask.py "SELECT DISTINCT district, length(district) AS characters, strlen(district) AS utf8_bytes, 2 + strlen(district) AS bigquery_bytes FROM orders ORDER BY district"'

file_fence "$L/logical-bytes.md" logical.sql > logical.sql || exit 1
block logical
run 'python3 ask.py logical.sql'
run 'du -cb warehouse/orders/*/*.parquet | tail -1'

file_fence "$L/storage-bill.md" storage.py > storage.py || exit 1
block storage
run 'python3 storage.py 1024 3 0'
run 'python3 storage.py 1024 3 0.9'
run 'python3 storage.py 1024 3 0.9 20'
