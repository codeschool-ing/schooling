#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of pipelines-etl, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: `lab.sh reset` and a week of trade
# before the first block, and the price API. The project files are copied into
# ~/etl from ../../lab/project, where they are kept for the lessons after this
# one; the lesson shows each of them.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "$0")/../../capture.sh"
P=$(cd "$(dirname "$0")/../../lab/project" && pwd)
lab reset >/dev/null
lab until 2026-03-07 >/dev/null
lab api >/dev/null
for f in load_raw.py prices.py run_sql.sh sql/staging/00_schema.sql sql/staging/orders.sql \
         sql/staging/order_lines.sql sql/staging/books.sql sql/staging/prices.sql \
         sql/staging/events.sql sql/marts/00_schema.sql sql/marts/daily_sales.sql; do
  put "$f" < "$P/$f"
done

code load-raw-py load_raw.py
block load
on 'python prices.py 2000-01-01T00:00:00-03:00 landing/prices.jsonl'
on 'python load_raw.py'

block messy
put find_problems.sql <<'SQL'
-- One example of each kind of trouble in the publishers' feed.
SELECT DISTINCT ON (problem)
       problem, doc->>'isbn' AS isbn, format('%L', doc->>'publisher') AS publisher,
       doc->'list_price_cents' AS price, doc->>'currency' AS currency
  FROM (SELECT doc,
               CASE WHEN doc->>'isbn' LIKE '%-%' THEN 'hyphens in the isbn'
                    WHEN jsonb_typeof(doc->'list_price_cents') = 'string' THEN 'price as text'
                    WHEN doc->>'publisher' <> trim(doc->>'publisher') THEN 'space in the name'
                    WHEN doc->'list_price_cents' = 'null' THEN 'no price'
               END AS problem
          FROM raw.prices) AS feed
 WHERE problem IS NOT NULL
 ORDER BY problem, doc->>'isbn';
SQL
code find-sql find_problems.sql
on 'psql -d wh -f find_problems.sql'
on "psql -d wh -c \"SELECT count(*) AS prices, count(b.book_id) AS matching_a_book FROM raw.prices p LEFT JOIN raw.books b ON b.isbn = p.doc->>'isbn'\""

code prices-sql sql/staging/prices.sql
block clean
on 'psql -q -d wh -f sql/staging/00_schema.sql -f sql/staging/prices.sql'
on "psql -d wh -c \"SELECT count(*) AS prices, count(b.book_id) AS matching_a_book FROM staging.prices p LEFT JOIN raw.books b USING (isbn)\""
on "psql -d wh -c \"SELECT publisher, currency, count(*) FROM staging.prices WHERE publisher IN ('Maré', 'Farol', 'Granito') GROUP BY 1, 2 ORDER BY 1\""

code events-sql sql/staging/events.sql
block dedupe
on 'psql -q -d wh -f sql/staging/events.sql'
on "psql -d wh -c \"SELECT (SELECT count(*) FROM raw.events) AS delivered, (SELECT count(*) FROM staging.events) AS events\""

block fanout
on "psql -d wh -c \"SELECT sum(p.amount_cents) AS revenue_cents FROM raw.orders o JOIN raw.payments p USING (order_id) WHERE o.status = 'completed'\""
on "psql -d wh -c \"SELECT sum(p.amount_cents) AS revenue_cents FROM raw.orders o JOIN raw.payments p USING (order_id) JOIN raw.order_lines l USING (order_id) WHERE o.status = 'completed'\""
on "psql -d wh -c \"SELECT count(*) AS orders, (SELECT count(*) FROM raw.orders o JOIN raw.order_lines l USING (order_id) WHERE o.status = 'completed') AS after_the_join FROM raw.orders WHERE status = 'completed'\""

code orders-sql sql/staging/orders.sql
code lines-sql sql/staging/order_lines.sql
block zones
on "psql -d wh -c \"SELECT (ordered_at AT TIME ZONE 'America/Sao_Paulo')::date AS sao_paulo_day, count(*) FROM raw.orders WHERE ordered_at >= '2026-03-06' AND ordered_at < '2026-03-08' GROUP BY 1 ORDER BY 1\""
on "PGTZ=UTC psql -d wh -c \"SELECT ordered_at::date AS utc_day, count(*) FROM raw.orders WHERE ordered_at >= '2026-03-06 00:00-03' AND ordered_at < '2026-03-08 00:00-03' GROUP BY 1 ORDER BY 1\""

code daily-sql sql/marts/daily_sales.sql
code run-sh run_sql.sh
block build
on 'sh run_sql.sh'
on "psql -d wh -c \"SELECT order_date, sum(books) AS books, sum(revenue_cents) AS revenue_cents FROM marts.daily_sales WHERE order_date >= '2026-03-01' GROUP BY 1 ORDER BY 1\""

block reconcile
on "psql -d wh -c \"SELECT (SELECT sum(revenue_cents) FROM marts.daily_sales) AS mart, (SELECT sum(l.quantity * l.unit_price_cents) FROM raw.order_lines l JOIN raw.orders o USING (order_id) WHERE o.status = 'completed') AS lines, (SELECT sum(p.amount_cents) FROM raw.payments p JOIN raw.orders o USING (order_id) WHERE o.status = 'completed') AS payments\""
lab api-down
