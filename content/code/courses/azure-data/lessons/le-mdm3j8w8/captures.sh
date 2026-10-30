#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", with PostgreSQL started and empty. The shell function `pg` is
# the first ```sh fence of the-engine.md, sourced as it stands (its
# `docker compose` line is the one `services` stands in for). orders-pg.sql,
# main.tf, params.tf and mysql.tf are read out of the lesson, so there is no
# second copy here.
#
# STAGED: PostgreSQL is started by `services` rather than by the
# `docker compose --profile postgres up -d` the student types; after the
# `docker compose restart postgres` in server-parameters.md, the wait until
# it accepts connections again is not shown. Terraform never reaches Azure,
# and `az` stops at the login, as the transcript shows.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services postgres || exit 1

eval "$(fence "$HERE/the-engine.md" 1 | grep '^pg()')"
export -f pg
file_fence "$HERE/the-engine.md" orders-pg.sql > orders-pg.sql

block version
run 'pg -c "SELECT version()"'
block load
run 'pg < orders-pg.sql'
block query
run 'pg -c "EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF) SELECT count(*), sum(total_cents) FROM orders WHERE customer_id = 17"'
run 'pg -c "SELECT count(*), sum(total_cents) FROM orders WHERE customer_id = 17"'
block settings
run "pg -c \"SELECT name, setting, unit, context FROM pg_settings WHERE name IN ('max_connections', 'shared_buffers', 'shared_preload_libraries', 'work_mem', 'log_min_duration_statement') ORDER BY context, name\""
block stat-before
run 'pg -c "CREATE EXTENSION pg_stat_statements"'
run 'pg -c "SELECT count(*) FROM pg_stat_statements"'
block stat-alter
run "pg -c \"ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements'\""
run 'pg -c "SELECT pg_reload_conf()"'
run "pg -c \"SELECT name, setting, pending_restart FROM pg_settings WHERE name = 'shared_preload_libraries'\""
block stat-after
run 'docker compose restart postgres 2>&1 | tail -1'
for _ in $(seq 60); do docker compose exec -T postgres pg_isready -q -U postgres 2>/dev/null && break; sleep 0.5; done; sleep 1
run 'pg -c "SHOW shared_preload_libraries"'
run 'for i in 1 2 3; do pg -c "SELECT count(*), sum(total_cents) FROM orders WHERE customer_id = 17" > /dev/null; done'
run 'pg -c "SELECT calls, rows, query FROM pg_stat_statements ORDER BY calls DESC LIMIT 3"'
block az
run 'az postgres flexible-server parameter set --resource-group rg-quitanda-data-prd --server-name psql-quitanda-orders-prd --name shared_preload_libraries --value pg_stat_statements 2>&1 | tail -1'

bash -e <(fence "$HERE/flexible-server.md" 1) || exit 1
cd ~/azure/tf/flex && file_fence "$HERE/flexible-server.md" main.tf > main.tf
PROMPT_DIR='~/azure/tf/flex'
block tf-valid
run "terraform init -no-color | grep -E 'Installing|Installed|successfully'"
run 'terraform validate -no-color'
block tf-sku
run "sed -i.bak 's/\"GP_Standard_D2ds_v5\"/\"Standard_D2ds_v5\"/' main.tf && terraform validate -no-color; mv main.tf.bak main.tf"
block tf-params
file_fence "$HERE/server-parameters.md" params.tf > params.tf
run 'terraform validate -no-color'
block tf-hamode
run "sed -i.bak 's/\"ZoneRedundant\"/\"ZoneRedundant2\"/' main.tf && terraform validate -no-color 2>&1 | grep Error; mv main.tf.bak main.tf"
block tf-ha
run "sed -i.bak 's/\"GP_Standard_D2ds_v5\"/\"B_Standard_B1ms\"/' main.tf && terraform validate -no-color; mv main.tf.bak main.tf"
block tf-retention
run "sed -i.bak 's/backup_retention_days         = 7/backup_retention_days         = 40/' main.tf && terraform validate -no-color 2>&1 | grep Error; mv main.tf.bak main.tf"
block tf-mysql
file_fence "$HERE/pgbouncer-and-mysql.md" mysql.tf > mysql.tf
run 'terraform validate -no-color'
PROMPT_DIR='~/azure'
block end
