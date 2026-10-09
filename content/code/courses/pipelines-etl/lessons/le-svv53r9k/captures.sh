#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of pipelines-etl, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: `lab.sh reset` and the first day of
# March before the first block; Ana's project from lesson 6, copied into ~/etl
# from ../../lab/project; and in the `nights` block, the loop that plays each
# day from 2 to 14 March and runs the nightly load after it, which the lesson
# shows as a loop and does not print.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "$0")/../../capture.sh"
P=$(cd "$(dirname "$0")/../../lab/project" && pwd)
lab reset >/dev/null
lab day 2026-03-01 >/dev/null
for f in $(cd "$P" && find . -type f ! -name README | sed 's|^\./||'); do put "$f" < "$P/$f"; done
lab exec 'touch landing/prices.jsonl; python load_raw.py >/dev/null; sh run_sql.sh >/dev/null'

put nightly.sh <<'SH'
#!/bin/sh
# One night: copy the shop into raw, rebuild staging, then load the marts.
set -e
day=${1:?usage: nightly.sh YYYY-MM-DD}
export PGOPTIONS="-c client_min_messages=warning"
python load_raw.py >/dev/null
sh run_sql.sh >/dev/null
psql -q -v ON_ERROR_STOP=1 -d wh -f load/dim_customer.sql
psql -q -v ON_ERROR_STOP=1 -d wh -At -f load/dim_book.sql | sort | uniq -c | sed 's/t$/inserted/; s/f$/updated/'
psql -q -v ON_ERROR_STOP=1 -d wh -v day="$day" -f load/fact_sales.sql
psql -d wh -At -c "SELECT '$day: ' || count(*) || ' fact rows' FROM marts.fact_sales WHERE order_date = '$day'"
SH
code nightly-sh nightly.sh
code dim-book-sql load/dim_book.sql
code dim-customer-sql load/dim_customer.sql
code fact-sql load/fact_sales.sql

block first
on 'sh nightly.sh 2026-03-01'
on "psql -d wh -c \"SELECT count(*) AS versions, count(DISTINCT customer_id) AS customers FROM marts.dim_customer\""

block second
root 'day 2026-03-02'
on 'sh nightly.sh 2026-03-02'

block twice
on 'sh nightly.sh 2026-03-02'
on "psql -d wh -c \"SELECT order_date, count(*) FROM marts.fact_sales GROUP BY 1 ORDER BY 1\""

block append
on "psql -d wh -c \"CREATE TABLE marts.sales_log AS SELECT * FROM marts.fact_sales WHERE false\""
on "psql -d wh -c \"INSERT INTO marts.sales_log SELECT * FROM marts.fact_sales WHERE order_date = '2026-03-02'\""
on "psql -d wh -c \"INSERT INTO marts.sales_log SELECT * FROM marts.fact_sales WHERE order_date = '2026-03-02'\""
on "psql -d wh -c \"SELECT order_date, count(*), count(DISTINCT (order_id, line_no)) AS distinct_lines FROM marts.sales_log GROUP BY 1\""

block third
root 'day 2026-03-03'
on 'grep "^UPDATE books" /var/lib/etl-data/days/2026-03-03.sql'
on 'sh nightly.sh 2026-03-03'

block nights
for d in 04 05 06 07 08 09 10 11 12 13 14 15; do lab day 2026-03-$d >/dev/null; lab exec "sh nightly.sh 2026-03-$d" >/dev/null; done
on "psql -d wh -c \"SELECT customer_key, customer_id, city, state, valid_from, valid_to, is_current FROM marts.dim_customer WHERE customer_id = 3145 ORDER BY valid_from\""
on "psql -d wh -c \"SELECT count(*) AS versions, count(DISTINCT customer_id) AS customers, count(*) FILTER (WHERE NOT is_current) AS closed FROM marts.dim_customer\""

block point-in-time
on "psql -d wh -c \"SELECT f.order_date, f.order_id, d.city FROM marts.fact_sales f JOIN marts.dim_customer d USING (customer_key) WHERE d.customer_id = 3145 ORDER BY f.order_date\""

block erased
on "psql -d wh -c \"SELECT count(*) FROM marts.dim_customer WHERE customer_id = 1880\""
on "psql -d wh -c \"SELECT customer_key = -1 AS unknown, count(*) FROM marts.fact_sales GROUP BY 1\""

block truncate
lab exec "psql -d wh -c 'CREATE TABLE marts.dim_shop AS SELECT * FROM raw.shops'" >/dev/null
lab exec "setsid psql -d wh -c 'BEGIN; TRUNCATE marts.dim_shop; INSERT INTO marts.dim_shop SELECT * FROM raw.shops; SELECT pg_sleep(5); COMMIT;' </dev/null >/dev/null 2>&1 &"
sleep 1
on "psql -d wh -c \"SET lock_timeout = '2s'\" -c \"SELECT count(*) FROM marts.dim_shop\""
sleep 5
lab exec "setsid psql -d wh -c 'BEGIN; DELETE FROM marts.dim_shop; INSERT INTO marts.dim_shop SELECT * FROM raw.shops; SELECT pg_sleep(5); COMMIT;' </dev/null >/dev/null 2>&1 &"
sleep 1
on "psql -d wh -c \"SET lock_timeout = '2s'\" -c \"SELECT count(*) FROM marts.dim_shop\""
sleep 5
