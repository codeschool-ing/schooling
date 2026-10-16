#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of aws-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE PROGRAMS ARE THE LESSON'S: the table is created by the first ```sh fence
# of the-key.md, profile.json is the fence that file introduces, and seed.py is
# the schooling-example of single-table.md, all read out of the lesson as they
# stand. moto is empty when this starts, as it is for a student who has just
# started it in the other terminal.
#
# STAGED: nothing beyond what lab.sh stages for every lesson.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1
L="$HERE"

# ---- the-key -----------------------------------------------------------------
bash -e <(fence "$L/the-key.md" 1) || exit 1
block key-table
run 'aws dynamodb describe-table --table-name quitanda --query "Table.[TableStatus,KeySchema,AttributeDefinitions]" --output text'
run 'aws dynamodb create-table --table-name orders-test --attribute-definitions AttributeName=pk,AttributeType=S AttributeName=total_cents,AttributeType=N --key-schema AttributeName=pk,KeyType=HASH --billing-mode PAY_PER_REQUEST'
file_fence "$L/the-key.md" profile.json > profile.json
block key-put
run 'aws dynamodb put-item --table-name quitanda --item file://profile.json'
run "aws dynamodb get-item --table-name quitanda --key '{\"pk\": {\"S\": \"CUSTOMER#c-17\"}, \"sk\": {\"S\": \"PROFILE\"}}'"
run "aws dynamodb get-item --table-name quitanda --key '{\"pk\": {\"S\": \"CUSTOMER#c-17\"}}'"

# ---- single-table ----------------------------------------------------------------
example "$L/single-table.md" seed.py seed.py
block seed-run
run 'python3 seed.py'
run "aws dynamodb scan --table-name quitanda --query 'Items[].[pk.S,sk.S]' --output text"

# ---- three-reads ---------------------------------------------------------------
block reads-query
run "aws dynamodb query --table-name quitanda --key-condition-expression 'pk = :p AND begins_with(sk, :o)' --expression-attribute-values '{\":p\": {\"S\": \"CUSTOMER#c-17\"}, \":o\": {\"S\": \"ORDER#2026-10-05#o-10002\"}}' --query 'Items[].[sk.S,total_cents.N,product.S,qty.N]' --output text"
run "aws dynamodb query --table-name quitanda --key-condition-expression 'pk = :p AND sk BETWEEN :a AND :b' --expression-attribute-values '{\":p\": {\"S\": \"CUSTOMER#c-17\"}, \":a\": {\"S\": \"ORDER#2026-10-01\"}, \":b\": {\"S\": \"ORDER#2026-10-08\"}}' --query '[Count,ScannedCount]' --output text"
block reads-refused
run "aws dynamodb query --table-name quitanda --key-condition-expression 'sk = :s' --expression-attribute-values '{\":s\": {\"S\": \"PROFILE\"}}'"
run "aws dynamodb query --table-name quitanda --key-condition-expression 'begins_with(pk, :p)' --expression-attribute-values '{\":p\": {\"S\": \"CUSTOMER#\"}}'"
block reads-latest
run "aws dynamodb query --table-name quitanda --key-condition-expression 'pk = :p AND begins_with(sk, :o)' --expression-attribute-values '{\":p\": {\"S\": \"CUSTOMER#c-17\"}, \":o\": {\"S\": \"ORDER#\"}}' --no-scan-index-forward --limit 1 --query 'Items[].[sk.S,product.S]' --output text"
block reads-scan
run "aws dynamodb scan --table-name quitanda --filter-expression 'name = :n' --expression-attribute-values '{\":n\": {\"S\": \"Gabi\"}}'"
run "aws dynamodb scan --table-name quitanda --filter-expression '#n = :n' --expression-attribute-names '{\"#n\": \"name\"}' --expression-attribute-values '{\":n\": {\"S\": \"Gabi\"}}' --query '[Count,ScannedCount,Items[0].pk.S]' --output text"

# ---- conditional-writes ----------------------------------------------------------
block cond-overwrite
run "aws dynamodb get-item --table-name quitanda --key '{\"pk\": {\"S\": \"CUSTOMER#c-17\"}, \"sk\": {\"S\": \"PROFILE\"}}' --query 'Item.[name.S,district.S,customer_id.S]' --output text"
block cond-insert
run "aws dynamodb put-item --table-name quitanda --item file://profile.json --condition-expression 'attribute_not_exists(pk)' --return-values-on-condition-check-failure ALL_OLD"
run "aws dynamodb put-item --table-name quitanda --item '{\"pk\": {\"S\": \"CUSTOMER#c-99\"}, \"sk\": {\"S\": \"PROFILE\"}, \"name\": {\"S\": \"Ana\"}}' --condition-expression 'attribute_not_exists(pk)'"
run "aws dynamodb put-item --table-name quitanda --item '{\"pk\": {\"S\": \"CUSTOMER#c-99\"}, \"sk\": {\"S\": \"PROFILE\"}, \"name\": {\"S\": \"Ana\"}}' --condition-expression 'attribute_not_exists(pk)'"
block cond-deliver
run "aws dynamodb update-item --table-name quitanda --key '{\"pk\": {\"S\": \"CUSTOMER#c-19\"}, \"sk\": {\"S\": \"ORDER#2026-10-14#o-10009\"}}' --update-expression 'REMOVE pending_since SET delivered_at = :t' --condition-expression 'attribute_exists(pending_since)' --expression-attribute-values '{\":t\": {\"S\": \"2026-10-14T18:20\"}}' --return-values ALL_NEW --query 'Attributes.[order_id.S,pending_since.S,delivered_at.S]' --output text"
run "aws dynamodb update-item --table-name quitanda --key '{\"pk\": {\"S\": \"CUSTOMER#c-19\"}, \"sk\": {\"S\": \"ORDER#2026-10-14#o-10009\"}}' --update-expression 'REMOVE pending_since SET delivered_at = :t' --condition-expression 'attribute_exists(pending_since)' --expression-attribute-values '{\":t\": {\"S\": \"2026-10-14T18:45\"}}' --return-values ALL_NEW"
