#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of warehouse-modeling, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: ~/wh/wh.duckdb, the warehouse lessons 2
# to 5 build, made here by `lab.sh warehouse`. The snowflaked tables of this
# lesson are built on top of it by the files `put` writes, which the lesson
# shows as they are.
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

put star-query.sql <<'EOF'
-- Revenue in 2025 by region and department, weekends only, physical shops.
SELECT s.region, b.department, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_date d USING (date_key)
JOIN dim_shop s USING (shop_key)
JOIN dim_book b USING (book_key)
WHERE d.year = 2025 AND d.is_weekend AND s.channel = 'store'
GROUP BY ALL
ORDER BY s.region, revenue_brl DESC;
EOF
code star-query-sql star-query.sql
block star-query
on 'duckdb wh.duckdb < star-query.sql'

put snowflake.sql <<'EOF'
-- The book dimension, normalised: every level of the category tree and the
-- publisher get a table of their own, and each row points at the one above.
CREATE TABLE sf_department AS
SELECT row_number() OVER (ORDER BY name) AS department_key, name AS department
FROM staging.categories WHERE parent_id IS NULL;

CREATE TABLE sf_subcategory AS
SELECT row_number() OVER (ORDER BY c.name) AS subcategory_key, c.name AS subcategory,
       d.department_key
FROM staging.categories c
JOIN staging.categories p ON p.category_id = c.parent_id
JOIN sf_department d      ON d.department = p.name
WHERE p.parent_id IS NULL;

CREATE TABLE sf_category AS
SELECT row_number() OVER (ORDER BY b.category) AS category_key, b.category, s.subcategory_key
FROM (SELECT DISTINCT category, subcategory FROM dim_book) b
JOIN sf_subcategory s USING (subcategory);

CREATE TABLE sf_publisher AS
SELECT row_number() OVER (ORDER BY publisher) AS publisher_key, publisher
FROM (SELECT DISTINCT publisher FROM dim_book);

CREATE TABLE sf_book AS
SELECT b.book_key, b.book_id, b.isbn, b.title, b.authors, b.format,
       c.category_key, p.publisher_key, b.published_on
FROM dim_book b
JOIN sf_category c  USING (category)
JOIN sf_publisher p USING (publisher);
EOF
code snowflake-sql snowflake.sql
block snowflake
on 'duckdb wh.duckdb < snowflake.sql'
on "duckdb wh.duckdb -c \"SELECT table_name, estimated_size AS rows, column_count AS columns FROM duckdb_tables() WHERE table_name LIKE 'sf_%' OR table_name = 'dim_book' ORDER BY rows\""

put snow-query.sql <<'EOF'
-- The same question, against the snowflake.
SELECT s.region, dep.department, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_date d         USING (date_key)
JOIN dim_shop s         USING (shop_key)
JOIN sf_book b          USING (book_key)
JOIN sf_category c      USING (category_key)
JOIN sf_subcategory sub USING (subcategory_key)
JOIN sf_department dep  USING (department_key)
WHERE d.year = 2025 AND d.is_weekend AND s.channel = 'store'
GROUP BY ALL
ORDER BY s.region, revenue_brl DESC;
EOF
code snow-query-sql snow-query.sql
block snow-query
on 'duckdb wh.duckdb < snow-query.sql'

block joins
on "{ echo 'EXPLAIN (FORMAT json)'; cat star-query.sql; } | duckdb -list wh.duckdb | grep -o HASH_JOIN | wc -l"
on "{ echo 'EXPLAIN (FORMAT json)'; cat snow-query.sql; } | duckdb -list wh.duckdb | grep -o HASH_JOIN | wc -l"

put repeated.sql <<'EOF'
-- What the star repeats, in bytes of text, against the size of the fact table.
SELECT sum(strlen(category) + strlen(subcategory) + strlen(department) + strlen(publisher))
           AS repeated_text_bytes,
       (SELECT count(*) FROM fact_sales) AS fact_rows
FROM dim_book;
EOF
code repeated-sql repeated.sql
block repeated
on 'duckdb wh.duckdb < repeated.sql'
on 'ls -l wh.duckdb'

put tree.sql <<'EOF'
-- Walk the category tree from each top-level node down, and print the path.
WITH RECURSIVE tree AS (
    SELECT category_id, name, name AS path, 1 AS depth
    FROM staging.categories WHERE parent_id IS NULL
    UNION ALL
    SELECT c.category_id, c.name, t.path || ' > ' || c.name, t.depth + 1
    FROM staging.categories c JOIN tree t ON c.parent_id = t.category_id
)
SELECT depth, count(*) AS nodes, min(path) AS example
FROM tree GROUP BY depth ORDER BY depth;
EOF
code tree-sql tree.sql
block tree
on 'duckdb wh.duckdb < tree.sql'

block leaves
on "duckdb wh.duckdb -c \"SELECT department, subcategory, category FROM dim_book WHERE department IN ('Comics', 'Fiction') GROUP BY ALL ORDER BY ALL LIMIT 6\""

put drill-across.sql <<'EOF'
-- Two fact tables, one conformed shop dimension: December 2025 sales against
-- the stock counted at the end of that month.
WITH sold AS (
    SELECT f.shop_key, sum(f.quantity) AS books_sold
    FROM fact_sales f JOIN dim_date d USING (date_key)
    WHERE d.year = 2025 AND d.month = 12
    GROUP BY f.shop_key
),
counted AS (
    SELECT i.shop_key, sum(i.on_hand) AS books_on_shelf
    FROM fact_inventory i
    WHERE i.date_key = 20251231
    GROUP BY i.shop_key
)
SELECT s.shop_name, sold.books_sold, counted.books_on_shelf,
       round(counted.books_on_shelf / sold.books_sold, 1) AS months_of_stock
FROM sold
JOIN counted USING (shop_key)
JOIN dim_shop s USING (shop_key)
ORDER BY months_of_stock;
EOF
code drill-across-sql drill-across.sql
block drill-across
on 'duckdb wh.duckdb < drill-across.sql'

put roles.sql <<'EOF'
-- One date dimension, two roles: the day an order was placed, and the day it left.
CREATE VIEW dim_order_date AS SELECT * FROM dim_date;
CREATE VIEW dim_ship_date  AS SELECT * FROM dim_date;

SELECT od.day_name AS ordered_on, sd.day_name AS shipped_on, count(*) AS orders
FROM fact_fulfilment f
JOIN dim_order_date od ON od.date_key = f.ordered_date_key
JOIN dim_ship_date  sd ON sd.date_key = f.shipped_date_key
WHERE od.day_of_week = 5
GROUP BY ALL ORDER BY orders DESC;
EOF
code roles-sql roles.sql
block roles
on 'duckdb wh.duckdb < roles.sql'

block profiles
on "duckdb wh.duckdb -c \"SELECT count(*) AS payments, count(DISTINCT method) AS methods, count(DISTINCT installments) AS installment_counts, count(DISTINCT (method, installments)) AS combinations FROM fact_payments\""

put junk.sql <<'EOF'
-- A junk dimension: every combination of the payment's small flags that
-- actually occurs, once, with a key.
CREATE TABLE dim_payment_profile AS
SELECT row_number() OVER (ORDER BY method, installments) AS payment_profile_key,
       method, installments,
       CASE WHEN installments = 1 THEN 'paid at once' ELSE 'in instalments' END AS terms
FROM (SELECT DISTINCT method, installments FROM fact_payments);

SELECT * FROM dim_payment_profile;
EOF
code junk-sql junk.sql
block junk
on 'duckdb wh.duckdb < junk.sql'
