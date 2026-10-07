#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of pipelines-etl, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: `lab.sh reset` and the first ten days
# of March before the first block; Ana's project from lessons 6 to 9, copied
# into ~/etl from ../../lab/project, with the changes lesson 11 made to it —
# the loader that truncates, the dbt project and its profile — copied over it
# from ../../lab/after-11; raw loaded and the dbt models built once with
# `dbt run`. The files are written by `put` and shown in the lesson. Airflow
# is not started.
#
# dbt prints its own clock in UTC, at the start of every line; those times,
# like the durations beside them, are the recording's own.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, dbt-core 1.12.5 with
# dbt-postgres 1.11.0, 4 cores, TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "$0")/../../capture.sh"
P=$(cd "$(dirname "$0")/../../lab/project" && pwd)
A=$(cd "$(dirname "$0")/../../lab/after-11" && pwd)
shop() { printf 'ana@vm:~/etl/shop$ %s\n' "$*"; lab exec "cd shop && $*" 2>&1 || true; }
lab reset >/dev/null
lab until 2026-03-10 >/dev/null
for f in $(cd "$P" && find . -type f ! -name README | sed 's|^\./||'); do put "$f" < "$P/$f"; done
for f in $(cd "$A" && find load_raw.py shop -type f); do put "$f" < "$A/$f"; done
lab exec 'rm -rf ~/.dbt; mkdir -p ~/.dbt && cat > ~/.dbt/profiles.yml' < "$A/profiles.yml"
lab exec 'touch landing/prices.jsonl; python load_raw.py >/dev/null; cd shop && dbt run >/dev/null'

put shop/models/staging/schema.yml <<'YML'
version: 2

models:
  - name: stg_orders
    columns:
      - name: order_id
        data_tests: [unique, not_null]
      - name: customer_id
        data_tests: [not_null]
      - name: status
        data_tests:
          - accepted_values:
              arguments:
                values: [completed, cancelled, refunded]
  - name: stg_order_lines
    columns:
      - name: order_id
        data_tests:
          - unique
          - relationships:
              arguments:
                to: ref('stg_orders')
                field: order_id
YML
code schema-1 shop/models/staging/schema.yml
block test-1
shop 'dbt test'
block test-sql
shop 'cat target/compiled/shop/models/staging/schema.yml/not_null_stg_orders_customer_id.sql; echo'
shop 'cat target/compiled/shop/models/staging/schema.yml/unique_stg_order_lines_order_id.sql; echo'
block walk-in
on 'psql -d wh -c "SELECT s.name, s.channel, count(*) FILTER (WHERE o.customer_id IS NULL) AS no_customer, count(*) AS orders FROM dbt_staging.stg_orders o JOIN raw.shops s USING (shop_id) GROUP BY 1, 2 ORDER BY 2, 1"'

put shop/models/staging/schema.yml <<'YML'
version: 2

models:
  - name: stg_orders
    columns:
      - name: order_id
        data_tests: [unique, not_null]
      - name: customer_id
        data_tests:
          - not_null:
              config:
                where: "shop_id = 7"            # the website: a till may sell to nobody
      - name: status
        data_tests:
          - accepted_values:
              arguments:
                values: [completed, cancelled, refunded]
  - name: stg_order_lines
    data_tests:
      - unique:                                 # the grain is the order AND the line
          arguments:
            column_name: "order_id || '-' || line_no"
    columns:
      - name: order_id
        data_tests:
          - relationships:
              arguments:
                to: ref('stg_orders')
                field: order_id
YML
code schema-2 shop/models/staging/schema.yml
block build-skip
shop 'dbt build 2>&1 | grep -E "PASS|FAIL|WARN|SKIP|ERROR|Done"'
block erased
on 'psql -d wh -c "SELECT order_id, ordered_at, updated_at FROM raw.orders WHERE shop_id = 7 AND customer_id IS NULL ORDER BY 1"'
block warn
lab exec "sed -i 's|                where: \"shop_id = 7\"            # the website: a till may sell to nobody|                where: \"shop_id = 7\"            # the website: a till may sell to nobody\\n                severity: warn                  # 7 erased customers: known, and lawful|' shop/models/staging/schema.yml"
shop 'grep -n -A4 "not_null:" models/staging/schema.yml'
shop 'dbt build 2>&1 | grep -E "WARN|FAIL|SKIP|ERROR|Done"'

put shop/tests/fact_sales_has_not_drifted.sql <<'SQL'
-- Days on which the incremental fact table and a rebuild from staging disagree:
-- lesson 11's drift.sql, made into a test. Every row it returns is a failure.
select order_date, t.lines as in_table, s.lines as in_source
  from (select order_date, count(*) as lines from {{ ref('fact_sales') }} group by 1) as t
  full join (select order_date, count(*) as lines from {{ ref('int_sales') }} group by 1) as s
       using (order_date)
 where t.lines is distinct from s.lines
SQL
code singular shop/tests/fact_sales_has_not_drifted.sql
block drift-test
shop 'dbt build 2>&1 | grep -E "drift|Done"'
root 'until 2026-03-14'
on 'python load_raw.py >/dev/null'
shop 'dbt build 2>&1 | grep -E "fact_sales|drift|Done"'
shop 'dbt build -s fact_sales+ --full-refresh 2>&1 | grep -E "fact_sales|drift|Done"'

put shop/models/marts/schema.yml <<'YML'
version: 2

models:
  - name: daily_sales
    description: >
      Books and revenue by day, shop and category, counting completed sales only.
      One row per combination that sold anything. Read by the morning report.
    columns:
      - name: order_date
        description: The day of the sale in São Paulo, not in UTC.
        data_tests: [not_null]
      - name: revenue_cents
        description: Sum of quantity times unit price, in cents of a real.
  - name: fact_sales
    description: >
      One row per order line sold. Incremental: each run replaces the newest day it
      has and every day after it, so changes to older days need a full refresh.
    columns:
      - name: customer_id
        description: Null for a sale at a till to nobody, and for a customer erased on request.
YML
put shop/models/marts/exposures.yml <<'YML'
version: 2

exposures:
  - name: morning_report
    type: dashboard
    description: The sales report the shops' managers read at 08:00.
    owner:
      name: Ana
    depends_on:
      - ref('daily_sales')
YML
put docs.py <<'PY'
"""What dbt docs knows about one model: its description from the project,
its columns' types from the database, and what it depends on."""
import json
import sys

model = f"model.shop.{sys.argv[1]}"
manifest = json.load(open("shop/target/manifest.json"))
catalog = json.load(open("shop/target/catalog.json"))
node, table = manifest["nodes"][model], catalog["nodes"][model]
print(node["description"].strip())
for name, col in table["columns"].items():
    said = node["columns"].get(name, {}).get("description", "")
    print(f"  {name:<14}{col['type']:<10}{said}")
print("depends on:", ", ".join(manifest["parent_map"][model]))
print("used by:   ", ", ".join(manifest["child_map"][model]))
PY
code marts-schema shop/models/marts/schema.yml
code exposures shop/models/marts/exposures.yml
code docs-py docs.py
block docs
shop 'dbt docs generate 2>&1 | tail -n 2'
shop 'ls target'
on 'python docs.py daily_sales'
block lineage
shop 'dbt ls -s +exposure:morning_report --resource-type model --resource-type source --resource-type exposure'
shop 'dbt ls -s source:raw.orders+ --resource-type model --resource-type exposure'
