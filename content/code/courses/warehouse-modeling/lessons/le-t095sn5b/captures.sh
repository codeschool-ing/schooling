#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of warehouse-modeling, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# This lesson starts from an empty ~/wh and builds the first star in it. The
# files that the lessons after it reuse are the course's own, in lab/ and
# lab/warehouse/, copied into ~/wh by `put` and shown in the lesson as they
# are. The fact tables built here leave out the customer: lesson 4 adds it,
# and lesson 5 makes it keep its history.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, DuckDB 1.5.6, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
COURSE=$(cd "$(dirname "$LAB_SH")" && pwd)
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/wh$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
put() { lab exec "cat > '$1'"; }
code() { printf '##### %s\n' "$1"; lab exec "cat '$2'"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/wh-capture.lock; flock 9
lab reset >/dev/null

put extract.sh < "$COURSE/lab/extract.sh"
block extract
on 'sh extract.sh'
on 'ls -l extract | head -6'
on 'head -3 extract/orders.csv'

block isbn-guess
on "duckdb -c \"SELECT isbn, typeof(isbn) AS type FROM read_csv('extract/books.csv') LIMIT 2\""

put staging.sql < "$COURSE/lab/warehouse/00_staging.sql"
block stage
on 'duckdb wh.duckdb < staging.sql'
on "duckdb wh.duckdb -c \"SELECT table_name, estimated_size AS rows FROM duckdb_tables() WHERE schema_name = 'staging' ORDER BY rows DESC LIMIT 5\""

put dim_date.sql < "$COURSE/lab/warehouse/10_dim_date.sql"
put dim_shop.sql < "$COURSE/lab/warehouse/11_dim_shop.sql"
put dim_book.sql < "$COURSE/lab/warehouse/12_dim_book.sql"
put dim_promotion.sql < "$COURSE/lab/warehouse/14_dim_promotion.sql"
block dims
on 'for f in dim_date dim_shop dim_book dim_promotion; do duckdb wh.duckdb < $f.sql; done'
block date-rows
on "duckdb wh.duckdb -c \"SELECT * FROM dim_date WHERE date_key IN (0, 20250418, 20250419)\""

block one-book
on "duckdb -line wh.duckdb -c \"SELECT * FROM dim_book WHERE book_id = 2395\""

block shops
on "duckdb wh.duckdb -c \"SELECT * FROM dim_shop\""

put fact_sales.sql <<'EOF'
-- The first fact table. Grain: one row per line of an order that was not
-- cancelled. Lesson 4 adds the customer.
CREATE TABLE fact_sales AS
SELECT d.date_key,
       s.shop_key,
       b.book_key,
       coalesce(l.promotion_id, 0)                        AS promotion_key,
       o.order_id,
       l.line_no,
       l.quantity,
       l.quantity * l.unit_price_cents                    AS gross_cents,
       l.discount_cents,
       l.quantity * l.unit_price_cents - l.discount_cents AS net_cents
FROM staging.order_lines l
JOIN staging.orders o USING (order_id)
JOIN dim_date d       ON d.date = CAST(o.ordered_at AS DATE)
JOIN dim_shop s       ON s.shop_id = o.shop_id
JOIN dim_book b       ON b.book_id = l.book_id
WHERE o.status <> 'cancelled'
ORDER BY o.order_id, l.line_no;
EOF
code fact-sales-sql fact_sales.sql
block fact-sales
on 'duckdb wh.duckdb < fact_sales.sql'
on "duckdb wh.duckdb -c \"SELECT * FROM fact_sales LIMIT 3\""
on "duckdb wh.duckdb -c \"SELECT count(*) AS lines, sum(net_cents) AS net_cents FROM fact_sales\""

put holidays.sql <<'EOF'
-- Revenue per shop-day in physical shops: holidays against ordinary days.
SELECT d.is_holiday,
       count(DISTINCT (f.date_key, f.shop_key))             AS shop_days,
       round(sum(f.net_cents) / 100 / count(DISTINCT (f.date_key, f.shop_key)), 2)
                                                            AS brl_per_shop_day
FROM fact_sales f
JOIN dim_date d USING (date_key)
JOIN dim_shop s USING (shop_key)
WHERE s.channel = 'store' AND NOT d.is_weekend
GROUP BY d.is_holiday
ORDER BY d.is_holiday;
EOF
code holidays-sql holidays.sql
block holidays
on 'duckdb wh.duckdb < holidays.sql'

put additive.sql <<'EOF'
SELECT s.shop_name,
       sum(f.quantity)                                   AS books,
       sum(f.net_cents)                                  AS net_cents,
       round(100.0 * sum(f.discount_cents) / sum(f.gross_cents), 2) AS discount_pct
FROM fact_sales f JOIN dim_shop s USING (shop_key)
GROUP BY ALL ORDER BY net_cents DESC;
EOF
code additive-sql additive.sql
block additive
on 'duckdb wh.duckdb < additive.sql'

put ratio.sql <<'EOF'
-- The discount rate of the whole chain, worked out two ways.
WITH by_shop AS (
    SELECT shop_key, sum(discount_cents) AS discount, sum(gross_cents) AS gross
    FROM fact_sales GROUP BY shop_key
)
SELECT round(100.0 * sum(discount) / sum(gross), 2) AS chain_rate,
       round(avg(100.0 * discount / gross), 2)       AS average_of_shop_rates
FROM by_shop;
EOF
code ratio-sql ratio.sql
block ratio
on 'duckdb wh.duckdb < ratio.sql'

put fact_inventory.sql < "$COURSE/lab/warehouse/21_fact_inventory.sql"
block inventory
on 'duckdb wh.duckdb < fact_inventory.sql'
put stock.sql <<'EOF'
-- Books on the shelves of Paulista, two ways.
SELECT d.year,
       sum(i.on_hand)                                   AS summed_over_months,
       sum(i.on_hand) FILTER (WHERE d.month = 12)       AS at_year_end,
       round(sum(i.on_hand) / count(DISTINCT d.month))  AS average_month_end
FROM fact_inventory i
JOIN dim_date d USING (date_key)
JOIN dim_shop s USING (shop_key)
WHERE s.shop_name = 'Paulista'
GROUP BY d.year ORDER BY d.year;
EOF
code stock-sql stock.sql
block stock
on 'duckdb wh.duckdb < stock.sql'

put fact_fulfilment.sql <<'EOF'
-- Grain: one row per online order, updated as it moves. A milestone not
-- reached yet points at the 'Not yet' date, key 0.
CREATE TABLE fact_fulfilment AS
SELECT o.order_id,
       CAST(strftime(o.ordered_at, '%Y%m%d') AS INTEGER)                  AS ordered_date_key,
       coalesce(CAST(strftime(o.paid_at, '%Y%m%d') AS INTEGER), 0)        AS paid_date_key,
       coalesce(CAST(strftime(o.shipped_at, '%Y%m%d') AS INTEGER), 0)     AS shipped_date_key,
       coalesce(CAST(strftime(o.delivered_at, '%Y%m%d') AS INTEGER), 0)   AS delivered_date_key,
       o.status,
       date_diff('day', CAST(o.ordered_at AS DATE), CAST(o.shipped_at AS DATE))   AS days_to_ship,
       date_diff('day', CAST(o.ordered_at AS DATE), CAST(o.delivered_at AS DATE)) AS days_to_deliver
FROM staging.orders o
JOIN staging.shops sh USING (shop_id)
WHERE sh.channel = 'online' AND o.status <> 'cancelled';
EOF
code fulfilment-sql fact_fulfilment.sql
block fulfilment
on 'duckdb wh.duckdb < fact_fulfilment.sql'
on "duckdb wh.duckdb -c \"SELECT * FROM fact_fulfilment WHERE order_id IN (100001, 676352)\""
put lead-times.sql <<'EOF'
SELECT d.year, d.month_name,
       count(*)                          AS orders,
       round(avg(f.days_to_ship), 1)     AS avg_days_to_ship,
       round(avg(f.days_to_deliver), 1)  AS avg_days_to_deliver,
       count(*) FILTER (WHERE f.delivered_date_key = 0) AS not_delivered_yet
FROM fact_fulfilment f
JOIN dim_date d ON d.date_key = f.ordered_date_key
WHERE d.month IN (11, 12)
GROUP BY ALL ORDER BY d.year, d.month_name DESC;
EOF
code lead-times-sql lead-times.sql
block lead-times
on 'duckdb wh.duckdb < lead-times.sql'

put fact_attendance.sql <<'EOF'
-- Grain: one row per customer at an author's event. There is no measure:
-- the row is the fact.
CREATE TABLE fact_event_attendance AS
SELECT d.date_key, s.shop_key, e.author_id, ea.customer_id
FROM staging.event_attendance ea
JOIN staging.events e USING (event_id)
JOIN dim_date d ON d.date = e.held_on
JOIN dim_shop s ON s.shop_id = e.shop_id;
EOF
code attendance-sql fact_attendance.sql
block attendance
on 'duckdb wh.duckdb < fact_attendance.sql'
put events.sql <<'EOF'
SELECT s.shop_name,
       count(DISTINCT f.date_key)    AS events,
       count(*)                      AS attendances,
       count(DISTINCT f.customer_id) AS people
FROM fact_event_attendance f JOIN dim_shop s USING (shop_key)
GROUP BY ALL ORDER BY attendances DESC;
EOF
code events-sql events.sql
block events
on 'duckdb wh.duckdb < events.sql'

block changes
on "duckdb wh.duckdb -c \"SELECT field, count(*) AS changes FROM staging.customer_changes GROUP BY ALL ORDER BY changes DESC\""
