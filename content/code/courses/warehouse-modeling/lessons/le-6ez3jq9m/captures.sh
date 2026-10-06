#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of warehouse-modeling, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: ~/wh/wh.duckdb, the warehouse lessons 2
# to 5 build, made here by `lab.sh warehouse`, and the three monthly customer
# extracts in ~/wh/extracts, which lab.sh copies there from the generated
# files. Each extract is the customer table as the shop's database held it at
# midnight on the first of a month. The tables this lesson builds beside the
# warehouse's own dim_customer are made by the files `put` writes, which the
# lesson shows as they are.
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

block history
on "duckdb wh.duckdb -c \"SELECT changed_at, field, old_value, new_value FROM staging.customer_changes WHERE customer_id = 1 ORDER BY changed_at\""

put type0.sql <<'EOF'
-- Type 0: attributes written once, when the customer joined, and never changed.
CREATE TABLE customer_origin AS
SELECT customer_id,
       CAST(valid_from AS DATE) AS joined_on,
       state                    AS state_when_joined
FROM dim_customer
WHERE customer_key > 0
QUALIFY row_number() OVER (PARTITION BY customer_id ORDER BY valid_from) = 1;

SELECT count(*) AS customers,
       count(*) FILTER (WHERE o.state_when_joined <> c.state) AS live_elsewhere_now
FROM customer_origin o
JOIN staging.customers c USING (customer_id);
EOF
code type0-sql type0.sql
block type0
on 'duckdb wh.duckdb < type0.sql'

put type1.sql <<'EOF'
-- Type 1: one row per customer, overwritten with whatever the extract says.
CREATE OR REPLACE TABLE dim_customer_t1 AS
SELECT customer_id, name, tier, city, state
FROM read_csv('extracts/customers_' || getvariable('extract_date') || '.csv');

SELECT c.state, round(sum(f.net_cents) / 100, 2) AS sold_in_2024_brl
FROM fact_sales f
JOIN dim_customer d     ON d.customer_key = f.customer_key
JOIN dim_customer_t1 c  ON c.customer_id = d.customer_id
JOIN dim_date dt        ON dt.date_key = f.date_key
WHERE dt.year = 2024 AND c.state IN ('MG', 'PR')
GROUP BY ALL ORDER BY c.state;
EOF
code type1-sql type1.sql
block type1
on "duckdb wh.duckdb -cmd \"SET VARIABLE extract_date = DATE '2025-10-01'\" < type1.sql"
on "duckdb wh.duckdb -cmd \"SET VARIABLE extract_date = DATE '2025-12-01'\" < type1.sql"

put by-state-2024.sql <<'EOF'
-- The same question, against the type 2 dimension.
SELECT d.state, round(sum(f.net_cents) / 100, 2) AS sold_in_2024_brl
FROM fact_sales f
JOIN dim_customer d USING (customer_key)
JOIN dim_date dt    USING (date_key)
WHERE dt.year = 2024 AND d.state IN ('MG', 'PR')
GROUP BY ALL ORDER BY d.state;
EOF
code by-state-2024-sql by-state-2024.sql
block by-state-2024
on 'duckdb wh.duckdb < by-state-2024.sql'

block customer-1
on "duckdb wh.duckdb -c \"SELECT customer_key, tier, city, valid_from, valid_to, is_current FROM dim_customer WHERE customer_id = 1 ORDER BY valid_from\""

block versions
on "duckdb wh.duckdb -c \"SELECT versions, count(*) AS customers FROM (SELECT customer_id, count(*) AS versions FROM dim_customer WHERE customer_key > 0 GROUP BY customer_id) GROUP BY versions ORDER BY versions\""

put by-tier.sql <<'EOF'
-- Revenue of 2025 by loyalty tier: the tier the customer had when they
-- bought, against the tier they have now.
SELECT d.tier AS tier_at_sale, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_customer d USING (customer_key)
JOIN dim_date dt    USING (date_key)
WHERE dt.year = 2025 AND d.customer_key > 0
GROUP BY ALL ORDER BY revenue_brl DESC;

SELECT now.tier AS tier_today, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_customer d   USING (customer_key)
JOIN dim_customer now ON now.customer_id = d.customer_id AND now.is_current
JOIN dim_date dt      USING (date_key)
WHERE dt.year = 2025 AND d.customer_key > 0
GROUP BY ALL ORDER BY revenue_brl DESC;
EOF
code by-tier-sql by-tier.sql
block by-tier
on 'duckdb wh.duckdb < by-tier.sql'

put first_load.sql <<'EOF'
-- A type 2 customer dimension loaded from monthly extracts. The first month:
-- one current version of everybody, from the day of the extract.
CREATE SEQUENCE customer_key_seq START 1;
CREATE TABLE dim_customer_m (
    customer_key BIGINT PRIMARY KEY,
    customer_id  BIGINT NOT NULL,
    name         VARCHAR,
    tier         VARCHAR,
    city         VARCHAR,
    state        VARCHAR,
    valid_from   DATE NOT NULL,
    valid_to     DATE NOT NULL,
    is_current   BOOLEAN NOT NULL
);
INSERT INTO dim_customer_m
SELECT nextval('customer_key_seq'), customer_id, name, tier, city, state,
       DATE '2025-10-01', DATE '9999-12-31', true
