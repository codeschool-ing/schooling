#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of aws-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", with moto empty. lake.py and ask.py are read out of lesson 15,
# orders-table.json out of lesson 16, and orders_etl.py and etl.py out of this
# lesson, so the copies run here are the ones printed.
#
# GLUE IS NOT RUN, because moto runs no Spark: its job runs are SUCCEEDED with
# nothing executed, and the lesson shows exactly that. The transformation is
# executed for real by etl.py, with DuckDB and PyArrow, against moto's S3 and
# moto's Glue Data Catalog. orders_etl.py, the Glue script, is uploaded and
# named in a job definition and never runs anywhere.
#
# STAGED: nothing beyond lesson 1's lab and the files of lessons 15 and 16,
# which the student saved there.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1
example "$LESSONS/le-2vfrcj3x/the-lake.md" lake.py lake.py || exit 1
example "$LESSONS/le-2vfrcj3x/asking.md" ask.py ask.py || exit 1
file_fence "$LESSONS/le-cmcnxvz0/catalog.md" orders-table.json > orders-table.json || exit 1
example "$HERE/the-script.md" orders_etl.py orders_etl.py || exit 1
example "$HERE/run-it-here.md" etl.py etl.py || exit 1

block price-glue
run 'python3 prices.py glue'

block job-moto
run 'aws s3 mb s3://quitanda-glue-prod'
run 'aws s3 cp orders_etl.py s3://quitanda-glue-prod/scripts/orders_etl.py --only-show-errors'
run "aws glue create-job --name orders-etl --role arn:aws:iam::123456789012:role/quitanda-glue-etl --command Name=glueetl,ScriptLocation=s3://quitanda-glue-prod/scripts/orders_etl.py,PythonVersion=3 --glue-version 5.0 --worker-type G.1X --number-of-workers 10 --timeout 60 --default-arguments '{\"--job-bookmark-option\": \"job-bookmark-enable\"}'"
run 'aws glue start-job-run --job-name orders-etl'
RID=$(aws glue get-job-runs --job-name orders-etl --query 'JobRuns[0].Id' --output text)
run "aws glue get-job-run --job-name orders-etl --run-id $RID --query 'JobRun.[JobRunState,ExecutionTime,GlueVersion,WorkerType,NumberOfWorkers,DPUSeconds]' --output text"
run "aws glue get-job --job-name orders-etl --query 'Job.GlueVersion' --output text"

block etl-setup
run 'aws s3 mb s3://quitanda-raw-prod && aws s3 mb s3://quitanda-curated-prod'
run "aws glue create-database --database-input '{\"Name\": \"quitanda\"}' && aws glue create-table --database-name quitanda --table-input file://orders-table.json"
run 'python3 lake.py --layer raw'

block etl-first
run 'python3 etl.py'

block etl-check
run 'python3 ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC"'
run "aws glue get-partitions --database-name quitanda --table-name orders --query 'length(Partitions)'"

block etl-again
run 'python3 etl.py'

block resent
run 'aws s3 cp s3://quitanda-raw-prod/raw/orders/dt=2026-10-15/orders.csv day15.csv --only-show-errors && head -501 day15.csv > resent.csv'
run 'aws s3 cp resent.csv s3://quitanda-raw-prod/raw/orders/dt=2026-10-15/orders-resent.csv --only-show-errors'
run 'aws s3 ls s3://quitanda-raw-prod/raw/orders/dt=2026-10-15/'
run 'python3 etl.py'

block resent-check
run "python3 ask.py \"SELECT count(*) AS orders, count(DISTINCT order_id) AS ids FROM orders_csv WHERE dt = '2026-10-15'\""
run "python3 ask.py \"SELECT count(*) AS orders, count(DISTINCT order_id) AS ids FROM orders WHERE dt = '2026-10-15'\""

block bookmark-file
run 'aws s3 cp s3://quitanda-glue-prod/bookmarks/orders-etl.json bookmark.json --only-show-errors'
run "jq length bookmark.json && jq -r '.[] | select(contains(\"resent\"))' bookmark.json"

block bookmark-moto
run 'aws glue get-job-bookmark --job-name orders-etl'

block flex-shell
run "aws glue create-job --name orders-etl-flex --role arn:aws:iam::123456789012:role/quitanda-glue-etl --command Name=glueetl,ScriptLocation=s3://quitanda-glue-prod/scripts/orders_etl.py,PythonVersion=3 --glue-version 5.0 --worker-type G.1X --number-of-workers 10 --execution-class FLEX"
run "aws glue create-job --name orders-etl-small --role arn:aws:iam::123456789012:role/quitanda-glue-etl --command Name=pythonshell,ScriptLocation=s3://quitanda-glue-prod/scripts/etl.py,PythonVersion=3.9 --max-capacity 0.0625"
run "aws glue get-jobs --query 'Jobs[].[Name,Command.Name,ExecutionClass,WorkerType,NumberOfWorkers,MaxCapacity]' --output text"
