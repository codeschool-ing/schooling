#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of warehouse-modeling, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: ~/wh/wh.duckdb, the warehouse lessons 2
# to 5 build, made here by `lab.sh warehouse`. The wide table, the copies in
# PostgreSQL, the vault tables and the aggregate are built by the files `put`
# writes, which the lesson shows as they are. Timings are one run each, on a
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

put obt.sql <<'EOF'
-- One big table: every sale with every attribute of its dimensions on the row.
CREATE TABLE sales_wide AS
SELECT f.order_id, f.line_no, f.quantity, f.gross_cents, f.discount_cents, f.net_cents,
       d.date, d.year, d.month, d.month_name, d.day_name, d.is_weekend, d.is_holiday,
       s.shop_name, s.city AS shop_city, s.state AS shop_state, s.region, s.channel,
       b.isbn, b.title, b.authors, b.format, b.category, b.subcategory, b.department,
       b.publisher,
       c.tier, c.city AS customer_city, c.state AS customer_state,
       p.code AS promotion_code, p.promotion_name
FROM fact_sales f
JOIN dim_date d      USING (date_key)
JOIN dim_shop s      USING (shop_key)
JOIN dim_book b      USING (book_key)
JOIN dim_customer c  USING (customer_key)
JOIN dim_promotion p USING (promotion_key);
EOF
code obt-sql obt.sql
block obt
on 'duckdb wh.duckdb < obt.sql'
on "duckdb wh.duckdb -c \"SELECT count(*) AS rows, (SELECT count(*) FROM information_schema.columns WHERE table_name = 'sales_wide') AS columns FROM sales_wide\""

put rename.sql <<'EOF'
-- The department "Non-fiction" is renamed "Nonfiction". Where does that write?
SELECT (SELECT count(*) FROM sf_department_demo WHERE department = 'Non-fiction') AS snowflake_rows,
       (SELECT count(*) FROM dim_book WHERE department = 'Non-fiction')            AS star_rows,
       (SELECT count(*) FROM sales_wide WHERE department = 'Non-fiction')          AS wide_rows;
EOF
code rename-sql rename.sql
block rename
on "duckdb wh.duckdb -c \"CREATE TABLE sf_department_demo AS SELECT DISTINCT department FROM dim_book\""
on 'duckdb wh.duckdb < rename.sql'

put half-update.sql <<'EOF'
-- The rename, interrupted halfway: 2025 has been rewritten and 2024 not yet.
BEGIN;
UPDATE sales_wide SET department = 'Nonfiction'
WHERE department = 'Non-fiction' AND year = 2025;

SELECT year, department, count(*) AS lines
FROM sales_wide WHERE department IN ('Non-fiction', 'Nonfiction')
GROUP BY ALL ORDER BY ALL;
ROLLBACK;
EOF
code half-update-sql half-update.sql
block half-update
on 'duckdb wh.duckdb < half-update.sql'

put export.sql <<'EOF'
-- The star and the wide table, as files PostgreSQL can load and as Parquet.
COPY fact_sales    TO 'pg/fact_sales.csv'    (HEADER);
COPY dim_date      TO 'pg/dim_date.csv'      (HEADER);
COPY dim_shop      TO 'pg/dim_shop.csv'      (HEADER);
COPY dim_book      TO 'pg/dim_book.csv'      (HEADER);
COPY dim_customer  TO 'pg/dim_customer.csv'  (HEADER);
COPY dim_promotion TO 'pg/dim_promotion.csv' (HEADER);
COPY sales_wide    TO 'pg/sales_wide.csv'    (HEADER);
EOF
put pg-load.sql <<'EOF'
-- The same tables, stored by row in PostgreSQL.
CREATE SCHEMA wh;
CREATE TABLE wh.fact_sales (date_key int, shop_key int, book_key int, customer_key int,
    promotion_key int, order_id bigint, line_no int, quantity int, gross_cents bigint,
    discount_cents bigint, net_cents bigint);
CREATE TABLE wh.dim_date (date_key int, date date, year int, quarter int, month int,
    month_name text, day_of_month int, day_of_week int, day_name text, is_weekend bool,
    is_holiday bool, holiday text);
CREATE TABLE wh.dim_shop (shop_key int, shop_id int, shop_name text, city text, state text,
    region text, channel text, opened_on date);
CREATE TABLE wh.dim_book (book_key int, book_id int, isbn text, title text, authors text,
    format text, category text, subcategory text, department text, publisher text,
    published_on date);
CREATE TABLE wh.dim_customer (customer_key int, customer_id int, name text, tier text,
    city text, state text, valid_from timestamptz, valid_to timestamptz, is_current bool);
CREATE TABLE wh.dim_promotion (promotion_key int, promotion_id int, code text,
    promotion_name text, percent_off int, starts_on date, ends_on date, applies_to text);
CREATE TABLE wh.sales_wide (order_id bigint, line_no int, quantity int, gross_cents bigint,
    discount_cents bigint, net_cents bigint, date date, year int, month int, month_name text,
    day_name text, is_weekend bool, is_holiday bool, shop_name text, shop_city text,
    shop_state text, region text, channel text, isbn text, title text, authors text,
    format text, category text, subcategory text, department text, publisher text, tier text,
    customer_city text, customer_state text, promotion_code text, promotion_name text);
