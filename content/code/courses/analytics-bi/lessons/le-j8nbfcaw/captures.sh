#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of analytics-bi, as a script that
# produces them.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the shop as lesson 1 leaves it: lantern.sql loaded, the two
# database settings applied, and the view order_totals, each taken out of
# lesson 1's .md files. The view order_revenue and the comment on it are taken
# out of this lesson's own .md files.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, machine clock UTC.
set -uo pipefail
cd "$(dirname "$0")"
export TZ=UTC LC_ALL=C.UTF-8
LAB_SH=../../lab.sh
FENCE=../../lab/fence.py
lab() { bash "$LAB_SH" "$@" 9>&-; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/abi-capture.lock; flock 9
. ../../lab/views.sh
views_up_to 1 >/dev/null 2>&1

block three
session lantern <<'SQL'
SELECT round(sum(gross_cents) / 100.0, 2) AS marketing,
       round(sum(gross_cents - gross_cents * discount_pct / 100) / 100.0, 2) AS ecommerce,
       round(sum(gross_cents - gross_cents * discount_pct / 100)
         FILTER (WHERE status = 'paid' AND customer_id <> 1) / 100.0, 2) AS finance
FROM order_totals
WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01';
SQL

block view
python3 "$FENCE" three-revenues.md 'CREATE VIEW order_revenue' | session lantern

block view-check
session lantern <<'SQL'
SELECT order_id, status, gross_cents, discount_cents, net_cents
FROM order_revenue WHERE order_id IN (5001, 5002, 5003);
SQL

block active
session lantern <<'SQL'
SELECT count(DISTINCT customer_id) FILTER (WHERE ordered_at >= date '2026-06-01' - 30) AS last_30_days,
       count(DISTINCT customer_id) FILTER (WHERE ordered_at >= date '2026-06-01' - 90) AS last_90_days,
       count(DISTINCT customer_id) AS ever_ordered
FROM orders
WHERE ordered_at < '2026-06-01' AND customer_id <> 1;
SQL

block gaps
session lantern <<'SQL'
SELECT percentile_cont(ARRAY[0.25, 0.5, 0.75]) WITHIN GROUP (ORDER BY gap) AS days_between_orders
FROM (SELECT ordered_at::date - lag(ordered_at::date) OVER (PARTITION BY customer_id ORDER BY ordered_at) AS gap
      FROM orders WHERE customer_id <> 1) AS g
WHERE gap IS NOT NULL;
SQL

block aov
session lantern <<'SQL'
SELECT round(sum(gross_cents) / count(*) / 100.0, 2) AS per_order
FROM order_totals WHERE customer_id <> 1;
SELECT round(avg(customer_avg) / 100.0, 2) AS per_customer
FROM (SELECT customer_id, avg(gross_cents) AS customer_avg
      FROM order_totals WHERE customer_id <> 1
      GROUP BY customer_id) AS c;
SQL

block days-sp
session lantern <<'SQL'
SELECT ordered_at::date AS day, to_char(ordered_at, 'Dy') AS name, count(*) AS orders
FROM orders WHERE ordered_at::date BETWEEN '2026-05-04' AND '2026-05-10'
GROUP BY 1, 2 ORDER BY 1;
SQL

block days-utc
session lantern <<'SQL'
SET timezone = 'UTC';
SELECT ordered_at::date AS day, to_char(ordered_at, 'Dy') AS name, count(*) AS orders
FROM orders WHERE ordered_at::date BETWEEN '2026-05-04' AND '2026-05-10'
GROUP BY 1, 2 ORDER BY 1;
SQL

block late
session lantern <<'SQL'
SELECT count(*) FILTER (WHERE extract(hour FROM ordered_at) >= 21) AS after_21h,
       count(*) AS orders
FROM orders;
SQL

block quarter-utc
session lantern <<'SQL'
SELECT current_setting('timezone') AS zone, count(*) AS orders,
       round(sum(gross_cents) / 100.0, 2) AS gross
FROM order_totals WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01';
SET timezone = 'UTC';
SELECT current_setting('timezone') AS zone, count(*) AS orders,
       round(sum(gross_cents) / 100.0, 2) AS gross
FROM order_totals WHERE ordered_at >= '2026-01-01' AND ordered_at < '2026-04-01';
SQL

block channels
session lantern <<'SQL'
SELECT channel, count(*) AS customers FROM customers GROUP BY 1 ORDER BY 1;
SELECT channel, count(*) AS sessions FROM web_sessions GROUP BY 1 ORDER BY 1;
SQL

block regions
python3 "$FENCE" dimensions.md 'SELECT CASE' | session lantern

block bridge
python3 "$FENCE" reconciling.md 'SELECT 1 AS step' | session lantern

block comment
python3 "$FENCE" the-definition.md 'COMMENT ON VIEW order_revenue' | session lantern

block comment-read
session lantern <<'SQL'
SELECT obj_description('order_revenue'::regclass) AS definition;
SQL
