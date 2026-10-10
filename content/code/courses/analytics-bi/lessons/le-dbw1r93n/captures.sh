#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of analytics-bi, as a script that
# produces them.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the shop and the semantic layer as lesson 3 leaves them, the
# activation model of lesson 7 and the tracking plan of lesson 8, each taken
# out of those lessons' .md files.
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
python3 "$FENCE" ../le-qwjdspwn/tracking-check.md '-- tracking.sql' | lab exec 'psql -q lantern' >/dev/null 2>&1

block segments
session lantern <<'SQL'
SELECT health,
       CASE WHEN orders = 1 THEN '1 order'
            WHEN orders <= 3 THEN '2-3 orders'
            ELSE '4+ orders' END AS frequency,
       count(*) AS customers, sum(net_revenue) AS net_revenue
FROM activation.crm_contacts
WHERE orders > 0
GROUP BY 1, 2 ORDER BY 1, 2;
SQL

block ntile-ties
session lantern <<'SQL'
SELECT f, min(orders), max(orders), count(*) AS customers
FROM (SELECT orders, ntile(5) OVER (ORDER BY orders) AS f
      FROM activation.crm_contacts WHERE orders > 0) x
GROUP BY f ORDER BY f;
SQL

block holdout
session lantern <<'SQL'
SELECT CASE WHEN abs(hashtext(external_id)) % 5 = 0 THEN 'hold out' ELSE 'call' END AS arm,
       count(*) AS customers, round(avg(net_revenue), 2) AS avg_net_revenue,
       round(avg(orders), 2) AS avg_orders
FROM activation.crm_contacts
WHERE health = 'at risk' AND orders >= 4
GROUP BY 1 ORDER BY 1;
SQL

block cohort-sizes
session lantern <<'SQL'
SELECT date_trunc('month', first_order)::date AS cohort, count(*) AS customers
FROM (SELECT customer_id, min(order_date) AS first_order
      FROM semantic.orders WHERE status = 'paid' GROUP BY customer_id) f
GROUP BY 1 ORDER BY 1;
SQL

block cohort-naive
session lantern <<'SQL'
WITH paid AS (
  SELECT DISTINCT customer_id, date_trunc('month', order_date)::date AS month
  FROM semantic.orders WHERE status = 'paid'),
cohort AS (SELECT customer_id, min(month) AS cohort FROM paid GROUP BY customer_id),
activity AS (
  SELECT c.cohort, p.customer_id,
         (12 * (extract(year FROM p.month) - extract(year FROM c.cohort))
          + extract(month FROM p.month) - extract(month FROM c.cohort))::int AS k
  FROM paid p JOIN cohort c USING (customer_id))
SELECT cohort, count(*) FILTER (WHERE k = 0) AS size,
       round(100.0 * count(*) FILTER (WHERE k = 1) / count(*) FILTER (WHERE k = 0), 1) AS m1,
       round(100.0 * count(*) FILTER (WHERE k = 2) / count(*) FILTER (WHERE k = 0), 1) AS m2,
       round(100.0 * count(*) FILTER (WHERE k = 3) / count(*) FILTER (WHERE k = 0), 1) AS m3,
       round(100.0 * count(*) FILTER (WHERE k = 6) / count(*) FILTER (WHERE k = 0), 1) AS m6
FROM activity
WHERE cohort >= '2025-10-01'
GROUP BY cohort ORDER BY cohort;
SQL

block cohort-censored
session lantern <<'SQL'
WITH paid AS (
  SELECT DISTINCT customer_id, date_trunc('month', order_date)::date AS month
  FROM semantic.orders WHERE status = 'paid'),
cohort AS (SELECT customer_id, min(month) AS cohort FROM paid GROUP BY customer_id),
activity AS (
  SELECT c.cohort, p.customer_id,
         (12 * (extract(year FROM p.month) - extract(year FROM c.cohort))
          + extract(month FROM p.month) - extract(month FROM c.cohort))::int AS k
  FROM paid p JOIN cohort c USING (customer_id)),
open_month AS (SELECT date_trunc('month', max(order_date))::date AS m FROM semantic.orders)
SELECT cohort, count(*) FILTER (WHERE k = 0) AS size,
       CASE WHEN cohort + interval '1 month' < m THEN
         round(100.0 * count(*) FILTER (WHERE k = 1) / count(*) FILTER (WHERE k = 0), 1) END AS m1,
       CASE WHEN cohort + interval '2 months' < m THEN
         round(100.0 * count(*) FILTER (WHERE k = 2) / count(*) FILTER (WHERE k = 0), 1) END AS m2,
       CASE WHEN cohort + interval '3 months' < m THEN
         round(100.0 * count(*) FILTER (WHERE k = 3) / count(*) FILTER (WHERE k = 0), 1) END AS m3,
       CASE WHEN cohort + interval '6 months' < m THEN
         round(100.0 * count(*) FILTER (WHERE k = 6) / count(*) FILTER (WHERE k = 0), 1) END AS m6
FROM activity CROSS JOIN open_month
WHERE cohort >= '2025-10-01'
GROUP BY cohort, m ORDER BY cohort;
SQL

block cohort-channel
session lantern <<'SQL'
WITH first AS (
  SELECT customer_id, min(order_date) AS first_order
  FROM semantic.orders WHERE status = 'paid' GROUP BY customer_id)
SELECT date_trunc('month', f.first_order) = '2025-11-01' AS november,
       c.acquisition_channel, count(*) AS customers,
       round(100.0 * count(*) FILTER (WHERE EXISTS (
         SELECT 1 FROM semantic.orders o
         WHERE o.customer_id = f.customer_id AND o.status = 'paid'
           AND o.order_date > f.first_order AND o.order_date <= f.first_order + 90))
         / count(*), 1) AS again_within_90_days
FROM first f JOIN semantic.customers c USING (customer_id)
WHERE f.first_order < '2026-03-01'
GROUP BY 1, 2 ORDER BY 1, 2;
SQL

block funnel-device
session lantern <<'SQL'
SELECT step, event,
       desktop, round(100.0 * desktop / lag(desktop) OVER (ORDER BY step), 1) AS desktop_pct,
       mobile, round(100.0 * mobile / lag(mobile) OVER (ORDER BY step), 1) AS mobile_pct
FROM (SELECT p.step, p.event,
             count(*) FILTER (WHERE s.device = 'desktop') AS desktop,
             count(*) FILTER (WHERE s.device = 'mobile') AS mobile
      FROM tracking.plan p JOIN shop.web_sessions s ON s.steps >= p.step
      GROUP BY p.step, p.event) f
ORDER BY step;
SQL

block checkout-step
session lantern <<'SQL'
SELECT extract(year FROM started_at)::int AS year, device,
       count(*) FILTER (WHERE steps >= 4) AS checkouts,
       round(100.0 * count(*) FILTER (WHERE steps >= 5)
             / count(*) FILTER (WHERE steps >= 4), 1) AS checkout_to_purchase
FROM shop.web_sessions
GROUP BY 1, 2 ORDER BY 1, 2;
SQL
