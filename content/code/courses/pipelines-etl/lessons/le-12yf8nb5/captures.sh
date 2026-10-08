#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of pipelines-etl, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: `lab.sh reset` and the first sixteen
# days of March before the first block; Ana's project from lessons 6 to 9,
# copied into ~/etl from ../../lab/project, with what lessons 11 and 12 added
# copied over it from ../../lab/after-11 and ../../lab/after-12; raw loaded,
# the dbt project built once with `dbt build --full-refresh`, and the old
# pipeline's marts loaded for the 16th with `sh nightly.sh 2026-03-16`. The
# files are written by `put` and shown in the lesson. Airflow is not started.
#
# dbt's clock in its own lines is UTC; times and durations are the recording's
# own. Fingerprints are md5 sums of the rows, and are the same on every run of
# this script, because the lab's data is drawn from fixed seeds.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, dbt-core 1.12.5,
# 4 cores, TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "$0")/../../capture.sh"
P=$(cd "$(dirname "$0")/../../lab/project" && pwd)
A=$(cd "$(dirname "$0")/../../lab/after-11" && pwd)
B=$(cd "$(dirname "$0")/../../lab/after-12" && pwd)
shop() { printf 'ana@vm:~/etl/shop$ %s\n' "$*"; lab exec "cd shop && $*" 2>&1 || true; }
lab reset >/dev/null
lab until 2026-03-16 >/dev/null
for f in $(cd "$P" && find . -type f ! -name README | sed 's|^\./||'); do put "$f" < "$P/$f"; done
for f in $(cd "$A" && find load_raw.py shop -type f); do put "$f" < "$A/$f"; done
for f in $(cd "$B" && find shop -type f); do put "$f" < "$B/$f"; done
lab exec 'rm -rf ~/.dbt; mkdir -p ~/.dbt && cat > ~/.dbt/profiles.yml' < "$A/profiles.yml"
lab exec 'touch landing/prices.jsonl; python load_raw.py >/dev/null; cd shop && dbt build --full-refresh >/dev/null'
lab exec 'sh nightly.sh 2026-03-16 >/dev/null'

put fingerprint.sql <<'SQL'
-- One day of marts.fact_sales reduced to two values: how many lines, and an md5
-- of all of them in a fixed order. Two runs that leave the same day behind give
-- the same two values; any difference at all, in any column, changes the md5.
SELECT count(*) AS lines,
       md5(string_agg(f::text, '|' ORDER BY order_id, line_no)) AS fingerprint
  FROM marts.fact_sales f
 WHERE order_date = :'day';
SQL
put load/fact_sales_append.sql <<'SQL'
-- marts.fact_sales for one day, the naive way: insert the day's lines.
INSERT INTO marts.fact_sales
SELECT o.order_date, o.order_id, l.line_no,
       coalesce(d.customer_key, -1),
       l.book_id, l.quantity, l.line_cents
  FROM staging.orders o
  JOIN staging.order_lines l USING (order_id)
  LEFT JOIN marts.dim_customer d
         ON d.customer_id = o.customer_id
        AND o.ordered_at >= d.valid_from
        AND (o.ordered_at < d.valid_to OR d.valid_to IS NULL)
 WHERE o.order_date = :'day' AND o.is_sale;
SQL
code fingerprint-sql fingerprint.sql
code append-sql load/fact_sales_append.sql
block append
on 'psql -d wh -v day=2026-03-16 -f fingerprint.sql'
on 'psql -q -d wh -v day=2026-03-16 -f load/fact_sales_append.sql'
on 'psql -d wh -v day=2026-03-16 -f fingerprint.sql'
on 'psql -q -d wh -v day=2026-03-16 -f load/fact_sales_append.sql'
on 'psql -d wh -v day=2026-03-16 -f fingerprint.sql'
block replace
on 'psql -q -d wh -v day=2026-03-16 -f load/fact_sales.sql'
on 'psql -d wh -v day=2026-03-16 -f fingerprint.sql'
on 'psql -q -d wh -v day=2026-03-16 -f load/fact_sales.sql'
on 'psql -d wh -v day=2026-03-16 -f fingerprint.sql'

put twice.sh <<'SH'
#!/bin/sh
# Run a step twice and say whether the second run changed anything.
#   sh twice.sh 'STEP' 'QUERY'
# QUERY is any SELECT that describes what the step leaves behind; the step is
# idempotent, as far as that query can see, when it gives the same answer after
# the first run and after the second.
set -e
step=$1 query=$2
sh -c "$step" >/dev/null
first=$(psql -d wh -Atc "$query")
sh -c "$step" >/dev/null
second=$(psql -d wh -Atc "$query")
echo "after one run:  $first"
echo "after two runs: $second"
if [ "$first" = "$second" ]; then echo "idempotent"; else echo "NOT idempotent"; exit 1; fi
SH
code twice-sh twice.sh
block twice
on "sh twice.sh 'psql -q -d wh -At -f load/dim_book.sql' 'SELECT count(*), md5(string_agg(d::text, chr(10) ORDER BY book_id)) FROM marts.dim_book d'"
on "sh twice.sh 'psql -q -d wh -f load/dim_customer.sql' 'SELECT count(*), md5(string_agg(d::text, chr(10) ORDER BY customer_key)) FROM marts.dim_customer d'"
on "sh twice.sh 'dbt build --project-dir shop --quiet' 'SELECT count(*), md5(string_agg(f::text, chr(10) ORDER BY order_id, line_no)) FROM dbt_marts.fact_sales f'"
on "sh twice.sh 'python load_raw.py' 'SELECT count(*), md5(string_agg(e::text, chr(10) ORDER BY e::text)) FROM raw.events e'"

block not-quite
put load/load_log.sql <<'SQL'
-- One row per load, so that somebody can ask when the fact table was last filled.
CREATE TABLE IF NOT EXISTS marts.load_log (loaded_day date, loaded_at timestamptz, lines bigint);
INSERT INTO marts.load_log
SELECT :'day', now(), count(*) FROM marts.fact_sales WHERE order_date = :'day';
SQL
code load-log load/load_log.sql
block not-quite-run
on "sh twice.sh 'psql -q -d wh -v day=2026-03-16 -f load/load_log.sql' 'SELECT count(*) FROM marts.load_log'"
on 'psql -d wh -c "TABLE marts.load_log"'

block lookback
root 'until 2026-03-18'
on 'python load_raw.py >/dev/null'
shop 'dbt build --quiet 2>&1 | grep -E "FAIL|Got"'
put shop/models/marts/fact_sales.sql <<'SQL'
-- One row per order line sold. Each run replaces the last thirty days the table
-- already has, and every day after them: the shop changes a sale for weeks after
-- it was made, and a day outside the window is only put right by a full refresh.
{{ config(materialized='incremental',
          incremental_strategy='delete+insert',
          unique_key='order_date') }}
select order_date, order_id, line_no, shop_id, customer_id, book_id, quantity, line_cents
  from {{ ref('int_sales') }}
{% if is_incremental() %}
 where order_date >= (select max(order_date) - 30 from {{ this }})
{% endif %}
SQL
on 'cat shop/models/marts/fact_sales.sql'
shop 'dbt build -s fact_sales+ 2>&1 | grep -E " OK | PASS | FAIL |Done"'
block lookback-next
root 'until 2026-03-21'
on 'python load_raw.py >/dev/null'
shop 'dbt build -s fact_sales+ 2>&1 | grep -E " OK | PASS | FAIL |Done"'
