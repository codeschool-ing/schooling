#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of pipelines-etl, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: `lab.sh reset` and the first nine days
# of March before the first block; Ana's project from lessons 6 to 9, copied
# into ~/etl from ../../lab/project, with raw, staging and marts.daily_sales
# built by it once, which is what the dbt models are compared against; and a
# copy of load_raw.py kept as /tmp/load_raw.before.py before Ana edits it, so
# that `diff` can show the edit. The files are written by `put` and shown in
# the lesson. Airflow is not started: nothing in this lesson needs it.
#
# dbt prints its own clock in UTC, at the start of every line; those times,
# like the durations beside them, are the recording's own.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, dbt-core 1.12.5 with
# dbt-postgres 1.11.0, 4 cores, TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "$0")/../../capture.sh"
P=$(cd "$(dirname "$0")/../../lab/project" && pwd)
# what ana typed in ~/etl/shop, the dbt project, and what it printed
shop() { printf 'ana@vm:~/etl/shop$ %s\n' "$*"; lab exec "cd shop && $*" 2>&1 || true; }
lab reset >/dev/null
lab until 2026-03-09 >/dev/null
for f in $(cd "$P" && find . -type f ! -name README | sed 's|^\./||'); do put "$f" < "$P/$f"; done
lab exec 'touch landing/prices.jsonl; python load_raw.py >/dev/null; sh run_sql.sh >/dev/null'
lab exec 'rm -rf ~/.dbt shop'

put shop/dbt_project.yml <<'YML'
name: shop
version: "1.0"
profile: ponto_final            # which entry of ~/.dbt/profiles.yml to connect with

flags:
  send_anonymous_usage_stats: false
  use_colors: false

models:
  shop:
    staging:                    # everything under models/staging
      +schema: staging
      +materialized: view
    marts:                      # everything under models/marts
      +schema: marts
      +materialized: table
YML
lab exec 'mkdir -p ~/.dbt && cat > ~/.dbt/profiles.yml' <<'YML'
ponto_final:
  target: dev
  outputs:
    dev:
      type: postgres
      host: /run/etl-pg         # the socket's directory: a path, not a name
      port: 5432
      user: ana
      password: ""
      dbname: wh
      schema: dbt
      threads: 4
YML
put shop/models/staging/sources.yml <<'YML'
version: 2

sources:
  - name: raw                   # what load_raw.py copies in: dbt reads it, never writes it
    schema: raw
    tables:
      - name: orders
      - name: order_lines
      - name: books
YML
put shop/models/staging/stg_orders.sql <<'SQL'
-- One row per order, as the shop has it, with the shop's own date worked out once.
select order_id,
       shop_id,
       customer_id,
       ordered_at,
       (ordered_at at time zone 'America/Sao_Paulo')::date as order_date,
       status,
       status = 'completed' as is_sale
  from {{ source('raw', 'orders') }}
SQL
put shop/models/staging/stg_order_lines.sql <<'SQL'
-- One row per order line, with what the line was worth.
select order_id,
       line_no,
       book_id,
       quantity,
       unit_price_cents,
       quantity * unit_price_cents as line_cents
  from {{ source('raw', 'order_lines') }}
SQL
put shop/models/staging/stg_books.sql <<'SQL'
-- One row per book.
select book_id, isbn, title, category, publisher, list_price_cents
  from {{ source('raw', 'books') }}
SQL
put shop/models/marts/daily_sales.sql <<'SQL'
-- Books and revenue by day, shop and category: one row per combination that sold anything.
select o.order_date,
       o.shop_id,
       b.category,
       sum(l.quantity)::integer  as books,
       sum(l.line_cents)::bigint as revenue_cents
  from {{ ref('stg_order_lines') }} l
  join {{ ref('stg_orders') }} o using (order_id)
  join {{ ref('stg_books') }} b using (book_id)
 where o.is_sale
 group by 1, 2, 3
SQL
code project-yml shop/dbt_project.yml
code profiles-yml ../.dbt/profiles.yml
code sources-yml shop/models/staging/sources.yml
code stg-orders shop/models/staging/stg_orders.sql
code daily-sales shop/models/marts/daily_sales.sql

block tree
shop 'find . -type f | sort'
block debug
shop 'dbt debug 2>&1 | grep -E "OK|ERROR|checks"'
block first-run
shop 'dbt run'
block schemas
on 'psql -d wh -c "\dn"'
block compare
on 'psql -d wh -c "SELECT count(*) FROM (TABLE marts.daily_sales EXCEPT TABLE dbt_marts.daily_sales) AS old_only" -c "SELECT count(*) FROM (TABLE dbt_marts.daily_sales EXCEPT TABLE marts.daily_sales) AS new_only"'
block compiled
shop 'find target -name daily_sales.sql'
shop 'cat target/compiled/shop/models/marts/daily_sales.sql; echo'
shop 'cat target/run/shop/models/marts/daily_sales.sql; echo'

