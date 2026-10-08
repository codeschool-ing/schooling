#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of warehouse-modeling, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# SECTIONS 03 TO 06 ARE THE STUDENT'S SETUP, RUN FOR REAL. `lab.sh wipe` puts
# the machine back as apt left it, with the cluster stopped, no role, no
# database, none of the four settings and an empty ~/wh, and the blocks up to
# `disk` build it all again the way the lesson says to, failures included:
# every failure section 06 quotes is one a first run meets when a step is
# skipped or repeated, taken here by skipping or repeating it. The schema, the
# generator and load.sh are the course's lab/ files, which lab.sh refuses to
# run unless the lesson shows each of them whole, byte for byte.
#
# NOT RUN HERE: creating the virtual machine, which this machine cannot do.
# The apt-get and pip commands of section 03 were run, the first by hand on
# 2026-10-07 and the second by lab.sh, and are not quoted: their output is a
# page of download progress.
#
# STAGED for the blocks after `disk`: the database `shop` as lab.sh loads it,
# from the same generated files; and ~/wh/wh.duckdb, the warehouse lesson 2
# builds, made here by `lab.sh warehouse` with lesson 2's own build.sh so that
# section 12 can ask it the question section 09 asked the shop's database.
# The SQL files are written into ~/wh by `put` and shown in the lesson as they
# are.
#
# Timings are one run each, on a machine shared with other work, and they move
# from run to run; the lesson says so where it quotes one.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, DuckDB 1.5.6, Python 3.12, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-07.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
COURSE=$(cd "$(dirname "$LAB_SH")" && pwd)
lab() { bash "$LAB_SH" "$@"; }
# on 'command': what ana typed in ~/wh, and what it printed.
on() { printf 'ana@lab:~/wh$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
# put PATH: a file ana wrote in ~/wh, from stdin; `code` prints it as a block.
put() { lab exec "cat > '$1'"; }
code() { printf '##### %s\n' "$1"; lab exec "cat '$2'"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/wh-capture.lock; flock 9
lab check || exit 1
lab wipe >/dev/null 2>&1

block versions
on 'psql --version'
on 'duckdb --version'
on 'python3 --version'

block fail-down
on 'pg_lsclusters'
on "psql -c 'SELECT 1'"

block start
on 'sudo pg_ctlcluster 16 main start'
on 'pg_lsclusters'

block fail-role
on "psql -c 'SELECT 1'"

block role
on 'sudo -u postgres createuser --superuser $USER'

block fail-db
on "psql -c 'SELECT 1'"

block database
on 'createdb --locale=C.UTF-8 --template=template0 shop'
on "psql -c \"ALTER SYSTEM SET timezone = 'America/Sao_Paulo'\" -c \"ALTER SYSTEM SET shared_buffers = '512MB'\" -c \"ALTER SYSTEM SET max_parallel_workers_per_gather = 0\" -c \"ALTER SYSTEM SET jit = off\""

block fail-restart
on "psql -c 'SHOW shared_buffers'"

block restart
on 'sudo pg_ctlcluster 16 main restart'
on "psql -c 'SHOW shared_buffers'"

put oltp.sql < "$COURSE/lab/oltp.sql"
block schema
on 'psql -q -f oltp.sql'
on "psql -c '\dt'"

put generate.py < "$COURSE/lab/generate.py"
block run
on 'time python3 generate.py'
on 'ls extracts && ls data | wc -l && du -sh data extracts'

put load.sh < "$COURSE/lab/load.sh"
block load
on 'sh load.sh'
on "psql -c 'SELECT count(*) AS orders, min(ordered_at) AS first, max(ordered_at) AS last FROM orders'"

block fail-twice
on 'sh load.sh'

block start-over
on 'dropdb shop && createdb --locale=C.UTF-8 --template=template0 shop && psql -q -f oltp.sql && sh load.sh'

block disk
on 'sudo du -sh /var/lib/postgresql/16/main ~/wh-env ~/wh'

lab reset >/dev/null
lab warehouse >/dev/null

put sale.sql <<'EOF'
-- One sale at the Paulista till: two books, paid by Pix.
BEGIN;
INSERT INTO orders (order_id, shop_id, customer_id, ordered_at, status)
VALUES (900001, 1, 31579, '2026-01-02 10:14:00-03', 'completed');
INSERT INTO order_lines (order_id, line_no, book_id, quantity, unit_price_cents)
VALUES (900001, 1, 2395, 1, 15990),
       (900001, 2, 1036, 1, 12590);
INSERT INTO payments (payment_id, order_id, method, installments, amount_cents)
VALUES (2000001, 900001, 'pix', 1, 28580);
COMMIT;
EOF
code sale-sql sale.sql
block sale
on 'psql -f sale.sql'

put one-order.sql <<'EOF'
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT o.ordered_at, o.status, l.line_no, l.book_id, l.quantity, l.unit_price_cents
FROM orders o JOIN order_lines l USING (order_id)
WHERE o.order_id = 900001;
EOF
code one-order-sql one-order.sql
block one-order
on 'psql -f one-order.sql'

put report.sql <<'EOF'
-- Revenue by year and department, from the shop's own database.
SELECT extract(year FROM o.ordered_at) AS year,
       coalesce(top.name, mid.name)    AS department,
       round(sum(l.quantity * l.unit_price_cents - l.discount_cents) / 100.0, 2)
                                       AS revenue_brl
FROM orders o
JOIN order_lines l          USING (order_id)
JOIN books b                USING (book_id)
JOIN categories leaf        ON leaf.category_id = b.category_id
JOIN categories mid         ON mid.category_id = leaf.parent_id
LEFT JOIN categories top    ON top.category_id = mid.parent_id
WHERE o.status <> 'cancelled' AND o.ordered_at < '2026-01-01'
GROUP BY 1, 2
ORDER BY 1, 2;
EOF
code report-sql report.sql
block report
on 'psql -c "\timing on" -f report.sql'

block report-buffers
on "{ echo 'EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)'; cat report.sql; } | psql | grep -m1 Buffers"


put history.sql <<'EOF'
-- What the shop charged for one title, and what it says the title costs.
SELECT b.title, b.list_price_cents AS price_now,
       extract(year FROM o.ordered_at) AS year,
       min(l.unit_price_cents) AS charged_min, max(l.unit_price_cents) AS charged_max
FROM books b
JOIN order_lines l USING (book_id)
JOIN orders o      USING (order_id)
WHERE b.book_id = 2395 AND o.ordered_at < '2026-01-01'
GROUP BY 1, 2, 3 ORDER BY 3;
EOF
code history-sql history.sql
block history
on 'psql -f history.sql'

block moved
on "psql -c \"SELECT customer_id, city, state FROM customers WHERE customer_id = 2123\""
on "psql -c \"SELECT changed_at, field, old_value, new_value FROM customer_changes WHERE customer_id = 2123 ORDER BY changed_at\""

block moved-count
on "psql -c \"SELECT count(*) AS orders_2024, count(DISTINCT o.customer_id) AS customers FROM orders o JOIN customer_changes c USING (customer_id) WHERE c.field = 'state' AND o.ordered_at < '2025-01-01' AND c.changed_at >= '2025-01-01'\""

put wh-report.sql <<'EOF'
-- The same question, asked of the warehouse.
.timer on
SELECT d.year, b.department, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_date d USING (date_key)
JOIN dim_book b USING (book_key)
GROUP BY ALL
ORDER BY ALL;
EOF
code wh-report-sql wh-report.sql
block wh-report
on 'duckdb wh.duckdb < wh-report.sql'

block wh-tables
on "duckdb wh.duckdb -c \"SELECT table_name, estimated_size AS rows FROM duckdb_tables() WHERE schema_name = 'main' ORDER BY table_name\""