FROM read_csv('extracts/customers_2025-10-01.csv');
EOF
code first-load-sql first_load.sql

put load_month.sql <<'EOF'
-- Load one month's extract into the type 2 dimension. Run with the extract's
-- date in the variable load_date.
BEGIN;
CREATE OR REPLACE TEMP TABLE ext AS
SELECT * FROM read_csv('extracts/customers_' || getvariable('load_date') || '.csv');

-- 1. Type 1: a corrected name is written into every version of the customer.
UPDATE dim_customer_m d SET name = e.name
FROM ext e
WHERE d.customer_id = e.customer_id AND d.name <> e.name;

-- 2. Close the current version of everybody whose tracked attributes changed.
UPDATE dim_customer_m d SET valid_to = getvariable('load_date'), is_current = false
FROM ext e
WHERE d.customer_id = e.customer_id AND d.is_current
  AND (d.tier, d.city, d.state) IS DISTINCT FROM (e.tier, e.city, e.state);

-- 3. Open a version for everybody who now has no current row: the ones just
--    closed, and customers who joined during the month.
INSERT INTO dim_customer_m
SELECT nextval('customer_key_seq'), e.customer_id, e.name, e.tier, e.city, e.state,
       getvariable('load_date'), DATE '9999-12-31', true
FROM ext e
WHERE NOT EXISTS (SELECT 1 FROM dim_customer_m d
                  WHERE d.customer_id = e.customer_id AND d.is_current);
COMMIT;

SELECT count(*) AS rows, count(*) FILTER (WHERE is_current) AS current,
       count(*) FILTER (WHERE valid_to = getvariable('load_date')) AS closed_now,
       count(*) FILTER (WHERE valid_from = getvariable('load_date')) AS opened_now
FROM dim_customer_m;
EOF
code load-month-sql load_month.sql
block loads
on 'duckdb wh.duckdb < first_load.sql'
on "duckdb wh.duckdb -cmd \"SET VARIABLE load_date = DATE '2025-11-01'\" < load_month.sql"
on "duckdb wh.duckdb -cmd \"SET VARIABLE load_date = DATE '2025-12-01'\" < load_month.sql"

block rerun
on "duckdb wh.duckdb -cmd \"SET VARIABLE load_date = DATE '2025-12-01'\" < load_month.sql"

block month-gap
on "duckdb wh.duckdb -c \"SELECT customer_id, changed_at, field, old_value, new_value FROM staging.customer_changes WHERE customer_id IN (SELECT customer_id FROM staging.customer_changes WHERE field IN ('tier', 'city', 'state') AND changed_at >= '2025-11-01' AND changed_at < '2025-12-01' GROUP BY customer_id HAVING count(DISTINCT changed_at) > 1) ORDER BY changed_at\""

put type3.sql <<'EOF'
-- Type 3: one extra column holding the value before the latest change.
CREATE TABLE dim_customer_t3 AS
SELECT c.customer_id, c.city,
       (SELECT old_value FROM staging.customer_changes x
         WHERE x.customer_id = c.customer_id AND x.field = 'city'
         ORDER BY x.changed_at DESC LIMIT 1) AS previous_city
FROM staging.customers c;

SELECT * FROM dim_customer_t3 WHERE customer_id IN (1, 2123) ORDER BY customer_id;
EOF
code type3-sql type3.sql
block type3
on 'duckdb wh.duckdb < type3.sql'

put type6.sql <<'EOF'
-- Type 6: type 2 rows, each also carrying the customer's current tier.
CREATE TABLE dim_customer_t6 AS
SELECT d.*, now.tier AS current_tier
FROM dim_customer d
LEFT JOIN dim_customer now ON now.customer_id = d.customer_id AND now.is_current;

SELECT d.tier AS tier_at_sale, d.current_tier, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_customer_t6 d USING (customer_key)
JOIN dim_date dt       USING (date_key)
WHERE dt.year = 2025 AND d.tier = 'reader'
GROUP BY ALL ORDER BY revenue_brl DESC;
EOF
code type6-sql type6.sql
block type6
on 'duckdb wh.duckdb < type6.sql'

put checks.sql <<'EOF'
-- Three things every type 2 dimension must satisfy, checked.
SELECT
  (SELECT count(*) FROM (SELECT customer_id FROM dim_customer WHERE is_current
                         GROUP BY customer_id HAVING count(*) <> 1))       AS not_one_current,
  (SELECT count(*) FROM dim_customer a JOIN dim_customer b
     ON a.customer_id = b.customer_id AND a.customer_key < b.customer_key
    AND a.valid_from < b.valid_to AND b.valid_from < a.valid_to)            AS overlapping_pairs,
  (SELECT count(*) FROM (SELECT valid_to, lead(valid_from) OVER
                           (PARTITION BY customer_id ORDER BY valid_from) AS next_from
                         FROM dim_customer WHERE customer_key > 0)
    WHERE next_from IS NOT NULL AND next_from <> valid_to)                AS gaps;
EOF
code checks-sql checks.sql
block checks
on 'duckdb wh.duckdb < checks.sql'
