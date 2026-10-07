#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of pipelines-etl, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: `lab.sh reset` before the first block;
# and, in the `late` block, the slow till: an order whose transaction began at
# 23:40 on 2 March and committed only after that night's extraction had run.
# This script inserts it into the shop directly, with that timestamp, which is
# what such a till would have left behind. The lesson says so.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "$0")/../../capture.sh"
lab reset >/dev/null
lab day 2026-03-01 >/dev/null

put raw_changes.sql <<'SQL'
-- Every version of a row an incremental extraction has seen, with the moment
-- it was extracted. Nothing is ever updated here; a later version is a new row.
CREATE SCHEMA IF NOT EXISTS raw;
CREATE TABLE IF NOT EXISTS raw.orders_changes (
  order_id integer, shop_id integer, customer_id integer, ordered_at timestamptz,
  status text, updated_at timestamptz, extracted_at timestamptz NOT NULL);
CREATE TABLE IF NOT EXISTS raw.customers_changes (
  customer_id integer, name text, email text, city text, state text,
  created_at timestamptz, updated_at timestamptz, extracted_at timestamptz NOT NULL);
CREATE TABLE IF NOT EXISTS etl_state (
  source    text PRIMARY KEY,
  watermark timestamptz NOT NULL);
SQL
put incremental.py <<'PY'
"""Copy the rows of a shop table that changed since the last run."""
import sys

import psycopg
from psycopg import sql

table = sys.argv[1]                                  # orders or customers
lookback = int(sys.argv[2]) if len(sys.argv) > 2 else 0   # minutes to re-read
source = f"shop.{table}" + (f"+{lookback}m" if lookback else "")
target = sql.Identifier("raw", f"{table}_changes" + (f"_{lookback}m" if lookback else ""))

with psycopg.connect("dbname=wh") as wh, psycopg.connect("dbname=shop") as shop:
    wh.execute(sql.SQL("CREATE TABLE IF NOT EXISTS {} (LIKE raw.{})").format(
        target, sql.Identifier(f"{table}_changes")))
    found = wh.execute("SELECT watermark FROM etl_state WHERE source = %s FOR UPDATE",
                       (source,)).fetchone()
    since = found[0] if found else None

    shop.execute("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY")
    until = shop.execute(sql.SQL("SELECT max(updated_at) FROM {}").format(
        sql.Identifier(table))).fetchone()[0]
    query = sql.SQL("SELECT *, now() FROM {} WHERE updated_at <= %s").format(sql.Identifier(table))
    params = [until]
    if since is not None:
        query += sql.SQL(" AND updated_at > %s::timestamptz - make_interval(mins => %s)")
        params += [since, lookback]
    rows = shop.execute(query, params).fetchall()

    if rows:
        insert = sql.SQL("INSERT INTO {} VALUES ({})").format(
            target, sql.SQL(", ").join([sql.Placeholder()] * len(rows[0])))
        wh.cursor().executemany(insert, rows)

    wh.execute("""INSERT INTO etl_state VALUES (%s, %s)
                  ON CONFLICT (source) DO UPDATE SET watermark = excluded.watermark""",
               (source, until))
print(f"{source}: {len(rows)} rows since {since:%m-%d %H:%M:%S}, watermark now {until:%m-%d %H:%M:%S}"
      if since else f"{source}: {len(rows)} rows, the first run, watermark now {until:%m-%d %H:%M:%S}")
PY
put full_customers.py <<'PY'
"""Replace raw.customers with a complete copy of the shop's customers."""
import psycopg

with psycopg.connect("dbname=shop") as shop, psycopg.connect("dbname=wh") as wh:
    wh.execute("""CREATE TABLE IF NOT EXISTS raw.customers (
                    customer_id integer, name text, email text, city text, state text,
                    created_at timestamptz, updated_at timestamptz)""")
    wh.execute("TRUNCATE raw.customers")
    src, dst = shop.cursor(), wh.cursor()
    with src.copy("COPY customers TO STDOUT") as out, \
         dst.copy("COPY raw.customers FROM STDIN") as into:
        for chunk in out:
            into.write(chunk)
print(f"raw.customers: {src.rowcount} rows, all of them")
PY
code raw-changes-sql raw_changes.sql
code incremental-py incremental.py
code full-py full_customers.py
lab exec 'psql -q -d wh -f raw_changes.sql'

block full1
on 'python full_customers.py'
block night1

on 'python incremental.py customers'

on 'python incremental.py orders'
on 'python incremental.py orders 60'

block night2
root 'day 2026-03-02'
block full2
on 'python full_customers.py'
block night2-incremental

on 'python incremental.py orders'
on 'python incremental.py orders 60'
block state
on 'psql -d wh -c "SELECT * FROM etl_state ORDER BY source"'

block late
lab exec "psql -q -c \"INSERT INTO orders VALUES (900001, 1, NULL, '2026-03-02 23:40:00-03', 'completed', '2026-03-02 23:40:00-03'); INSERT INTO order_lines VALUES (900001, 1, 17, 1, 4990); INSERT INTO payments VALUES (990001, 900001, 'cash', 4990, '2026-03-02 23:40:50-03')\""
on "psql -c \"SELECT order_id, ordered_at, updated_at FROM orders WHERE order_id = 900001\""
root 'day 2026-03-03'
on 'python incremental.py orders'
on 'python incremental.py orders 60'
on "psql -d wh -c \"SELECT 'no lookback' AS run, count(*) FROM raw.orders_changes WHERE order_id = 900001 UNION ALL SELECT '60 minutes', count(*) FROM raw.orders_changes_60m WHERE order_id = 900001\""

block twice
on "psql -d wh -c \"SELECT count(*) AS rows, count(DISTINCT (order_id, updated_at)) AS versions FROM raw.orders_changes_60m\""

block versions
on "psql -d wh -c \"SELECT order_id, status, updated_at, extracted_at FROM raw.orders_changes WHERE order_id IN (SELECT order_id FROM raw.orders_changes GROUP BY order_id HAVING count(*) > 1) ORDER BY order_id, updated_at LIMIT 4\""
put latest.sql <<'SQL'
-- The latest version of each order the extraction has seen.
CREATE OR REPLACE VIEW raw.orders_latest AS
SELECT DISTINCT ON (order_id) *
  FROM raw.orders_changes
 ORDER BY order_id, updated_at DESC, extracted_at DESC;
SQL
code latest-sql latest.sql
block latest
on 'psql -q -d wh -f latest.sql'
on "psql -d wh -c \"SELECT (SELECT count(*) FROM raw.orders_changes) AS versions, (SELECT count(*) FROM raw.orders_latest) AS orders\""
on "psql -c \"SELECT count(*) AS orders FROM orders WHERE updated_at <= '2026-03-03 23:59:59-03'\""

block deletes
root 'until 2026-03-14'
on 'grep -A2 "SET customer_id = NULL" /var/lib/etl-data/days/2026-03-14.sql'
on 'python incremental.py customers'
on 'python full_customers.py'
on "psql -c \"SELECT count(*) AS in_the_shop FROM customers WHERE customer_id = 1880\""
on "psql -d wh -c \"SELECT (SELECT count(*) FROM raw.customers_changes WHERE customer_id = 1880) AS incremental, (SELECT count(*) FROM raw.customers WHERE customer_id = 1880) AS full_copy\""
