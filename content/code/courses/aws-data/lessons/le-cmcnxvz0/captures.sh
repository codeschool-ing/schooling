#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of aws-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", with moto empty. lake.py and ask.py are read out of lesson 15,
# where they are shown; orders-table.json, partitions.py, coupons.py and
# reais.py out of the fences of this lesson that introduce them.
#
# moto keeps the Data Catalog faithfully: databases, tables, partitions,
# partition expressions and table versions are real data structures there.
# A crawler is not: it changes state and reads nothing, and the prose says so.
# The Parquet files of "evolution" are read by PyArrow and DuckDB for real.
#
# STAGED: nothing beyond lesson 1's lab and the two programs of lesson 15,
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
file_fence "$HERE/catalog.md" orders-table.json > orders-table.json || exit 1
file_fence "$HERE/partitions.md" partitions.py > partitions.py || exit 1
file_fence "$HERE/evolution.md" coupons.py > coupons.py || exit 1
file_fence "$HERE/evolution.md" reais.py > reais.py || exit 1

block catalog-db
run "aws glue create-database --database-input '{\"Name\": \"quitanda\", \"Description\": \"Quitanda lake, curated layer\"}'"
run 'aws glue get-databases'

block catalog-table
run 'aws glue create-table --database-name quitanda --table-input file://orders-table.json'
run "aws glue get-table --database-name quitanda --name orders --query 'Table.[Name,TableType,VersionId,StorageDescriptor.Location,length(StorageDescriptor.Columns),PartitionKeys[0].Name]' --output text"
run 'aws glue get-table --database-name quitanda --name nope'

block lake-curated
run 'aws s3 mb s3://quitanda-raw-prod && aws s3 mb s3://quitanda-curated-prod'
run 'python3 lake.py'

block parts-create
run 'python3 partitions.py > partitions.json && jq length partitions.json'
run 'aws glue batch-create-partition --database-name quitanda --table-name orders --partition-input-list file://partitions.json'
run "aws glue get-partitions --database-name quitanda --table-name orders --query 'length(Partitions)'"

block parts-expr
run "aws glue get-partitions --database-name quitanda --table-name orders --expression \"dt BETWEEN '2026-10-10' AND '2026-10-12'\" --query 'Partitions[].[Values[0],StorageDescriptor.Location]' --output text"

run "aws glue get-partitions --database-name quitanda --table-name orders --expression \"payment = 'pix'\""

block parts-again
run "aws glue batch-create-partition --database-name quitanda --table-name orders --partition-input-list file://partitions.json --query 'length(Errors)'; echo \"exit \$?\""
run "aws glue batch-create-partition --database-name quitanda --table-name orders --partition-input-list file://partitions.json --query 'Errors[0]'"

block parts-nothing
run "aws glue create-partition --database-name quitanda --table-name orders --partition-input '{\"Values\": [\"2026-12-25\"], \"StorageDescriptor\": {\"Location\": \"s3://quitanda-curated-prod/orders/dt=2026-12-25/\"}}'"
run "aws glue get-partitions --database-name quitanda --table-name orders --expression \"dt > '2026-10-31'\" --query 'Partitions[].Values[0]' --output text"
run 'aws s3 ls s3://quitanda-curated-prod/orders/dt=2026-12-25/; echo "exit $?"'
run "aws glue delete-partition --database-name quitanda --table-name orders --partition-values 2026-12-25"

block price-glue
run 'python3 prices.py glue'

block crawler-create
run "aws glue create-crawler --name orders-crawler --role arn:aws:iam::123456789012:role/quitanda-glue-crawler --database-name quitanda --targets 'S3Targets=[{Path=s3://quitanda-curated-prod/orders/,SampleSize=5}]' --schema-change-policy UpdateBehavior=LOG,DeleteBehavior=LOG --recrawl-policy RecrawlBehavior=CRAWL_NEW_FOLDERS_ONLY --schedule 'cron(30 3 * * ? *)'"
run "aws glue get-crawler --name orders-crawler --query 'Crawler.[State,Schedule.State,SchemaChangePolicy.UpdateBehavior,RecrawlPolicy.RecrawlBehavior]' --output text"

block crawler-run
run 'aws glue start-crawler --name orders-crawler'
run "aws glue get-crawler --name orders-crawler --query 'Crawler.[State,LastCrawl.Status]' --output text"
run "sleep 10; aws glue get-crawler --name orders-crawler --query 'Crawler.[State,LastCrawl.Status]' --output text"
run "aws glue get-tables --database-name quitanda --query 'TableList[].Name' --output text"
run 'aws glue stop-crawler --name orders-crawler'
run "sleep 10; aws glue get-crawler --name orders-crawler --query 'Crawler.[State,LastCrawl.Status]' --output text"

block versions-add
run "jq '.StorageDescriptor.Columns += [{\"Name\": \"coupon\", \"Type\": \"string\"}]' orders-table.json > orders-table-2.json"
run 'aws glue update-table --database-name quitanda --table-input file://orders-table-2.json'
run "jq '(.StorageDescriptor.Columns[] | select(.Name == \"total_cents\") | .Type) = \"double\"' orders-table-2.json > orders-table-3.json"
run 'aws glue update-table --database-name quitanda --table-input file://orders-table-3.json'
run "aws glue get-table-versions --database-name quitanda --table-name orders --query 'TableVersions[].[VersionId,length(Table.StorageDescriptor.Columns),Table.StorageDescriptor.Columns[4].Type]' --output text"

block versions-partition
run "aws glue get-partition --database-name quitanda --table-name orders --partition-values 2026-10-15 --query 'Partition.StorageDescriptor.Columns[-1].Name' --output text"
run "aws glue get-table --database-name quitanda --name orders --query 'Table.StorageDescriptor.Columns[-1].Name' --output text"

block versions-skip
run 'aws glue update-table --database-name quitanda --table-input file://orders-table-2.json --skip-archive'
run "aws glue get-table-versions --database-name quitanda --table-name orders --query 'TableVersions[].VersionId' --output text"

block evo-coupons
run 'python3 coupons.py'
run "python3 ask.py \"SELECT dt, count(*) AS orders FROM orders WHERE dt >= '2026-10-30' GROUP BY dt ORDER BY dt\""
run "python3 ask.py \"SELECT count(coupon) FROM orders WHERE dt = '2026-11-01'\""

block evo-union
run 'aws s3 cp s3://quitanda-curated-prod/orders/dt=2026-10-31/orders.parquet oct31.parquet --only-show-errors'
run 'aws s3 cp s3://quitanda-curated-prod/orders/dt=2026-11-01/orders.parquet nov01.parquet --only-show-errors'
run "python3 -c \"import duckdb; duckdb.sql(\\\"SELECT count(*) AS orders, count(coupon) AS with_coupon FROM read_parquet(['oct31.parquet', 'nov01.parquet'], union_by_name = true)\\\").show()\""
run "python3 -c \"import duckdb; duckdb.sql(\\\"SELECT count(coupon) FROM read_parquet(['oct31.parquet', 'nov01.parquet'])\\\").show()\""

block evo-type
run 'python3 reais.py'
run "python3 ask.py \"SELECT dt, sum(total_cents) AS total FROM orders WHERE dt >= '2026-11-01' GROUP BY dt ORDER BY dt\""
run 'aws s3 rm s3://quitanda-curated-prod/orders/dt=2026-11-02/orders.parquet'
