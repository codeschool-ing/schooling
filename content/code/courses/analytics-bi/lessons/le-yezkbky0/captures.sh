#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of analytics-bi, as a script that
# produces them.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the shop and the semantic layer as lesson 3 leaves them, each
# taken out of the earlier lessons' .md files. The targets table is taken out
# of this lesson's targets-and-thresholds.md; its numbers are the business's
# inputs, invented for the course like every row of the shop.
#
# The dashboard itself is built in Metabase's browser screens, which the lesson
# describes; nothing here drives them. The SQL is what the dashboard's cards
# compute, run in psql.
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

block naked
session lantern <<'SQL'
SELECT sum(net_revenue) AS net_revenue_may
FROM semantic.orders
WHERE order_date >= '2026-05-01' AND order_date < '2026-06-01';
SQL

block context
session lantern <<'SQL'
SELECT sum(net_revenue) FILTER (WHERE order_date >= '2026-05-01' AND order_date < '2026-06-01') AS may_2026,
       sum(net_revenue) FILTER (WHERE order_date >= '2026-04-01' AND order_date < '2026-05-01') AS april_2026,
       sum(net_revenue) FILTER (WHERE order_date >= '2025-05-01' AND order_date < '2025-06-01') AS may_2025
FROM semantic.orders;
SQL

block lag
python3 "$FENCE" comparisons-in-sql.md 'WITH m AS' | session lantern

block days
session lantern <<'SQL'
SELECT k.day, to_char(k.day, 'Dy') AS name, count(o.order_id) AS orders
FROM semantic.calendar k LEFT JOIN semantic.orders o ON o.order_date = k.day
WHERE k.day IN ('2026-06-07', '2026-06-08', '2026-06-14', '2026-06-15')
GROUP BY k.day ORDER BY k.day;
SQL

block as-of
session lantern <<'SQL'
SELECT max(order_date) AS data_until FROM semantic.orders;
SQL

block mtd
python3 "$FENCE" the-partial-period.md 'SELECT sum(net_revenue) FILTER' | session lantern

block targets
python3 "$FENCE" targets-and-thresholds.md 'CREATE TABLE semantic.revenue_target' | session lantern

block attainment
python3 "$FENCE" targets-and-thresholds.md 'SELECT t.month' | session lantern

block breakdown
session lantern <<'SQL'
SELECT c.region, count(*) AS orders, sum(o.net_revenue) AS net_revenue
FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
WHERE o.order_date >= '2026-05-01' AND o.order_date < '2026-06-01'
GROUP BY c.region ORDER BY net_revenue DESC;
SQL

block north
session lantern <<'SQL'
SELECT to_char(date_trunc('month', o.order_date), 'YYYY-MM') AS month, count(*) AS orders,
       sum(o.net_revenue) AS net_revenue
FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
WHERE c.region = 'North' AND o.order_date >= '2026-01-01'
GROUP BY 1 ORDER BY 1;
SQL
