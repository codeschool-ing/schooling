#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of analytics-bi, as a script that
# produces them.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the shop and the semantic layer as lesson 3 leaves them, and
# the activation model as lesson 7 leaves it, each taken out of the earlier
# lessons' .md files.
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
views_up_to 3 >/dev/null 2>&1
python3 "$FENCE" ../le-zpnh1qs0/the-model.md '-- activation.sql' | lab exec 'psql -q lantern' >/dev/null 2>&1

block monthly
session lantern <<'SQL'
SELECT date_trunc('month', order_date)::date AS month, sum(net_revenue) AS net_revenue
FROM semantic.orders
WHERE order_date >= '2026-01-01' AND order_date < '2026-06-01'
GROUP BY 1 ORDER BY 1;
SQL

block conversion-years
session lantern <<'SQL'
SELECT extract(year FROM started_at)::int AS year, count(*) AS sessions,
       count(*) FILTER (WHERE steps >= 5) AS purchases,
       round(100.0 * count(*) FILTER (WHERE steps >= 5) / count(*), 2) AS conversion_pct
FROM shop.web_sessions
GROUP BY 1 ORDER BY 1;
SQL

block refunds-region
session lantern <<'SQL'
SELECT c.region, count(*) AS orders,
       count(*) FILTER (WHERE o.status = 'refunded') AS refunded,
       round(100.0 * count(*) FILTER (WHERE o.status = 'refunded') / count(*), 1) AS refund_pct
FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
GROUP BY 1 ORDER BY 2 DESC;
SQL

block windows
session lantern <<'SQL'
WITH m AS (
  SELECT date_trunc('month', order_date)::date AS month, sum(net_revenue) AS net_revenue
  FROM semantic.orders GROUP BY 1)
SELECT b.month AS compared_with, b.net_revenue AS then,
       may.net_revenue AS may_2026,
       round(100.0 * (may.net_revenue - b.net_revenue) / b.net_revenue, 1) AS change_pct
FROM m b, m may
WHERE may.month = '2026-05-01'
  AND b.month IN ('2025-05-01', '2025-11-01', '2026-04-01')
ORDER BY b.month;
SQL

block shares
session lantern <<'SQL'
SELECT extract(year FROM started_at)::int AS year, device, count(*) AS sessions,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY extract(year FROM started_at)), 1) AS share_pct
FROM shop.web_sessions
GROUP BY extract(year FROM started_at), device ORDER BY 1, 2;
SQL

block simpson
session lantern <<'SQL'
SELECT extract(year FROM started_at)::int AS year,
       coalesce(device, 'all') AS device,
       count(*) AS sessions,
       round(100.0 * count(*) FILTER (WHERE steps >= 5) / count(*), 2) AS conversion_pct
FROM shop.web_sessions
GROUP BY 1, ROLLUP (device) ORDER BY 1, 2;
SQL

block mix
session lantern <<'SQL'
WITH r AS (
  SELECT year, device, count(*)::numeric AS sessions,
         count(*) FILTER (WHERE steps >= 5) / count(*)::numeric AS rate
  FROM (SELECT extract(year FROM started_at)::int AS year, device, steps
        FROM shop.web_sessions) s
  GROUP BY 1, 2),
w AS (SELECT year, device, sessions / sum(sessions) OVER (PARTITION BY year) AS share FROM r)
SELECT 'mix of ' || w.year AS weights,
       round(100 * sum(w.share * r.rate) FILTER (WHERE r.year = 2025), 2) AS rates_of_2025,
       round(100 * sum(w.share * r.rate) FILTER (WHERE r.year = 2026), 2) AS rates_of_2026
FROM w JOIN r USING (device)
GROUP BY w.year ORDER BY w.year;
SQL

block survivors
session lantern <<'SQL'
WITH c AS (
  SELECT customer_id, min(order_date) AS first_order, max(order_date) AS last_order,
         count(*) FILTER (WHERE status = 'paid') AS paid_orders
  FROM semantic.orders GROUP BY customer_id),
asof AS (SELECT max(order_date) AS day FROM semantic.orders)
SELECT last_order >= asof.day - 45 AS still_active,
       count(*) AS customers, round(avg(paid_orders), 2) AS avg_paid_orders
FROM c, asof
WHERE first_order < '2025-04-01'
GROUP BY 1 ORDER BY 1;
SQL

block discount-naive
session lantern <<'SQL'
SELECT discount > 0 AS discounted, count(*) AS orders, round(avg(gross), 2) AS avg_gross
FROM semantic.orders WHERE status = 'paid'
GROUP BY 1 ORDER BY 1;
SQL

block discount-segment
session lantern <<'SQL'
SELECT c.segment, o.discount > 0 AS discounted, count(*) AS orders,
       round(avg(o.gross), 2) AS avg_gross
FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
WHERE o.status = 'paid'
GROUP BY 1, 2 ORDER BY 1, 2;
SQL
