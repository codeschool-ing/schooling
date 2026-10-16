#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of aws-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", with moto empty. The programs are read out of the lesson: lake.py
# from "the-lake", ask.py from "asking", footer.py and orders.sql from the
# fences that introduce them, so the copies run here are the ones printed.
#
# ATHENA IS NOT RUN, because moto runs no SQL. The questions are answered by
# ask.py, which uses DuckDB in-process over the objects moto stores; the
# Athena commands below show what moto records and that it enforces nothing.
#
# STAGED: nothing beyond lesson 1's lab. prices.py and its cache are there
# because lab.sh wrote them out of lesson 1.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1
example "$HERE/the-lake.md" lake.py lake.py || exit 1
example "$HERE/asking.md" ask.py ask.py || exit 1
file_fence "$HERE/three-reads.md" footer.py > footer.py || exit 1
file_fence "$HERE/in-place.md" orders.sql > orders.sql || exit 1

block price-athena
run 'python3 prices.py athena'

block ddl-moto
run 'aws s3 mb s3://quitanda-athena-results-prod'
run 'aws athena start-query-execution --query-string file://orders.sql --result-configuration OutputLocation=s3://quitanda-athena-results-prod/'
QID=$(aws athena list-query-executions --query 'QueryExecutionIds[0]' --output text)
run "aws athena get-query-execution --query-execution-id $QID --query 'QueryExecution.[StatementType,Status.State]' --output text"
run 'aws glue get-databases'

block lake-run
run 'aws s3 mb s3://quitanda-raw-prod && aws s3 mb s3://quitanda-curated-prod'
run 'python3 lake.py'

block lake-list
run 'aws s3 ls s3://quitanda-curated-prod/orders/ | head -3'
run 'aws s3 ls s3://quitanda-curated-prod/orders/dt=2026-10-01/'
run 'aws s3 ls s3://quitanda-raw-prod/raw/orders/dt=2026-10-01/'
run 'aws s3 cp s3://quitanda-raw-prod/raw/orders/dt=2026-10-01/orders.csv day.csv && head -4 day.csv'

block ask-csv
run 'python3 ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders_csv GROUP BY payment ORDER BY reais DESC"'

block ask-typo
run 'python3 ask.py "SELECT sum(total) FROM orders"'

block ask-parquet
run 'python3 ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC"'

block ask-day
run "python3 ask.py \"SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders WHERE dt = '2026-10-15' GROUP BY payment ORDER BY reais DESC\""

block ask-day-csv
run "python3 ask.py \"SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders_csv WHERE dt = '2026-10-15' GROUP BY payment ORDER BY reais DESC\""

block ask-hour
run 'python3 ask.py "SELECT hour, count(*) AS orders FROM orders WHERE hour >= 21 GROUP BY hour ORDER BY hour"'

block footer
run 'python3 footer.py s3://quitanda-curated-prod/orders/dt=2026-10-15/orders.parquet'

block workgroup
run "aws athena create-work-group --name analysts --configuration 'ResultConfiguration={OutputLocation=s3://quitanda-athena-results-prod/analysts/},EnforceWorkGroupConfiguration=true,BytesScannedCutoffPerQuery=10485760'"
run "aws athena get-work-group --work-group analysts --query 'WorkGroup.Configuration.[BytesScannedCutoffPerQuery,EnforceWorkGroupConfiguration]' --output text"
run 'aws athena start-query-execution --work-group analysts --query-string "SELECT * FROM quitanda.orders_csv"'
QID=$(aws athena list-query-executions --work-group analysts --query 'QueryExecutionIds[0]' --output text)
run "aws athena get-query-execution --query-execution-id $QID --query 'QueryExecution.[WorkGroup,Status.State,Statistics.DataScannedInBytes]' --output text"
