#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of warehouse-modeling, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: ~/wh/wh.duckdb, the warehouse lessons 2
# to 5 build, made here by `lab.sh warehouse`. The copy of fact_sales in
# PostgreSQL, the Parquet files and the reordered copies are made by the files
# `put` writes, which the lesson shows as they are. Timings are one run each,
# on a 4-core machine shared with other work, and move from run to run.
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

put to-postgres.sql <<'EOF'
-- The same fact table, stored by row in PostgreSQL.
CREATE TABLE fact_sales (date_key int, shop_key int, book_key int, customer_key int,
    promotion_key int, order_id bigint, line_no int, quantity int, gross_cents bigint,
    discount_cents bigint, net_cents bigint);
\copy fact_sales FROM 'fact_sales.csv' WITH (FORMAT csv, HEADER true)
VACUUM ANALYZE fact_sales;
EOF
block sizes
on "duckdb wh.duckdb -c \"COPY fact_sales TO 'fact_sales.csv' (HEADER); COPY fact_sales TO 'fact_sales.parquet'\""
on "psql -q -f to-postgres.sql"
on "duckdb only_sales.duckdb -c \"ATTACH 'wh.duckdb' AS wh (READ_ONLY); CREATE TABLE fact_sales AS FROM wh.fact_sales\""
on "psql -c \"SELECT pg_size_pretty(pg_table_size('fact_sales')) AS postgres_table\""
on 'ls -l fact_sales.csv only_sales.duckdb fact_sales.parquet'

block one-column
on "psql -c \"EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF) SELECT sum(net_cents) FROM fact_sales\" | grep -E 'Seq Scan|Buffers' | head -2"
on "psql -c \"SELECT pg_relation_size('fact_sales') / 8192 AS pages\""

put columns.sql <<'EOF'
-- How the Parquet file stores each column: bytes before and after encoding.
SELECT path_in_schema               AS column_name,
       sum(total_uncompressed_size) AS raw_bytes,
       sum(total_compressed_size)   AS stored_bytes
FROM parquet_metadata('fact_sales.parquet')
GROUP BY ALL
ORDER BY stored_bytes DESC;
EOF
code columns-sql columns.sql
block columns
on 'duckdb < columns.sql'

put compression.sql <<'EOF'
-- How DuckDB compressed each column of its own fact_sales.
SELECT column_name, compression, count(*) AS segments
FROM pragma_storage_info('fact_sales')
WHERE segment_type <> 'VALIDITY'
GROUP BY ALL
ORDER BY column_name, segments DESC;
EOF
code compression-sql compression.sql
block compression
on 'duckdb wh.duckdb < compression.sql'

put dictionary.sql <<'EOF'
-- A column with few distinct values, and one with many.
SELECT count(DISTINCT shop_key) AS shops, count(DISTINCT order_id) AS orders,
       count(*) AS rows
FROM fact_sales;
EOF
code dictionary-sql dictionary.sql
block dictionary
on 'duckdb wh.duckdb < dictionary.sql'

put order.sql <<'EOF'
-- The same rows in three orders: shuffled, as loaded, and sorted by shop and date.
COPY (SELECT * FROM fact_sales ORDER BY hash(order_id, line_no)) TO 'shuffled.parquet';
COPY (SELECT * FROM fact_sales ORDER BY order_id, line_no)       TO 'by_order.parquet';
COPY (SELECT * FROM fact_sales ORDER BY shop_key, date_key)      TO 'by_shop_date.parquet';

SELECT file_name,
       sum(total_compressed_size) FILTER (WHERE path_in_schema = 'shop_key') AS shop_key_bytes,
       sum(total_compressed_size) FILTER (WHERE path_in_schema = 'date_key') AS date_key_bytes,
       sum(total_compressed_size)                                            AS all_columns
