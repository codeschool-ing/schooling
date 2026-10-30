#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE PROGRAMS ARE THE LESSON'S: gen.py and ask.py are the schooling-examples
# of the-lake.md and bytes-processed.md, main.tf is the fence that name
# introduces in declaring.md. Nothing is copied here.
#
# NOTHING HERE IS SYNAPSE. Azurite holds the files and DuckDB, through
# PyArrow, queries them; SQL Server is asked once, to show it refusing a
# dedicated pool's table definition. Terraform asks Azure nothing.
#
# STAGED: Azurite and SQL Server are started empty by `services`, where the
# student types the `docker compose` lines the sections give. gen.py is
# seeded, so the month of orders is the same on every run.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services sql || exit 1

example "$HERE/the-lake.md" gen.py gen.py
example "$HERE/bytes-processed.md" ask.py ask.py

block sqlrefuse
run 'docker compose exec sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P Quitanda-Lab-2026 -C -Q "CREATE TABLE dbo.orders (order_id varchar(10) NOT NULL, customer_id varchar(8) NOT NULL) WITH (DISTRIBUTION = HASH(customer_id), CLUSTERED COLUMNSTORE INDEX)"'

block gen
run 'python gen.py'

Q="SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM"
block csv-month
run "python ask.py \"$Q orders_csv GROUP BY payment ORDER BY reais DESC\""
block parquet-month
run "python ask.py \"$Q orders GROUP BY payment ORDER BY reais DESC\""
block parquet-day
run "python ask.py \"$Q orders WHERE dt = '2026-10-15' GROUP BY payment ORDER BY reais DESC\""
block csv-day
run "python ask.py \"$Q orders_csv WHERE dt = '2026-10-15' GROUP BY payment ORDER BY reais DESC\""

block tf
bash -e <(fence "$HERE/declaring.md" 1) || exit 1
cd ~/azure/tf/synapse && file_fence "$HERE/declaring.md" main.tf > main.tf
PROMPT_DIR='~/azure/tf/synapse'
run "terraform init -no-color | grep -E 'Installing|Installed|successfully'"
run 'terraform validate -no-color'
run "sed -i 's/DW100c/DW150c/' main.tf && terraform validate -no-color"
PROMPT_DIR='~/azure'
