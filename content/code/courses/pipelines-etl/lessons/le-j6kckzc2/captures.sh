#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of pipelines-etl, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: `lab.sh reset` before the first block.
# The files ana writes are written by `put` and shown in the lesson as they
# are.
#
# Timings are one run each, on a machine shared with other work, and move from
# run to run; the lesson says so where it quotes one.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "$0")/../../capture.sh"
lab reset >/dev/null

block week
root 'until 2026-03-07'

put etl.py <<'PY'
"""ETL: books and revenue by day and category, worked out in Python before
anything reaches the warehouse."""
import collections
import datetime as dt
import sys

import psycopg

first, last = (dt.date.fromisoformat(a) for a in sys.argv[1:3])
with psycopg.connect("dbname=shop") as shop:
    rows = shop.execute(
        """SELECT o.ordered_at, o.status, b.category, l.quantity, l.unit_price_cents
             FROM orders o
             JOIN order_lines l USING (order_id)
             JOIN books b USING (book_id)
            WHERE o.ordered_at >= %s AND o.ordered_at < %s""",
        (first, last + dt.timedelta(days=1)),
    ).fetchall()

totals = collections.defaultdict(lambda: [0, 0])
for ordered_at, status, category, quantity, price in rows:
    if status != "completed":
        continue
    key = (ordered_at.date(), category)
    totals[key][0] += quantity
    totals[key][1] += quantity * price

with psycopg.connect("dbname=wh") as wh:
    wh.execute("""CREATE TABLE IF NOT EXISTS etl_sales_by_category (
                    day date, category text, books integer, revenue_cents bigint)""")
    wh.execute("DELETE FROM etl_sales_by_category WHERE day BETWEEN %s AND %s", (first, last))
    with wh.cursor() as cur:
        cur.executemany("INSERT INTO etl_sales_by_category VALUES (%s, %s, %s, %s)",
                        [(d, c, b, r) for (d, c), (b, r) in sorted(totals.items())])
print(f"read {len(rows)} rows from the shop, wrote {len(totals)} to the warehouse")
PY
code etl-py etl.py
block etl
on 'time python etl.py 2026-03-01 2026-03-07'
block etl-top
on 'psql -d wh -c "SELECT * FROM etl_sales_by_category WHERE day = '"'"'2026-03-07'"'"' ORDER BY revenue_cents DESC LIMIT 5"'

put extract_load.py <<'PY'
"""ELT, first half: copy the shop's rows for a range of days into the
warehouse's raw schema, exactly as they are."""
import datetime as dt
import sys

import psycopg
from psycopg import sql

first, last = (dt.date.fromisoformat(a) for a in sys.argv[1:3])
window = sql.SQL("ordered_at >= {} AND ordered_at < {}").format(
    sql.Literal(first), sql.Literal(last + dt.timedelta(days=1)))
QUERIES = {
    "orders": sql.SQL("SELECT * FROM orders WHERE {}").format(window),
    "order_lines": sql.SQL("SELECT l.* FROM order_lines l JOIN orders o USING (order_id)"
                           " WHERE {}").format(window),
    "books": sql.SQL("SELECT * FROM books"),
}

with psycopg.connect("dbname=shop") as shop, psycopg.connect("dbname=wh") as wh:
    wh.execute("CREATE SCHEMA IF NOT EXISTS raw")
    wh.execute(open("raw.sql").read())
    wh.execute("DELETE FROM raw.order_lines WHERE order_id IN (SELECT order_id FROM raw.orders"
               " WHERE {})".format(window.as_string(wh)))
    wh.execute("DELETE FROM raw.orders WHERE {}".format(window.as_string(wh)))
    wh.execute("TRUNCATE raw.books")
    for table, query in QUERIES.items():
        src, dst = shop.cursor(), wh.cursor()
        with src.copy(sql.SQL("COPY ({}) TO STDOUT").format(query)) as out, \
             dst.copy(sql.SQL("COPY raw.{} FROM STDIN").format(sql.Identifier(table))) as into:
            for chunk in out:
                into.write(chunk)
        print(f"raw.{table}: {src.rowcount} rows")
PY
put raw.sql <<'SQL'
-- The raw layer: the shop's tables as the shop has them, no keys enforced and
-- nothing cleaned. Created once; extract_load.py fills it.
CREATE TABLE IF NOT EXISTS raw.orders (
  order_id integer, shop_id integer, customer_id integer,
  ordered_at timestamptz, status text, updated_at timestamptz);
CREATE TABLE IF NOT EXISTS raw.order_lines (
  order_id integer, line_no integer, book_id integer,
  quantity integer, unit_price_cents integer);
CREATE TABLE IF NOT EXISTS raw.books (
  book_id integer, isbn text, title text, category text, publisher text,
  list_price_cents integer, updated_at timestamptz);
SQL
put sales_by_category.sql <<'SQL'
-- ELT, second half: the same question, answered inside the warehouse.
DROP TABLE IF EXISTS elt_sales_by_category;
CREATE TABLE elt_sales_by_category AS
SELECT (o.ordered_at AT TIME ZONE 'America/Sao_Paulo')::date AS day,
       b.category,
       sum(l.quantity)::integer AS books,
       sum(l.quantity * l.unit_price_cents)::bigint AS revenue_cents
  FROM raw.orders o
  JOIN raw.order_lines l USING (order_id)
  JOIN raw.books b USING (book_id)
 WHERE o.status = 'completed'
 GROUP BY 1, 2;
SQL
code extract-load-py extract_load.py
code raw-sql raw.sql
code sales-sql sales_by_category.sql
block elt
on 'time python extract_load.py 2026-03-01 2026-03-07'
block transform
on 'time psql -d wh -f sales_by_category.sql'

block compare
on 'psql -d wh -c "SELECT count(*) FROM (SELECT * FROM etl_sales_by_category EXCEPT SELECT * FROM elt_sales_by_category) AS only_etl"'
on 'psql -d wh -c "SELECT count(*) FROM (SELECT * FROM elt_sales_by_category EXCEPT SELECT * FROM etl_sales_by_category) AS only_elt"'

block sizes
on "psql -d wh -c \"SELECT relname, n_live_tup AS rows, pg_size_pretty(pg_total_relation_size(relid)) AS size FROM pg_stat_user_tables ORDER BY relname\""

block publisher
on "psql -d wh -c \"SELECT b.publisher, sum(l.quantity) AS books FROM raw.orders o JOIN raw.order_lines l USING (order_id) JOIN raw.books b USING (book_id) WHERE o.status = 'completed' GROUP BY 1 ORDER BY 2 DESC LIMIT 3\""

block sent
on 'psql -d wh -c "CREATE TABLE sent_report AS SELECT * FROM etl_sales_by_category"'
on 'psql -d wh -c "SELECT sum(books) AS books, sum(revenue_cents) AS revenue_cents FROM sent_report"'
block reproduce-etl
root 'until 2026-03-11'
on 'python etl.py 2026-03-01 2026-03-07'
on 'psql -d wh -c "SELECT sum(books) AS books, sum(revenue_cents) AS revenue_cents FROM etl_sales_by_category WHERE day <= '"'"'2026-03-07'"'"'"'
block reproduce-elt
on 'psql -d wh -f sales_by_category.sql'
on 'psql -d wh -c "SELECT sum(books) AS books, sum(revenue_cents) AS revenue_cents FROM elt_sales_by_category"'

block schemas
on 'psql -d wh -c "\dn"'
on 'psql -d wh -c "\dt raw.*"'