\copy wh.fact_sales FROM 'pg/fact_sales.csv' WITH (FORMAT csv, HEADER true)
\copy wh.dim_date FROM 'pg/dim_date.csv' WITH (FORMAT csv, HEADER true)
\copy wh.dim_shop FROM 'pg/dim_shop.csv' WITH (FORMAT csv, HEADER true)
\copy wh.dim_book FROM 'pg/dim_book.csv' WITH (FORMAT csv, HEADER true)
\copy wh.dim_customer FROM 'pg/dim_customer.csv' WITH (FORMAT csv, HEADER true)
\copy wh.dim_promotion FROM 'pg/dim_promotion.csv' WITH (FORMAT csv, HEADER true)
\copy wh.sales_wide FROM 'pg/sales_wide.csv' WITH (FORMAT csv, HEADER true)
VACUUM ANALYZE;
EOF
put pg-sizes.sql <<'EOF'
SELECT 'star: fact and five dimensions' AS model,
       pg_size_pretty(sum(pg_total_relation_size(c.oid))) AS size
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'wh' AND c.relkind = 'r' AND c.relname <> 'sales_wide'
UNION ALL
SELECT 'one big table', pg_size_pretty(pg_total_relation_size('wh.sales_wide'));
EOF
put pq-sizes.sql <<'EOF'
COPY fact_sales    TO 'pq/fact_sales.parquet';
COPY dim_date      TO 'pq/dim_date.parquet';
COPY dim_shop      TO 'pq/dim_shop.parquet';
COPY dim_book      TO 'pq/dim_book.parquet';
COPY dim_customer  TO 'pq/dim_customer.parquet';
COPY dim_promotion TO 'pq/dim_promotion.parquet';
COPY sales_wide    TO 'pq/sales_wide.parquet';
SELECT CASE WHEN file LIKE '%sales_wide%' THEN 'one big table'
            ELSE 'star: fact and five dimensions' END AS model,
       sum(size) AS bytes
FROM (SELECT filename AS file, size FROM read_blob('pq/*.parquet'))
GROUP BY ALL ORDER BY bytes;
EOF
code pg-sizes-sql pg-sizes.sql
code pq-sizes-sql pq-sizes.sql
block sizes
on 'mkdir -p pg pq && duckdb wh.duckdb < export.sql'
on 'psql -q -f pg-load.sql'
on 'psql -f pg-sizes.sql'
on 'duckdb wh.duckdb < pq-sizes.sql'

put q-star.sql <<'EOF'
.timer on
SELECT b.department, c.tier, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_book b     USING (book_key)
JOIN dim_customer c USING (customer_key)
JOIN dim_date d     USING (date_key)
WHERE d.year = 2025 AND c.customer_key > 0
GROUP BY ALL ORDER BY ALL;
EOF
put q-wide.sql <<'EOF'
.timer on
SELECT department, tier, round(sum(net_cents) / 100, 2) AS revenue_brl
FROM sales_wide
WHERE year = 2025 AND tier <> 'none'
GROUP BY ALL ORDER BY ALL;
EOF
code q-star-sql q-star.sql
code q-wide-sql q-wide.sql
block speed
on 'duckdb wh.duckdb < q-star.sql'
on 'duckdb wh.duckdb < q-wide.sql'

put vault.sql <<'EOF'
-- A fragment of a Data Vault for customers: a hub of business keys, and a
-- satellite of their tier, one row per change, both stamped with the load.
CREATE TABLE hub_customer AS
SELECT md5(CAST(customer_id AS VARCHAR)) AS customer_hk, customer_id,
       TIMESTAMPTZ '2025-12-31 23:00:00-03' AS load_ts, 'shop.customers' AS record_source
FROM staging.customers;

CREATE TABLE sat_customer_tier AS
SELECT md5(CAST(customer_id AS VARCHAR)) AS customer_hk, valid_from AS load_ts, tier,
       'shop.customer_changes' AS record_source
FROM dim_customer WHERE customer_key > 0;

-- The current tier of every customer, as a reader of the vault has to ask it.
SELECT tier, count(*) AS customers
FROM (SELECT h.customer_id, s.tier
      FROM hub_customer h
      JOIN sat_customer_tier s USING (customer_hk)
      QUALIFY row_number() OVER (PARTITION BY h.customer_hk ORDER BY s.load_ts DESC) = 1)
GROUP BY tier ORDER BY customers DESC;
EOF
code vault-sql vault.sql
block vault
on 'duckdb wh.duckdb < vault.sql'

put agg.sql <<'EOF'
-- A pre-summed table: revenue by month, shop and department.
CREATE TABLE agg_sales_month AS
SELECT d.year, d.month, f.shop_key, b.department,
       sum(f.quantity) AS books, sum(f.net_cents) AS net_cents
FROM fact_sales f
JOIN dim_date d USING (date_key)
JOIN dim_book b USING (book_key)
GROUP BY ALL;

SELECT (SELECT count(*) FROM fact_sales)      AS fact_rows,
       (SELECT count(*) FROM agg_sales_month) AS aggregate_rows,
       (SELECT sum(net_cents) FROM fact_sales)      AS fact_total,
       (SELECT sum(net_cents) FROM agg_sales_month) AS aggregate_total;
EOF
code agg-sql agg.sql
block agg
on 'duckdb wh.duckdb < agg.sql'

put correction.sql <<'EOF'
-- A correction reaches the fact table: one line of order 112406 was
-- registered at the wrong price, and is fixed.
UPDATE fact_sales SET net_cents = net_cents - 1000, gross_cents = gross_cents - 1000
WHERE order_id = 112406 AND line_no = 3;

SELECT (SELECT sum(net_cents) FROM fact_sales)      AS fact_total,
       (SELECT sum(net_cents) FROM agg_sales_month) AS aggregate_total;
EOF
code correction-sql correction.sql
block correction
on 'duckdb wh.duckdb < correction.sql'
