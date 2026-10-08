#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of pipelines-etl, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: `lab.sh reset` and the first
# twenty-one days of March before the first block; Ana's project from lessons
# 6 to 9, copied into ~/etl from ../../lab/project, with what lessons 11 to 17
# changed copied over it from ../../lab/after-11 to after-17; raw loaded and
# the dbt project built once. The files are written by `put` and shown in the
# lesson.
#
# THE LARGE TABLE IS MADE FOR THE LESSON, and the lesson says so: the shop's
# real sales, about thirty thousand lines, copied a hundred times with each
# copy moved back in time, so that there is enough data for a difference in
# method to show as a difference in time.
#
# Every time printed here is the recording's own, on this machine, and will be
# different on another; what the lesson relies on is the size of the gaps
# between them, which has been the same on every run.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, dbt-core 1.12.5,
# 4 cores, TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "$0")/../../capture.sh"
L=$(cd "$(dirname "$0")/../../lab" && pwd)
lab reset >/dev/null
lab until 2026-03-21 >/dev/null
for f in $(cd "$L/project" && find . -type f ! -name README | sed 's|^\./||'); do put "$f" < "$L/project/$f"; done
for o in after-11 after-12 after-15 after-16 after-17; do
  for f in $(cd "$L/$o" && find . -type f ! -name README ! -name profiles.yml | sed 's|^\./||'); do put "$f" < "$L/$o/$f"; done
done
lab exec 'rm -rf ~/.dbt; mkdir -p ~/.dbt && cat > ~/.dbt/profiles.yml' < "$L/after-17/profiles.yml"
lab exec 'touch landing/prices.jsonl; python load_raw.py >/dev/null; cd shop && dbt build --full-refresh >/dev/null'

# ------------------------------------------------------------ rows or bulk
put insert_speed.py <<'PY'
"""The same 30,000 order lines written into a table three ways, and timed."""
import time

import psycopg

with psycopg.connect("dbname=wh") as wh:
    rows = wh.execute("SELECT order_date, order_id, line_no, shop_id, customer_id, book_id, "
                      "quantity, line_cents FROM dbt_marts.fact_sales LIMIT 30000").fetchall()
    wh.execute("CREATE TEMP TABLE t (LIKE dbt_marts.fact_sales)")
    insert = "INSERT INTO t VALUES (%s, %s, %s, %s, %s, %s, %s, %s)"

    def timed(name, write):
        wh.execute("TRUNCATE t")
        start = time.perf_counter()
        write()
        wh.commit()
        took = time.perf_counter() - start
        print(f"{name:<28}{took:7.2f} s   {len(rows) / took:>10,.0f} rows a second")

    def one_statement_per_row():
        for row in rows:
            wh.execute(insert, row)

    def executemany():
        wh.cursor().executemany(insert, rows)

    def copy():
        with wh.cursor().copy("COPY t FROM STDIN") as cp:
            for row in rows:
                cp.write_row(row)

    timed("one INSERT per row", one_statement_per_row)
    timed("executemany", executemany)
    timed("COPY", copy)
PY
code insert-speed-py insert_speed.py
block rows-or-bulk
on 'python insert_speed.py'

# ------------------------------------------------------------ a large table
put big.sql <<'SQL'
-- Made for this lesson: the real fact table, copied a hundred times, each copy
-- moved back by three weeks more than the last and given order ids of its own.
DROP SCHEMA IF EXISTS big CASCADE;
CREATE SCHEMA big;
CREATE TABLE big.fact_sales AS
SELECT order_date - 21 * k AS order_date, order_id + 1000000 * k AS order_id, line_no,
       shop_id, customer_id, book_id, quantity, line_cents
  FROM dbt_marts.fact_sales, generate_series(0, 99) AS k;
ANALYZE big.fact_sales;
SQL
code big-sql big.sql
block big
on 'psql -q -d wh -c "\timing on" -f big.sql'
on 'psql -d wh -c "SELECT count(*) AS lines, min(order_date), max(order_date), pg_size_pretty(pg_total_relation_size('"'"'big.fact_sales'"'"')) AS size FROM big.fact_sales"'

# ------------------------------------------------------------ one day, found
put one_day.sql <<'SQL'
-- How PostgreSQL finds one day's lines, and how long it takes, without keeping the change.
BEGIN;
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF)
DELETE FROM big.fact_sales WHERE order_date = DATE '2026-03-16';
ROLLBACK;
SQL
code one-day-sql one_day.sql
block no-index
on 'psql -q -d wh -f one_day.sql'
block index
on 'psql -q -d wh -c "\timing on" -c "CREATE INDEX ON big.fact_sales (order_date)"'
on 'psql -q -d wh -f one_day.sql'

# ------------------------------------------------------------ whole or window
put rebuild.sql <<'SQL'
-- Two ways to bring the table up to date, each inside a transaction that is
-- rolled back, so that both start from the same table.
\timing on
BEGIN;
-- 1. rebuild it whole
CREATE TABLE big.fact_sales_new AS SELECT * FROM big.fact_sales;
ROLLBACK;
BEGIN;
-- 2. replace the last thirty days
DELETE FROM big.fact_sales WHERE order_date >= DATE '2026-03-21' - 30;
INSERT INTO big.fact_sales SELECT * FROM dbt_marts.fact_sales WHERE order_date >= DATE '2026-03-21' - 30;
ROLLBACK;
SQL
code rebuild-sql rebuild.sql
block whole-or-window
on 'psql -q -d wh -f rebuild.sql'

# ------------------------------------------------------------ reading less
put read.sql <<'SQL'
-- Revenue for one month, and the pages of the table each query had to read.
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT sum(line_cents) FROM big.fact_sales WHERE order_date BETWEEN DATE '2026-03-01' AND DATE '2026-03-31';
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT sum(line_cents) FROM big.fact_sales;
SQL
code read-sql read.sql
block read-less
on 'psql -q -d wh -f read.sql'
