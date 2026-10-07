#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of warehouse-modeling, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# NONE OF THE THREE PRODUCTS THIS LESSON IS ABOUT WAS RUN. There is no
# BigQuery, Snowflake or Redshift account in this course, and the SQL the
# lesson shows in their dialects is marked as not run where it appears.
#
# What runs here is arithmetic on the lab's own data, in DuckDB: the bytes a
# query would be billed for under BigQuery's on-demand model, counted the way
# BigQuery's price page says it counts them (the columns a query reads, at
# the logical size of each data type: 8 bytes for an INT64 or a DATE, 2 bytes
# plus the UTF-8 length for a STRING), and priced at the US$ 6.25 per TiB that
# page listed when it was read on 2026-10-06. The numbers are an estimate of a
# bill, not a bill.
#
# STAGED: ~/wh/wh.duckdb, the warehouse lessons 2 to 5 build.
#
# Recorded on Ubuntu 24.04, DuckDB 1.5.6, TZ=America/Sao_Paulo, on 2026-10-06.
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

put logical-bytes.sql <<'EOF'
-- The bytes BigQuery's on-demand model would bill for one query:
-- revenue of 2025 by department. Every column the query names, over every
-- row of its table, at BigQuery's logical size for the column's type.
WITH read AS (
    SELECT 'fact_sales' AS tbl, 3 * 8 * count(*) AS bytes   -- date_key, book_key, net_cents
    FROM fact_sales
    UNION ALL
    SELECT 'dim_date', 2 * 8 * count(*)                       -- date_key, year
    FROM dim_date
    UNION ALL
    SELECT 'dim_book', 8 * count(*) + sum(2 + strlen(department))
    FROM dim_book                                             -- book_key, department
)
SELECT tbl, bytes,
       greatest(bytes, 10 * 1024 * 1024) AS billed_bytes      -- 10 MB minimum per table
FROM read;
EOF
code logical-bytes-sql logical-bytes.sql
block logical-bytes
on 'duckdb wh.duckdb < logical-bytes.sql'

put scenarios.sql <<'EOF'
-- The same arithmetic for four queries, priced at US$ 6.25 per TiB.
WITH q (query, bytes) AS (VALUES
    ('revenue by department, all of fact_sales, 3 columns', 3 * 8 * 887477),
    ('SELECT * from fact_sales, all 11 columns',          11 * 8 * 887477),
    ('the first query, on 1,000 times the rows', 1000 * 3 * 8 * CAST(887477 AS BIGINT)),
    ('the same, partitioned by month, asking for one month', 1000 * 3 * 8 * CAST(887477 AS BIGINT) / 24)
)
SELECT query,
       round(bytes / 1024 / 1024 / 1024, 3)                AS gib,
       round(greatest(bytes, 10485760) / 1024 ^ 4 * 6.25, 4) AS usd
FROM q;
EOF
code scenarios-sql scenarios.sql
block scenarios
on 'duckdb wh.duckdb < scenarios.sql'