put shop/models/staging/int_sales.sql <<'SQL'
-- Every order line that was a sale, with its order's date, shop and customer.
-- Ephemeral: never built, only pasted into the models that use it.
{{ config(materialized='ephemeral') }}
select o.order_date, o.order_id, l.line_no, o.shop_id, o.customer_id,
       l.book_id, l.quantity, l.line_cents
  from {{ ref('stg_order_lines') }} l
  join {{ ref('stg_orders') }} o using (order_id)
 where o.is_sale
SQL
put shop/models/marts/daily_sales.sql <<'SQL'
-- Books and revenue by day, shop and category: one row per combination that sold anything.
select s.order_date,
       s.shop_id,
       b.category,
       sum(s.quantity)::integer  as books,
       sum(s.line_cents)::bigint as revenue_cents
  from {{ ref('int_sales') }} s
  join {{ ref('stg_books') }} b using (book_id)
 group by 1, 2, 3
SQL
put shop/models/marts/fact_sales.sql <<'SQL'
-- One row per order line sold. Each run replaces the newest day it already
-- has and every day after it, and leaves the older days alone.
{{ config(materialized='incremental',
          incremental_strategy='delete+insert',
          unique_key='order_date') }}
select order_date, order_id, line_no, shop_id, customer_id, book_id, quantity, line_cents
  from {{ ref('int_sales') }}
{% if is_incremental() %}
 where order_date >= (select max(order_date) from {{ this }})
{% endif %}
SQL
code int-sales shop/models/staging/int_sales.sql
code daily-sales-2 shop/models/marts/daily_sales.sql
code fact-sales shop/models/marts/fact_sales.sql
block second-run
shop 'dbt run'
block built
on 'psql -d wh -c "\dv dbt_staging.*" -c "\dt dbt_marts.*"'
shop 'sed -n "1,12p" target/compiled/shop/models/marts/daily_sales.sql'
on 'psql -d wh -c "SELECT count(*) FROM (TABLE marts.daily_sales EXCEPT TABLE dbt_marts.daily_sales) AS old_only"'

block new-day
root 'day 2026-03-10'
on 'python load_raw.py'
lab exec 'cp load_raw.py /tmp/load_raw.before.py'
lab exec 'python3 - load_raw.py' <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
for name in ("table", "name"):
    s = s.replace(f'        wh.execute(f"DROP TABLE IF EXISTS raw.{{{name}}}")\n', "")
s = s.replace('        wh.execute(f"CREATE TABLE raw.{table} ({columns})")\n',
              '        # Emptied and refilled, never dropped: dbt\'s views are built on these tables.\n'
              '        wh.execute(f"CREATE TABLE IF NOT EXISTS raw.{table} ({columns})")\n'
              '        wh.execute(f"TRUNCATE raw.{table}")\n')
s = s.replace('        wh.execute(f"CREATE TABLE raw.{name} (doc jsonb NOT NULL, file text NOT NULL)")\n',
              '        wh.execute(f"CREATE TABLE IF NOT EXISTS raw.{name} (doc jsonb NOT NULL, file text NOT NULL)")\n'
              '        wh.execute(f"TRUNCATE raw.{name}")\n')
open(p, "w").write(s)
PY
block truncate
on 'diff /tmp/load_raw.before.py load_raw.py'
on 'python load_raw.py'
put drift.sql <<'SQL'
-- Days on which the incremental table and a rebuild from the source disagree.
SELECT order_date, t.lines AS in_table, s.lines AS in_source
  FROM (SELECT order_date, count(*) AS lines FROM dbt_marts.fact_sales GROUP BY 1) AS t
  FULL JOIN (SELECT order_date, count(*) AS lines
               FROM dbt_staging.stg_order_lines
               JOIN dbt_staging.stg_orders USING (order_id)
              WHERE is_sale GROUP BY 1) AS s USING (order_date)
 WHERE t.lines IS DISTINCT FROM s.lines
 ORDER BY 1;
SQL
code drift-sql drift.sql
block incremental
shop 'dbt run -s fact_sales'
on 'psql -d wh -c "SELECT order_date, count(*) FROM dbt_marts.fact_sales WHERE order_date >= '"'"'2026-03-08'"'"' GROUP BY 1 ORDER BY 1"'
shop 'cat target/run/shop/models/marts/fact_sales.sql; echo'
block drift
on 'psql -d wh -f drift.sql'
block full-refresh
shop 'dbt run -s fact_sales --full-refresh 2>&1 | grep -E " OK |ERROR"'
on 'psql -d wh -f drift.sql'

block graph
shop 'dbt ls -s +daily_sales'
shop 'dbt ls -s stg_orders+ --resource-type model'
shop 'dbt run -s stg_books+ 2>&1 | grep -E " OK |ERROR"'
