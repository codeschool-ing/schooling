#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of analytics-bi, as a script that
# produces them.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the shop and the semantic layer as lesson 3 leaves them, each
# taken out of the earlier lessons' .md files.
#
# WHAT IS NOT HERE: Power BI. Power BI Desktop runs only on Windows and the lab
# is Ubuntu, so no DAX in this lesson was run, and the lesson says so beside
# each formula. Every number the lesson quotes comes from the SQL below, which
# computes what each measure is defined to compute. The `scp` line that copies
# the CSV files to a Windows computer was not run either (there is no Windows
# computer at the other end); the export itself was.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, machine clock UTC.
set -uo pipefail
cd "$(dirname "$0")"
export TZ=UTC LC_ALL=C.UTF-8
LAB_SH=../../lab.sh
FENCE=../../lab/fence.py
lab() { bash "$LAB_SH" "$@" 9>&-; }
on() { printf 'ana@vm:~$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/abi-capture.lock; flock 9
. ../../lab/views.sh
lab exec "psql -qX lantern -c 'DROP OWNED BY south_manager' -c 'DROP ROLE IF EXISTS south_manager'" >/dev/null 2>&1
views_up_to 3 >/dev/null 2>&1
lab exec 'rm -rf ~/powerbi'

block export
lab exec 'mkdir -p ~/powerbi'
python3 "$FENCE" import-and-transform.md '\copy (SELECT * FROM semantic.orders)' > /tmp/abi-export.sql
chmod 644 /tmp/abi-export.sql
printf 'ana@vm:~$ cd powerbi\n'
printf 'ana@vm:~/powerbi$ psql lantern -f export.sql\n'
lab exec 'cd ~/powerbi && cp /tmp/abi-export.sql export.sql && psql lantern -f export.sql' 2>&1
block files
printf 'ana@vm:~/powerbi$ wc -l *.csv\n'; lab exec 'cd ~/powerbi && wc -l *.csv'
printf 'ana@vm:~/powerbi$ head -n 3 orders.csv\n'; lab exec 'cd ~/powerbi && head -n 3 orders.csv'

block matrix
session lantern <<'SQL'
SELECT c.region, sum(o.net_revenue) AS net_revenue
FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
WHERE o.order_date >= '2026-01-01'
GROUP BY ROLLUP (c.region)
ORDER BY c.region NULLS LAST;
SQL

block share
session lantern <<'SQL'
SELECT c.region,
       round(100 * sum(o.net_revenue) / sum(sum(o.net_revenue)) OVER (), 1) AS share_pct
FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
WHERE o.order_date >= '2026-01-01'
GROUP BY c.region ORDER BY share_pct DESC;
SQL

block south
session lantern <<'SQL'
SELECT sum(o.net_revenue) AS net_revenue_south
FROM semantic.orders o JOIN semantic.customers c USING (customer_id)
WHERE o.order_date >= '2026-01-01' AND c.region = 'South';
SQL

block aov
session lantern <<'SQL'
SELECT round(sum(net_revenue) / count(*), 2) AS per_order
FROM semantic.orders WHERE order_date >= '2026-01-01';
SELECT round(avg(per_customer), 2) AS per_customer
FROM (SELECT customer_id, sum(net_revenue) / count(*) AS per_customer
      FROM semantic.orders WHERE order_date >= '2026-01-01'
      GROUP BY customer_id) AS c;
SQL

block ytd
session lantern <<'SQL'
SELECT k.month,
       sum(o.net_revenue) AS net_revenue,
       sum(sum(o.net_revenue)) OVER (ORDER BY k.month) AS net_revenue_ytd
FROM semantic.orders o JOIN semantic.calendar k ON k.day = o.order_date
WHERE k.month >= '2026-01-01'
GROUP BY k.month ORDER BY k.month;
SQL

block last-year
session lantern <<'SQL'
SELECT k.month,
       sum(o.net_revenue) AS net_revenue,
       (SELECT sum(o2.net_revenue) FROM semantic.orders o2
         WHERE o2.order_date >= k.month - interval '1 year'
           AND o2.order_date < k.month - interval '1 year' + interval '1 month') AS same_month_last_year
FROM semantic.orders o JOIN semantic.calendar k ON k.day = o.order_date
WHERE k.month BETWEEN '2026-03-01' AND '2026-05-01'
GROUP BY k.month ORDER BY k.month;
SQL

block bidirectional
session lantern <<'SQL'
SELECT count(*) AS orders_with_a_grinder
FROM semantic.orders o
WHERE EXISTS (SELECT 1 FROM semantic.order_lines l JOIN semantic.products p USING (product_id)
              WHERE l.order_id = o.order_id AND p.product = 'Hand Grinder');
SELECT count(*) AS all_orders FROM semantic.orders;
SQL

block rls
{ python3 "$FENCE" row-level-security.md 'CREATE TABLE semantic.region_access'
  python3 "$FENCE" row-level-security.md 'CREATE ROLE south_manager'; } | session lantern

block rls-check
on "PGPASSWORD=another-password-to-choose psql -h localhost -U south_manager lantern -c 'SELECT region, count(*) FROM semantic.my_orders GROUP BY region'"
