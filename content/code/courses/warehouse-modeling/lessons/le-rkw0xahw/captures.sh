#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of warehouse-modeling, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: ~/wh/wh.duckdb, the warehouse lessons 2
# to 5 build, made here by `lab.sh warehouse`. The tables this lesson adds to
# show a mistake, and then its repair, are built by the files `put` writes,
# which the lesson shows as they are.
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

put shipping-wrong.sql <<'EOF'
-- The shipping fee, copied onto every line of its order.
CREATE TABLE sales_with_shipping AS
SELECT f.*, o.shipping_cents
FROM fact_sales f JOIN staging.orders o USING (order_id);

SELECT (SELECT sum(shipping_cents) FROM sales_with_shipping)        AS summed_over_lines,
       (SELECT sum(shipping_cents) FROM staging.orders
         WHERE status <> 'cancelled')                                AS charged;
EOF
code shipping-wrong-sql shipping-wrong.sql
block shipping-wrong
on 'duckdb wh.duckdb < shipping-wrong.sql'

put allocate.sql <<'EOF'
-- Share each order's shipping among its lines, in proportion to their net
-- value, in whole cents; the cents left over go to the largest lines first.
CREATE TABLE fact_sales_shipping AS
WITH shares AS (
    SELECT f.order_id, f.line_no, f.net_cents, o.shipping_cents,
           o.shipping_cents * f.net_cents / sum(f.net_cents) OVER (PARTITION BY f.order_id)
               AS exact_share
    FROM fact_sales f JOIN staging.orders o USING (order_id)
    WHERE o.shipping_cents > 0
),
floored AS (
    SELECT *, CAST(floor(exact_share) AS BIGINT) AS cents,
           shipping_cents - sum(CAST(floor(exact_share) AS BIGINT))
               OVER (PARTITION BY order_id) AS left_over,
           row_number() OVER (PARTITION BY order_id
                              ORDER BY exact_share - floor(exact_share) DESC, line_no) AS place
    FROM shares
)
SELECT order_id, line_no, net_cents,
       cents + CASE WHEN place <= left_over THEN 1 ELSE 0 END AS shipping_cents
FROM floored;

SELECT * FROM fact_sales_shipping WHERE order_id = 112406 ORDER BY line_no;
SELECT sum(shipping_cents) AS allocated FROM fact_sales_shipping;
EOF
code allocate-sql allocate.sql
block allocate
on 'duckdb wh.duckdb < allocate.sql'

put fan-out.sql <<'EOF'
-- Two fact tables at two grains, joined on the order number.
SELECT (SELECT sum(net_cents) FROM fact_sales)                    AS sold,
       (SELECT sum(amount_cents) FROM fact_payments)              AS paid,
       sum(s.net_cents)                                           AS sold_after_join,
       sum(p.amount_cents)                                        AS paid_after_join
FROM fact_sales s JOIN fact_payments p USING (order_id);
EOF
code fan-out-sql fan-out.sql
block fan-out
on 'duckdb wh.duckdb < fan-out.sql'

block degenerate
on "duckdb wh.duckdb -c \"SELECT count(*) AS lines, count(DISTINCT order_id) AS orders FROM fact_sales\""
on "duckdb wh.duckdb -c \"SELECT f.line_no, b.title, f.quantity, f.net_cents FROM fact_sales f JOIN dim_book b USING (book_key) WHERE f.order_id = 112406 ORDER BY f.line_no\""

block emails
on "duckdb wh.duckdb -c \"SELECT changed_at, old_value, new_value FROM staging.customer_changes WHERE field = 'email' ORDER BY change_id LIMIT 2\""

block customer-keys
on "duckdb wh.duckdb -c \"SELECT customer_key, customer_id, city, state, tier, valid_from, valid_to FROM dim_customer WHERE customer_id = 2123\""

put key-size.sql <<'EOF'
-- The same 887,477 references, kept as an integer key and as an e-mail address.
COPY (SELECT customer_key FROM fact_sales) TO 'by_key.parquet';
COPY (SELECT coalesce(c.email, '') AS customer_email
      FROM fact_sales f
      LEFT JOIN dim_customer d USING (customer_key)
      LEFT JOIN staging.customers c ON c.customer_id = d.customer_id) TO 'by_email.parquet';
EOF
code key-size-sql key-size.sql
block key-size
on 'duckdb wh.duckdb < key-size.sql'
on 'ls -l by_key.parquet by_email.parquet'

block unknown-row
on "duckdb wh.duckdb -c \"SELECT * FROM dim_customer WHERE customer_key = 0\""

put null-keys.sql <<'EOF'
-- What happens if walk-in sales carry no customer at all.
CREATE TABLE sales_null_customer AS
SELECT * REPLACE (CASE WHEN customer_key = 0 THEN NULL ELSE customer_key END AS customer_key)
FROM fact_sales;

SELECT 'with key 0' AS version, count(*) AS lines, sum(net_cents) AS net_cents
FROM fact_sales f JOIN dim_customer c USING (customer_key)
UNION ALL
SELECT 'with NULL', count(*), sum(net_cents)
FROM sales_null_customer f JOIN dim_customer c USING (customer_key);
EOF
code null-keys-sql null-keys.sql
block null-keys
on 'duckdb wh.duckdb < null-keys.sql'

block authors
on "duckdb wh.duckdb -c \"SELECT b.title, a.author_name, ba.position, ba.weight FROM bridge_book_author ba JOIN dim_book b USING (book_key) JOIN dim_author a USING (author_key) WHERE b.book_id = 600\""
on "duckdb wh.duckdb -c \"SELECT count(*) AS books, count(*) FILTER (WHERE n > 1) AS with_more_than_one FROM (SELECT book_key, count(*) AS n FROM bridge_book_author GROUP BY book_key)\""

put by-author.sql <<'EOF'
-- Revenue by author, through the bridge, with and without its weight.
SELECT round(sum(f.net_cents) / 100, 2)             AS total_through_bridge,
       round(sum(f.net_cents * ba.weight) / 100, 2) AS total_weighted,
       (SELECT round(sum(net_cents) / 100, 2) FROM fact_sales) AS total_sold
FROM fact_sales f
JOIN bridge_book_author ba USING (book_key);
EOF
code by-author-sql by-author.sql
block by-author
on 'duckdb wh.duckdb < by-author.sql'

put top-authors.sql <<'EOF'
SELECT a.author_name,
       round(sum(f.net_cents) / 100, 2)             AS impact_brl,
       round(sum(f.net_cents * ba.weight) / 100, 2) AS weighted_brl
FROM fact_sales f
JOIN bridge_book_author ba USING (book_key)
JOIN dim_author a USING (author_key)
GROUP BY ALL
ORDER BY impact_brl DESC
LIMIT 5;
EOF
code top-authors-sql top-authors.sql
block top-authors
on 'duckdb wh.duckdb < top-authors.sql'