FROM parquet_metadata(['shuffled.parquet', 'by_order.parquet', 'by_shop_date.parquet'])
GROUP BY file_name ORDER BY all_columns DESC;
EOF
code order-sql order.sql
block order
on 'duckdb wh.duckdb < order.sql'

put ints.sql <<'EOF'
-- The range of values in some integer columns, and the bits that range needs.
SELECT 'quantity' AS column_name, min(quantity) AS lowest, max(quantity) AS highest,
       ceil(log2(max(quantity) - min(quantity) + 1)) AS bits_needed FROM fact_sales
UNION ALL
SELECT 'shop_key', min(shop_key), max(shop_key),
       ceil(log2(max(shop_key) - min(shop_key) + 1)) FROM fact_sales
UNION ALL
SELECT 'order_id', min(order_id), max(order_id),
       ceil(log2(max(order_id) - min(order_id) + 1)) FROM fact_sales;
EOF
code ints-sql ints.sql
block ints
on 'duckdb wh.duckdb < ints.sql'

put strings.sql <<'EOF'
SELECT column_name, compression, count(*) AS segments
FROM pragma_storage_info('dim_book')
WHERE column_name IN ('title', 'department', 'format', 'authors')
  AND segment_type <> 'VALIDITY'
GROUP BY ALL ORDER BY column_name;
EOF
code strings-sql strings.sql
block strings
on 'duckdb wh.duckdb < strings.sql'

put zonemaps.sql <<'EOF'
-- Every row group keeps the minimum and maximum of each column. How many
-- row groups of each file could hold a sale from March 2025?
SELECT file_name,
       count(*) AS row_groups,
       count(*) FILTER (WHERE CAST(stats_min AS INTEGER) <= 20250331
                          AND CAST(stats_max AS INTEGER) >= 20250301) AS must_be_read
FROM parquet_metadata(['shuffled.parquet', 'by_order.parquet'])
WHERE path_in_schema = 'date_key'
GROUP BY file_name ORDER BY file_name;
EOF
code zonemaps-sql zonemaps.sql
block zonemaps
on 'duckdb < zonemaps.sql'

block rowgroups
on "duckdb -c \"SELECT row_group_id, row_group_num_rows AS rows, stats_min, stats_max FROM parquet_metadata('by_order.parquet') WHERE path_in_schema = 'date_key' ORDER BY row_group_id\""

block schema
on "duckdb -c \"SELECT name, type FROM parquet_schema('fact_sales.parquet')\""
on "duckdb -c \"SELECT num_rows, num_row_groups, format_version, created_by FROM parquet_file_metadata('fact_sales.parquet')\""

put pg-sum.sql <<'EOF'
\timing on
SELECT sum(net_cents) FROM fact_sales;
EOF
put duck-sum.sql <<'EOF'
.timer on
SELECT sum(net_cents) FROM fact_sales;
EOF
block engines
on 'psql -f pg-sum.sql'
on 'duckdb wh.duckdb < duck-sum.sql'

put lookup.sql <<'EOF'
\timing on
CREATE INDEX ON fact_sales (order_id);
SELECT line_no, net_cents FROM fact_sales WHERE order_id = 112406;
EOF
put duck-lookup.sql <<'EOF'
.timer on
SELECT line_no, net_cents FROM fact_sales WHERE order_id = 112406;
EOF
block lookup
on 'psql -f lookup.sql'
on 'duckdb wh.duckdb < duck-lookup.sql'

block inserts
on "seq 1 2000 | awk '{ print \"INSERT INTO t VALUES (\" \$1 \", \" \$1 * 7 \");\" }' > inserts.sql"
on 'head -2 inserts.sql'
on "psql -q -c 'CREATE TABLE t (a int, b int)'"
on "TIMEFORMAT='%R seconds'; time psql -q -f inserts.sql"
on "duckdb small.duckdb -c 'CREATE TABLE t (a int, b int)'"
on "TIMEFORMAT='%R seconds'; time duckdb small.duckdb < inserts.sql"
