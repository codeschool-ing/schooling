#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", with SQL Server started and empty. The shell function `sql` and
# the query `Q` are the second ```sh fence of the-engine.md, sourced as they
# stand; orders.sql, main.tf, pool.tf and breakeven.py are read out of the
# lesson, so there is no second copy here.
#
# STAGED: SQL Server is started by `services` rather than by the
# `docker compose --profile sql up -d` the student types, and the wait until
# it accepts a connection is not shown. Terraform never reaches Azure:
# `init` reads the provider from the plugin cache lesson 1 set up, and
# `validate` is offline.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services sql || exit 1

. <(fence "$HERE/the-engine.md" 2) || exit 1
export -f sql
export Q
file_fence "$HERE/the-engine.md" orders.sql > orders.sql

block load
run 'sql < orders.sql'
block edition
run "sql -Q \"SELECT CAST(SERVERPROPERTY('EngineEdition') AS int) AS engine_edition, CAST(SERVERPROPERTY('Edition') AS varchar(40)) AS edition, CAST(DATABASEPROPERTYEX('quitanda', 'ServiceObjective') AS varchar(20)) AS service_objective\""
block before
run 'sql -d quitanda -Q "SET STATISTICS IO ON; $Q" | cut -d, -f1-2'
run "printf 'SET SHOWPLAN_TEXT ON\nGO\n%s\nGO\n' \"\$Q\" | sql -d quitanda | grep -oE '(Clustered )?Index (Scan|Seek)'"
block after
run 'sql -d quitanda -Q "CREATE INDEX ix_orders_customer ON dbo.orders (customer_id) INCLUDE (total_cents)"'
run 'sql -d quitanda -Q "SET STATISTICS IO ON; $Q" | cut -d, -f1-2'
run "printf 'SET SHOWPLAN_TEXT ON\nGO\n%s\nGO\n' \"\$Q\" | sql -d quitanda | grep -oE '(Clustered )?Index (Scan|Seek)'"

bash -e <(fence "$HERE/dtu-and-vcore.md" 1) || exit 1
cd ~/azure/tf/sql && file_fence "$HERE/dtu-and-vcore.md" main.tf > main.tf
PROMPT_DIR='~/azure/tf/sql'
block tf-valid
run "terraform init -no-color | grep -E 'Installing|Installed|successfully'"
run 'terraform validate -no-color'
block tf-sku
run "sed -i.bak 's/\"GP_Gen5_2\"/\"GP-Gen5-2\"/' main.tf && terraform validate -no-color; mv main.tf.bak main.tf"
block tf-retention
run "sed -i.bak 's/retention_days = 7/retention_days = 40/' main.tf && terraform validate -no-color 2>&1 | grep Error; mv main.tf.bak main.tf"
block tf-pause
run "sed -i.bak 's/auto_pause_delay_in_minutes = 60/auto_pause_delay_in_minutes = 5/' main.tf && terraform validate -no-color 2>&1 | grep Error; mv main.tf.bak main.tf"
block tf-min
run "sed -i.bak 's/min_capacity                = 0.5/min_capacity                = 0.1/' main.tf && terraform validate -no-color 2>&1 | grep Error; mv main.tf.bak main.tf"
block tf-pool
file_fence "$HERE/elastic-pools.md" pool.tf > pool.tf
run 'terraform validate -no-color'
block tf-pool-wrong
run "sed -i.bak 's/max_capacity = 50/max_capacity = 500/' pool.tf && terraform validate -no-color; mv pool.tf.bak pool.tf"
PROMPT_DIR='~/azure'
cd ~/azure

example "$HERE/serverless.md" breakeven.py ~/azure/breakeven.py || exit 1
block breakeven
run 'python breakeven.py'
block end
