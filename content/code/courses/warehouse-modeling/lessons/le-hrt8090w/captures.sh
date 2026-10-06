#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of warehouse-modeling, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: ~/wh/wh.duckdb, the warehouse lessons 2
# to 5 build, made here by `lab.sh warehouse`.
#
# THE LARGE TABLE IS SYNTHETIC. fact_sales_x20 is twenty copies of fact_sales,
# with a column saying which copy a row is, so that a query runs long enough
# for its timing to be read. The lesson says so where it uses it. Nothing in it
# is a sale that happened twenty times.
#
# THERE IS ONE MACHINE. The "nodes" of sections 07 to 09 are a hash of a key
# modulo 4, computed in SQL to count where rows would go on four machines; no
# second machine was involved. The timings are one run each, on a 4-core
# machine shared with other work, and move from run to run.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, DuckDB 1.5.6, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/wh$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
put() { lab exec "cat > '$1'"; }
code() { printf '##### %s\n' "$1"; lab exec "cat '$2'"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/wh-capture.lock; flock 9
lab reset >/dev/null
lab warehouse >/dev/null

block cores
on 'nproc'
on 'free -m | head -2'

put x20.sql <<'EOF'
-- Twenty copies of the sales table, to have something that takes time.
CREATE TABLE fact_sales_x20 AS
SELECT f.*, c.copy FROM fact_sales f, range(20) AS c(copy);
SELECT count(*) AS rows FROM fact_sales_x20;
EOF
code x20-sql x20.sql
block x20
on 'duckdb wh.duckdb < x20.sql'

put threads.sql <<'EOF'
-- One question, asked with one, two and four threads.
.timer on
SET threads = 1;
SELECT count(*) FROM (SELECT b.department, d.month, sum(f.net_cents)
                      FROM fact_sales_x20 f JOIN dim_book b USING (book_key)
                      JOIN dim_date d USING (date_key) GROUP BY ALL);
SET threads = 2;
SELECT count(*) FROM (SELECT b.department, d.month, sum(f.net_cents)
                      FROM fact_sales_x20 f JOIN dim_book b USING (book_key)
                      JOIN dim_date d USING (date_key) GROUP BY ALL);
SET threads = 4;
SELECT count(*) FROM (SELECT b.department, d.month, sum(f.net_cents)
                      FROM fact_sales_x20 f JOIN dim_book b USING (book_key)
                      JOIN dim_date d USING (date_key) GROUP BY ALL);
EOF
code threads-sql threads.sql
block threads
on "duckdb -list wh.duckdb < threads.sql | grep 'Run Time'"

put memory.sql <<'EOF'
-- A grouping with 17.7 million groups, given less and less memory.
.timer on
SELECT count(*) FROM (SELECT order_id, line_no, copy, sum(net_cents)
                      FROM fact_sales_x20 GROUP BY ALL);
SET memory_limit = '200MB';
SELECT count(*) FROM (SELECT order_id, line_no, copy, sum(net_cents)
                      FROM fact_sales_x20 GROUP BY ALL);
SET memory_limit = '20MB';
SELECT count(*) FROM (SELECT order_id, line_no, copy, sum(net_cents)
                      FROM fact_sales_x20 GROUP BY ALL);
EOF
code memory-sql memory.sql
block memory
on "duckdb -list wh.duckdb < memory.sql 2>&1 | grep -E 'Run Time|Error|^[0-9]'"

put nodes.sql <<'EOF'
-- Where the sales rows would go on four machines, by two choices of key.
SELECT hash(order_id) % 4 AS node, count(*) AS rows_by_order
FROM fact_sales GROUP BY node ORDER BY node;

SELECT hash(shop_key) % 4 AS node, count(*) AS rows_by_shop
FROM fact_sales GROUP BY node ORDER BY node;
EOF
code nodes-sql nodes.sql
block nodes
on 'duckdb wh.duckdb < nodes.sql'

block online-share
on "duckdb wh.duckdb -c \"SELECT s.shop_name, count(*) AS rows, round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct FROM fact_sales f JOIN dim_shop s USING (shop_key) GROUP BY ALL ORDER BY rows DESC LIMIT 2\""

put movement.sql <<'EOF'
-- Sales are spread by order. To join them with books spread by book, how
-- many rows would have to move? And to copy the whole book table to every
-- machine instead?
SELECT count(*) FILTER (WHERE hash(order_id) % 4 <> hash(book_key) % 4) AS sales_rows_moved,
       count(*)                                                          AS sales_rows,
       (SELECT count(*) * 3 FROM dim_book)                               AS book_rows_copied
FROM fact_sales;
EOF
code movement-sql movement.sql
block movement
on 'duckdb wh.duckdb < movement.sql'

put lake.sql <<'EOF'
-- The sales, written as Parquet files, one folder per year and month.
COPY (SELECT f.*, d.year, d.month FROM fact_sales f JOIN dim_date d USING (date_key))
TO 'sales_by_month' (FORMAT parquet, PARTITION_BY (year, month));
EOF
code lake-sql lake.sql
block lake
on 'duckdb wh.duckdb < lake.sql'
on 'ls sales_by_month sales_by_month/year=2025 | head -8'
on 'find sales_by_month -name "*.parquet" | wc -l'

put pruning.sql <<'EOF'
EXPLAIN ANALYZE
SELECT sum(net_cents)
FROM read_parquet('sales_by_month/*/*/*.parquet', hive_partitioning = true)
WHERE year = 2025 AND month = 3;
EOF
code pruning-sql pruning.sql
block pruning
on "duckdb wh.duckdb < pruning.sql | grep -E 'Filters|year = |Scanning|Total Files'"
