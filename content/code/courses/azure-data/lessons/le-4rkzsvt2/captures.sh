#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", with SQL Server started and empty. The shell function `sql` is
# the first ```sh fence of cross-database.md, sourced as it stands (its
# `docker compose` line is the one `services` stands in for). orders.sql is
# read out of lesson 8, where the student saved it; delivery.sql, job.sql and
# main.tf are read out of this lesson, so there is no second copy here.
#
# STAGED: SQL Server is started by `services` rather than by the
# `docker compose --profile sql up -d` the student types, and the wait until
# it accepts a connection is not shown. Terraform never reaches Azure.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services sql || exit 1

eval "$(fence "$HERE/cross-database.md" 1 | grep '^sql()')"
export -f sql
file_fence "$LESSONS/le-16v3n5ab/the-engine.md" orders.sql > orders.sql
file_fence "$HERE/cross-database.md" delivery.sql > delivery.sql
file_fence "$HERE/sql-agent.md" job.sql > job.sql

block build
run 'sql < orders.sql'
run 'sql < delivery.sql'
block join
run 'sql -d quitanda -Q "SELECT TOP (3) o.order_id, o.total_cents, d.courier, d.delivered_at FROM dbo.orders o JOIN delivery.dbo.deliveries d ON d.order_id = o.order_id ORDER BY o.order_id"'
block job
run 'sql < job.sql'
run "sql -Q \"EXEC msdb.dbo.sp_start_job @job_name = N'nightly-totals'\""
run 'sleep 5; sql -Q "SELECT j.name, h.step_name, h.run_status FROM msdb.dbo.sysjobhistory h JOIN msdb.dbo.sysjobs j ON j.job_id = h.job_id"'
run 'sql -d quitanda -Q "SELECT COUNT(*) AS days, MIN(day) AS first_day, MAX(day) AS last_day, SUM(orders) AS orders FROM dbo.daily_totals"'

bash -e <(fence "$HERE/the-network.md" 1) || exit 1
cd ~/azure/tf/sqlmi && file_fence "$HERE/the-network.md" main.tf > main.tf
PROMPT_DIR='~/azure/tf/sqlmi'
block tf-valid
run "terraform init -no-color | grep -E 'Installing|Installed|successfully'"
run 'terraform validate -no-color'
block tf-sku
run "sed -i.bak 's/\"GP_Gen5\"/\"GP_Gen5_8\"/' main.tf && terraform validate -no-color; mv main.tf.bak main.tf"
block tf-licence
run "sed -i.bak 's/\"BasePrice\"/\"BringYourOwn\"/' main.tf && terraform validate -no-color 2>&1 | grep Error; mv main.tf.bak main.tf"
PROMPT_DIR='~/azure'
block end
