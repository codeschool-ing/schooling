#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of aws-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE PROGRAMS ARE THE LESSONS': the table is created by the first ```sh fence
# of lesson 9's the-key.md and loaded by lesson 9's seed.py, read out of
# single-table.md; pages.py is the schooling-example of this lesson's
# the-scan.md, and each index is the ```sh fence of the section that builds it.
# moto is empty when this starts.
#
# STAGED: nothing beyond what lab.sh stages for every lesson. seed.py with
# 4000 customers takes about twenty seconds against moto, and its output is
# the same on every run, because its random numbers are seeded.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1
L="$HERE"
L9="$LESSONS/le-4edkwgs2"
DAY="'{\":d\": {\"S\": \"2026-10-01\"}}'"

# ---- the-scan ------------------------------------------------------------------
bash -e <(fence "$L9/the-key.md" 1) || exit 1
example "$L9/single-table.md" seed.py seed.py
example "$L/the-scan.md" pages.py pages.py
block scan-load
run 'python3 seed.py 4000'
run 'aws dynamodb describe-table --table-name quitanda --query "Table.[ItemCount,TableSizeBytes]" --output text'
run "aws dynamodb scan --table-name quitanda --filter-expression 'order_day = :d' --expression-attribute-values $DAY --select COUNT --query '[Count,ScannedCount]' --output text"
block scan-pages
run 'python3 pages.py'
run 'python3 pages.py 2026-10-01'
block scan-price
run 'python3 prices.py dynamodb'

# ---- gsi -------------------------------------------------------------------------
bash -e <(fence "$L/gsi.md" 1) || exit 1
block gsi-describe
run 'aws dynamodb describe-table --table-name quitanda --query "Table.GlobalSecondaryIndexes[].[IndexName,IndexStatus,Projection.ProjectionType,Projection.NonKeyAttributes[0]]" --output text'
block gsi-query
run 'python3 pages.py 2026-10-01 by-day'
run "aws dynamodb query --table-name quitanda --index-name by-day --key-condition-expression 'order_day = :d' --expression-attribute-values $DAY --max-items 2 --query 'Items[]' --output json"
run "aws dynamodb query --table-name quitanda --index-name by-day --key-condition-expression 'order_day = :d' --expression-attribute-values $DAY --consistent-read --select COUNT"

# ---- sparse ----------------------------------------------------------------------
bash -e <(fence "$L/sparse.md" 1) || exit 1
block sparse-count
run "aws dynamodb scan --table-name quitanda --index-name pending --select COUNT --query '[Count,ScannedCount]' --output text"
run "aws dynamodb scan --table-name quitanda --filter-expression 'attribute_exists(pending_since)' --select COUNT --query '[Count,ScannedCount]' --output text"
FIRST=$(aws dynamodb scan --table-name quitanda --index-name pending --max-items 1 --query 'Items[0].[pk.S,sk.S]' --output text | head -1)
PK=$(cut -f1 <<<"$FIRST"); SK=$(cut -f2 <<<"$FIRST")
block sparse-deliver
run "aws dynamodb update-item --table-name quitanda --key '{\"pk\": {\"S\": \"$PK\"}, \"sk\": {\"S\": \"$SK\"}}' --update-expression 'REMOVE pending_since SET delivered_at = :t' --condition-expression 'attribute_exists(pending_since)' --expression-attribute-values '{\":t\": {\"S\": \"2026-10-14T19:05\"}}'"
run "aws dynamodb scan --table-name quitanda --index-name pending --select COUNT --query Count"

# ---- pages -----------------------------------------------------------------------
C17="'{\":p\": {\"S\": \"CUSTOMER#c-17\"}}'"
block pages-limit
run "aws dynamodb query --table-name quitanda --key-condition-expression 'pk = :p' --expression-attribute-values $C17 --limit 5 --no-paginate --query '[Items[].sk.S,LastEvaluatedKey]'"
run "aws dynamodb query --table-name quitanda --key-condition-expression 'pk = :p' --expression-attribute-values $C17 --limit 5 --no-paginate --exclusive-start-key '{\"pk\": {\"S\": \"CUSTOMER#c-17\"}, \"sk\": {\"S\": \"ORDER#2026-10-05#o-10002\"}}' --query '[Items[].sk.S,LastEvaluatedKey]'"
block pages-trap
run "aws dynamodb scan --table-name quitanda --filter-expression 'order_day = :d' --expression-attribute-values $DAY --limit 100 --no-paginate --query '[Count,ScannedCount]' --output text"

# ---- lsi -------------------------------------------------------------------------
bash -e <(fence "$L/lsi.md" 1) || exit 1
block lsi-query
run 'python3 seed.py'
run "aws dynamodb query --table-name quitanda --index-name by-total --key-condition-expression 'pk = :p' --expression-attribute-values $C17 --no-scan-index-forward --query 'Items[].[total_cents.N,sk.S]' --output text"
run "aws dynamodb query --table-name quitanda --index-name by-total --key-condition-expression 'pk = :p' --expression-attribute-values $C17 --no-scan-index-forward --limit 1 --consistent-read --query 'Items[0].[order_id.S,total_cents.N]' --output text"
