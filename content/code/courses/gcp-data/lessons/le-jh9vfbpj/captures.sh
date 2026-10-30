#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of gcp-data (AlloyDB), as a script
# that produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# NOTHING HERE IS ALLOYDB. Google publishes no emulator for it, and this course
# has no account, so the storage layer, the instances, the read pools, the
# columnar engine and AlloyDB Omni are taught from Google's documentation and
# pricing page, and the lesson marks them as not run. What does run:
#   - `gcloud alloydb … --help`, and a flag the command line refuses before it
#     sends anything: both answer offline, from the CLI's own files;
#   - PostgreSQL 16, Ubuntu's package, as the engine AlloyDB is compatible
#     with: orders.sql is read out of columnar-engine.md as it stands;
#   - compare.py, read out of the schooling-example of the-bill.md.
#
# STAGED:
#   - postgresql-16 is installed on the recording machine already; the lesson
#     shows it as an apt-get line.
#   - the student runs `postgres` in the foreground of a terminal of its own;
#     here it is started in the background, as the OS user `postgres`, because
#     the recording runs as root and PostgreSQL refuses to run as root. initdb
#     takes the same flags the lesson gives, so the superuser is `quitanda`.
#   - /tmp is a private tmpfs for this run, so the server's socket in /tmp
#     cannot meet another capture's running at the same time.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
L="$HERE"

# ---- a-cluster ----------------------------------------------------------------
block help-types
run "gcloud alloydb instances create --help | sed -n '/^     --instance-type/,/zones in a region/p'"
block help-cpu
run "gcloud alloydb instances create --help | sed -n '/^     --cpu-count/,/288\\./p'"
block bad-flag
run 'gcloud alloydb instances create quitanda-orders-reads --cluster=quitanda-orders --region=southamerica-east1 --instance-type=READ_POOL --cpu-count=8 --read-pool-nodes=2'

# ---- where-it-fits --------------------------------------------------------------
block migrate-help
run "gcloud alloydb clusters migrate-cloud-sql --help | sed -n '/^DESCRIPTION/,/^EXAMPLES/p'"

# ---- columnar-engine: a PostgreSQL of the student's own --------------------------
export PATH="/usr/lib/postgresql/16/bin:$PATH"
mount -t tmpfs tmpfs /tmp || exit 1
mkdir -p ~/gcp/pg && chown postgres ~/gcp/pg
runuser -u postgres -- initdb -D "$HOME/gcp/pg" -U quitanda --auth=trust > /dev/null || exit 1
( cd ~/gcp && setsid runuser -u postgres -- postgres -D "$HOME/gcp/pg" -k /tmp -p 5433 -c listen_addresses='' \
    > ~/.pg.log 2>&1 < /dev/null & )
for _ in $(seq 40); do pg_isready -q -h /tmp -p 5433 && break; sleep 0.25; done
export PGHOST=/tmp PGPORT=5433 PGUSER=quitanda PGDATABASE=postgres
file_fence "$L/columnar-engine.md" orders.sql > orders.sql

block pg-load
run 'psql -q -f orders.sql > /dev/null'
run "psql -c \"SELECT pg_size_pretty(pg_relation_size('orders')) AS size, pg_relation_size('orders') / 8192 AS pages\""
block pg-wide
run "psql -c \"SELECT district, count(*), sum(total_cents) FROM orders WHERE day >= '2026-10-01' GROUP BY district ORDER BY district\""
run "psql -c 'SET max_parallel_workers_per_gather = 0' -c \"EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT district, count(*), sum(total_cents) FROM orders WHERE day >= '2026-10-01' GROUP BY district\""
block pg-narrow
run "psql -c 'CREATE TABLE orders_cols AS SELECT day, district, total_cents FROM orders' -c 'VACUUM ANALYZE orders_cols'"
run "psql -c \"SELECT pg_size_pretty(pg_relation_size('orders_cols')) AS size, pg_relation_size('orders_cols') / 8192 AS pages\""
run "psql -c 'SET max_parallel_workers_per_gather = 0' -c \"EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT district, count(*), sum(total_cents) FROM orders_cols WHERE day >= '2026-10-01' GROUP BY district\""
block pg-point
run "psql -c 'EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT * FROM orders WHERE order_id = 1234567'"
block pg-alloydb-only
run "psql -c \"SELECT google_columnar_engine_add('orders')\""
kill "$(head -1 ~/gcp/pg/postmaster.pid)" 2>/dev/null
for _ in $(seq 40); do [ -f ~/gcp/pg/postmaster.pid ] || break; sleep 0.25; done

# ---- the-bill -------------------------------------------------------------------
example "$L/the-bill.md" compare.py compare.py
block bill-run
run 'python3 compare.py'
block bill-node
run "python3 -c 'print(round(8 * 0.1051 + 64 * 0.01781, 5), round(8 * 0.062 + 64 * 0.0105, 5), round(8 * 0.1239 + 64 * 0.021, 5))'"
block bill-line
run "python3 -c 'print(round((2 * 2891.73 - 1704.70 - 1705.28) / (0.51 + 2 * 0.255 - 0.476909)))'"
