#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of warehouse-modeling, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: ~/wh/wh.duckdb and ~/wh/extract, the
# warehouse and the extract of lessons 2 to 5, made here by `lab.sh
# warehouse`. The two marts are written here, in this script, and shown in the
# lesson as they are. The finance team and the marketing team are people in
# the lesson's story; both of their marts were written by the same hand as the
# rest of the lab, to show what two separate teams' definitions do.
# The metadata and the contract are the course's own files, in lab/meta/,
# copied into ~/wh by `put`.
#
# Recorded on Ubuntu 24.04, DuckDB 1.5.6, Python 3.12 with the duckdb module
# 1.5.6, TZ=America/Sao_Paulo, on 2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
COURSE=$(cd "$(dirname "$LAB_SH")" && pwd)
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/wh$ %s\n' "$*"; timeout 120 bash "$LAB_SH" exec "$*" 2>&1 || true; }
put() { lab exec "cat > '$1'"; }
code() { printf '##### %s\n' "$1"; lab exec "cat '$2'"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/wh-capture.lock; flock 9
lab reset >/dev/null
lab warehouse >/dev/null
for f in sources.json gen_staging.py fact_sales.contract.json check_contract.py; do
  put $f < "$COURSE/lab/meta/$f"
done

put mart_sales.sql <<'SQL'
-- The sales team's mart: views over the warehouse's star, nothing copied.
CREATE SCHEMA mart_sales;
CREATE VIEW mart_sales.monthly AS
SELECT d.year, d.month, s.shop_name,
       count(DISTINCT f.order_id) AS orders,
       sum(f.net_cents)           AS net_cents
FROM fact_sales f
JOIN dim_date d USING (date_key)
JOIN dim_shop s USING (shop_key)
GROUP BY ALL;
SQL
code mart-sales-sql mart_sales.sql
block mart
on 'duckdb wh.duckdb < mart_sales.sql'
on "duckdb wh.duckdb -c \"SELECT shop_name, orders, net_cents FROM mart_sales.monthly WHERE year = 2025 AND month = 12 ORDER BY net_cents DESC\""
on "duckdb wh.duckdb -c \"SELECT sum(net_cents) AS december FROM mart_sales.monthly WHERE year = 2025 AND month = 12\""

put mart_finance.sql <<'SQL'
-- Finance's mart, built by another team straight from the extract:
-- the money customers paid, by the day of the order.
SET TimeZone = 'America/Sao_Paulo';
CREATE SCHEMA mart_finance;
CREATE TABLE mart_finance.receipts AS
SELECT CAST(o.ordered_at AS DATE) AS day, o.shop_id,
       sum(p.amount_cents) AS amount_cents
FROM read_csv('extract/payments.csv') p
JOIN read_csv('extract/orders.csv') o USING (order_id)
GROUP BY ALL;
SQL
put mart_marketing.sql <<'SQL'
-- Marketing's mart, a third team's: payments by the day they were made.
SET TimeZone = 'America/Sao_Paulo';
CREATE SCHEMA mart_marketing;
CREATE TABLE mart_marketing.revenue AS
SELECT CAST(o.paid_at AS DATE) AS day,
       sum(p.amount_cents) AS revenue_cents
FROM read_csv('extract/payments.csv') p
JOIN read_csv('extract/orders.csv') o USING (order_id)
GROUP BY ALL;
SQL
code mart-finance-sql mart_finance.sql
code mart-marketing-sql mart_marketing.sql
block disagree
on 'duckdb wh.duckdb < mart_finance.sql && duckdb wh.duckdb < mart_marketing.sql'
on "duckdb wh.duckdb -c \"SELECT 'sales' AS mart, sum(net_cents) AS december FROM mart_sales.monthly WHERE year = 2025 AND month = 12
UNION ALL SELECT 'finance', sum(amount_cents) FROM mart_finance.receipts WHERE day BETWEEN '2025-12-01' AND '2025-12-31'
UNION ALL SELECT 'marketing', sum(revenue_cents) FROM mart_marketing.revenue WHERE day BETWEEN '2025-12-01' AND '2025-12-31'\""

put reconcile.sql <<'SQL'
-- Where do finance and sales part company? Shipping is the obvious suspect.
SET TimeZone = 'America/Sao_Paulo';
SELECT sum(shipping_cents) AS shipping,
       count(*) FILTER (WHERE paid_at IS NULL) AS orders_never_paid_online,
       count(*) FILTER (WHERE paid_at IS NULL AND status = 'completed') AS of_which_in_a_shop
FROM read_csv('extract/orders.csv')
WHERE CAST(ordered_at AS DATE) BETWEEN '2025-12-01' AND '2025-12-31'
  AND status <> 'cancelled';
SQL
code reconcile-sql reconcile.sql
block reconcile
on 'duckdb wh.duckdb < reconcile.sql'
on "duckdb wh.duckdb -c \"SELECT 773739182 - 755814482 AS finance_minus_sales\""

put bus.sql <<'SQL'
-- The bus matrix, read off the warehouse itself: one row per fact table,
-- an x wherever it carries a dimension's key.
SELECT table_name AS process,
       CASE WHEN bool_or(column_name LIKE '%date_key') THEN 'x' ELSE '' END AS "date",
       CASE WHEN bool_or(column_name = 'shop_key')      THEN 'x' ELSE '' END AS shop,
       CASE WHEN bool_or(column_name = 'book_key')      THEN 'x' ELSE '' END AS book,
       CASE WHEN bool_or(column_name = 'customer_key')  THEN 'x' ELSE '' END AS customer,
       CASE WHEN bool_or(column_name = 'promotion_key') THEN 'x' ELSE '' END AS promotion,
       CASE WHEN bool_or(column_name = 'author_key')    THEN 'x' ELSE '' END AS author
FROM duckdb_columns()
WHERE schema_name = 'main' AND table_name LIKE 'fact\_%' ESCAPE '\'
GROUP BY table_name
ORDER BY table_name;
SQL
code bus-sql bus.sql
block bus
on 'duckdb -readonly wh.duckdb < bus.sql'

code contract-json fact_sales.contract.json
code check-py check_contract.py
block contract
on 'python3 check_contract.py fact_sales.contract.json; echo "exit status $?"'
on "duckdb wh.duckdb -c \"ALTER TABLE fact_sales RENAME COLUMN discount_cents TO discount\""
on 'python3 check_contract.py fact_sales.contract.json; echo "exit status $?"'

code sources-json sources.json
code gen-py gen_staging.py
block generate
on 'python3 gen_staging.py sources.json > staging.sql && wc -l staging.sql && sed -n 1,3p staging.sql && grep books staging.sql'
on 'duckdb fresh.duckdb < staging.sql'
put compare.sql <<'SQL'
-- Every staging column, by hand against generated, both ways round.
ATTACH 'wh.duckdb' AS hand (READ_ONLY);
ATTACH 'fresh.duckdb' AS generated (READ_ONLY);
WITH h AS (SELECT table_name, column_name, data_type FROM duckdb_columns()
           WHERE database_name = 'hand' AND schema_name = 'staging'),
     g AS (SELECT table_name, column_name, data_type FROM duckdb_columns()
           WHERE database_name = 'generated' AND schema_name = 'staging')
SELECT (SELECT count(*) FROM h) AS hand_columns,
       (SELECT count(*) FROM g) AS generated_columns,
       (SELECT count(*) FROM (FROM h EXCEPT FROM g)) AS only_by_hand,
       (SELECT count(*) FROM (FROM g EXCEPT FROM h)) AS only_generated;
SQL
code compare-sql compare.sql
on 'duckdb < compare.sql'
