#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", with Azurite started and empty. orders.py, onelake.py and ask.py
# are read out of delta-in-a-container.md, and main.tf out of capacity.md, so
# there is no second copy here. Terraform creates nothing: `validate` reads the
# file and the provider's schema, offline.
#
# FABRIC IS NOT RUN, and nothing here imitates it: there is no emulator for any
# part of Fabric. The table is written by the open-source deltalake library into
# a container on Azurite, through the blob interface, and read back by
# deltalake and DuckDB. The names of the Parquet files are random and change on
# every run.
#
# STAGED: the emulators are started by `services` rather than by the
# `docker compose up -d` the student types.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services azurite || exit 1
file_fence "$HERE/delta-in-a-container.md" orders.py > orders.py || exit 1
example "$HERE/delta-in-a-container.md" onelake.py onelake.py || exit 1
file_fence "$HERE/delta-in-a-container.md" ask.py > ask.py || exit 1

block tf-fabric
mkdir -p ~/azure/tf/fabric && cd ~/azure/tf/fabric || exit 1
file_fence "$HERE/capacity.md" main.tf > main.tf
PROMPT_DIR='~/azure/tf/fabric'
run "terraform init -no-color | grep -E 'Installing|Installed|successfully'"
run 'terraform validate -no-color'
run "sed -i 's/\"F2\"/\"F3\"/' main.tf && terraform validate -no-color 2>&1 | grep Error"
run "sed -i 's/\"F3\"/\"F2\"/; s/fcquitandaprd/fc-quitanda-prd/' main.tf && terraform validate -no-color 2>&1 | grep Error"
PROMPT_DIR='~/azure'
cd ~/azure

block write
run 'az storage container create -n quitanda-analytics'
run 'python onelake.py'
run "python -c \"import orders, pyarrow.csv as c; c.write_csv(orders.october(days=1), 'export.csv')\""
run 'az storage blob upload -c quitanda-analytics -f export.csv -n sales.Lakehouse/Files/exports/2026-10-01.csv -o none'
run "az storage blob list -c quitanda-analytics --query '[].{name:name, bytes:properties.contentLength}' -o table"

block log
run 'az storage blob download -c quitanda-analytics -n sales.Lakehouse/Tables/orders/_delta_log/00000000000000000000.json -f v0.json -o none'
run 'jq -c keys v0.json'
run "jq -c '.protocol // empty' v0.json"
run "jq -r '.metaData // empty | .schemaString | fromjson | .fields[] | \"\\(.name) \\(.type)\"' v0.json"
run "jq -c '.add // empty | .stats | fromjson | {numRecords, minValues: {dt: .minValues.dt}, maxValues: {dt: .maxValues.dt}}' v0.json"

block ask
run 'python ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC"'
