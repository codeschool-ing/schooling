#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of analytics-bi, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from a cluster as sql-databases leaves it: a role for ana and no
# database called lantern. lantern.sql and the two ALTER DATABASE lines are
# taken out of setting-up.md and run as they are printed there; the view
# order_totals is taken out of order-value.md the same way.
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

lab role
lab exec 'dropdb --if-exists lantern; rm -f ~/lantern.sql'

block versions
on 'psql --version'
on 'pg_lsclusters'

python3 "$FENCE" setting-up.md '-- lantern.sql' | lab exec 'cat > lantern.sql'

block createdb
on 'createdb lantern'

block load
on 'psql -q lantern -f lantern.sql'

block alter
printf 'ana@vm:~$ psql lantern\n'
python3 "$FENCE" setting-up.md 'ALTER DATABASE lantern' | session lantern

block show
printf 'ana@vm:~$ psql lantern\n'
printf 'SHOW timezone;\nSHOW search_path;\n' | session lantern

block load-again
on 'psql -q lantern -f lantern.sql'

block dt
printf '\\dt\n' | session lantern

block ranges
session lantern <<'SQL'
SELECT count(*) AS customers, min(signed_up), max(signed_up) FROM customers;
SELECT count(*) AS orders, min(ordered_at), max(ordered_at) FROM orders;
SELECT status, count(*) FROM orders GROUP BY status;
SQL

block grain
session lantern <<'SQL'
SELECT count(*) AS lines, count(DISTINCT order_id) AS orders FROM order_lines;
SELECT count(*) AS orders_without_lines
FROM orders o
WHERE NOT EXISTS (SELECT 1 FROM order_lines l WHERE l.order_id = o.order_id);
SQL

python3 "$FENCE" order-value.md 'CREATE VIEW order_totals' > /tmp/abi-view.sql
chmod 644 /tmp/abi-view.sql

block view
{ cat /tmp/abi-view.sql; } | session lantern

block histogram
session lantern <<'SQL'
SELECT (width_bucket(gross_cents, 0, 40000, 8) - 1) * 50 AS from_brl,
       count(*), repeat('#', count(*)::int / 40) AS orders
FROM order_totals GROUP BY 1 ORDER BY 1;
SQL

block centre
session lantern <<'SQL'
SELECT round(avg(gross_cents) / 100.0, 2) AS mean_brl,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY gross_cents) / 100 AS median_brl
FROM order_totals;
SELECT percentile_cont(ARRAY[0.25, 0.5, 0.75]) WITHIN GROUP (ORDER BY gross_cents)
       AS quartiles_cents
FROM order_totals;
SQL

block by-segment
session lantern <<'SQL'
SELECT c.segment, count(*) AS orders,
       round(avg(t.gross_cents) / 100.0, 2) AS mean_brl,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY t.gross_cents) / 100 AS median_brl
FROM order_totals t JOIN customers c USING (customer_id)
GROUP BY c.segment;
SQL

block fences
session lantern <<'SQL'
WITH q AS (
  SELECT percentile_cont(0.25) WITHIN GROUP (ORDER BY gross_cents) AS q1,
         percentile_cont(0.75) WITHIN GROUP (ORDER BY gross_cents) AS q3
  FROM order_totals)
SELECT q1 - 1.5 * (q3 - q1) AS low_fence,
       q3 + 1.5 * (q3 - q1) AS high_fence,
       (SELECT count(*) FROM order_totals, q
         WHERE gross_cents > q3 + 1.5 * (q3 - q1)) AS above
FROM q;
SQL

block top
session lantern <<'SQL'
SELECT t.order_id, t.customer_id, c.segment, t.gross_cents / 100 AS gross_brl
FROM order_totals t JOIN customers c USING (customer_id)
ORDER BY t.gross_cents DESC LIMIT 6;
SQL

block mismatch
session lantern <<'SQL'
SELECT l.order_id, l.product_id, l.quantity, l.unit_cents, p.price_cents
FROM order_lines l JOIN products p USING (product_id)
WHERE l.unit_cents <> p.price_cents
ORDER BY l.order_id;
SQL

block above-by-segment
session lantern <<'SQL'
SELECT c.segment, count(*) AS above_fence
FROM order_totals t JOIN customers c USING (customer_id)
WHERE t.gross_cents > 34977.5
GROUP BY c.segment;
SQL

block bottom
session lantern <<'SQL'
SELECT order_id, customer_id, gross_cents FROM order_totals ORDER BY gross_cents LIMIT 5;
SELECT customer_id, signed_up, state, channel FROM customers WHERE customer_id = 1;
SQL

block corr
session lantern <<'SQL'
SELECT round(corr(discount_pct, gross_cents)::numeric, 3) AS r FROM order_totals;
SELECT c.segment, count(*) AS orders,
       round(corr(t.discount_pct, t.gross_cents)::numeric, 3) AS r
FROM order_totals t JOIN customers c USING (customer_id)
GROUP BY c.segment;
SELECT c.segment, t.discount_pct, count(*) AS orders,
       round(avg(t.gross_cents) / 100.0, 2) AS mean_brl
FROM order_totals t JOIN customers c USING (customer_id)
GROUP BY 1, 2 ORDER BY 1, 2;
SQL

block corr-clean
session lantern <<'SQL'
SELECT round(corr(discount_pct, gross_cents)::numeric, 3) AS r
FROM order_totals
WHERE order_id NOT IN (412, 415, 431);
SQL

block months
session lantern <<'SQL'
SELECT to_char(date_trunc('month', ordered_at), 'YYYY-MM') AS month,
       count(*) AS orders, repeat('#', count(*)::int / 20) AS bar
FROM orders GROUP BY 1 ORDER BY 1;
SQL

block empty-days
session lantern <<'SQL'
SELECT d::date AS day, extract(isodow FROM d) AS weekday
FROM generate_series(date '2025-04-01', date '2026-06-17', interval '1 day') AS d
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.ordered_at::date = d::date)
ORDER BY 1;
SQL

block around
session lantern <<'SQL'
SELECT ordered_at::date AS day, count(*) AS orders
FROM orders
WHERE ordered_at::date BETWEEN '2025-08-07' AND '2025-08-21'
GROUP BY 1 ORDER BY 1;
SQL

block weekday
session lantern <<'SQL'
SELECT extract(isodow FROM ordered_at) AS weekday, to_char(ordered_at, 'Dy') AS name,
       count(*) AS orders
FROM orders GROUP BY 1, 2 ORDER BY 1;
SQL

# ---- when-setup-fails
block truncated
lab exec 'head -n 100 lantern.sql > short.sql'
on 'psql -q lantern -f short.sql'
lab exec 'rm -f short.sql'
on 'psql -q lantern -f lantern.sql >/dev/null 2>&1'

block no-db
on 'psql lantern2'


block stopped
on 'sudo pg_ctlcluster 16 main stop'
on 'psql lantern'
on 'sudo pg_ctlcluster 16 main start'

block ssh
printf '$ ssh -p 2222 ana@localhost\n'; script -qc 'ssh -o BatchMode=yes -p 2222 ana@localhost' /dev/null | tr -d '\r' || true

# Last, because it throws the cluster away: a server that has never heard of ana.
block no-role
lab fresh
on 'psql lantern'
lab shop
python3 "$FENCE" order-value.md 'CREATE VIEW order_totals' | lab exec 'psql -qX lantern'
