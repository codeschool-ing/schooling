#!/bin/sh
# One real day of the shop, cut out of its database into files that are kept
# with the tests: every order placed that day in São Paulo, its lines and its
# payments, the customers they name, and every shop and book. Customers keep
# their city and state and lose their name and e-mail.
#   sh tests/make_fixture.sh 2026-03-02
set -e
day=${1:?usage: make_fixture.sh YYYY-MM-DD}
out=tests/fixture
mkdir -p $out
pg_dump -d shop --schema-only --no-owner --no-privileges > $out/schema.sql
orders="SELECT order_id FROM orders WHERE (ordered_at AT TIME ZONE 'America/Sao_Paulo')::date = '$day'"
cut() { psql -q -d shop -c "\copy ($2) TO '$out/$1.csv' WITH (FORMAT csv, HEADER)"; }
cut shops       "SELECT * FROM shops ORDER BY shop_id"
cut books       "SELECT * FROM books ORDER BY book_id"
# Names and e-mails are personal and no test needs them: replaced on the way out.
cut customers   "SELECT customer_id, 'customer ' || customer_id AS name, customer_id || '@example.invalid' AS email, city, state, created_at, updated_at FROM customers WHERE customer_id IN (SELECT customer_id FROM orders WHERE order_id IN ($orders)) ORDER BY customer_id"
cut orders      "SELECT * FROM orders WHERE order_id IN ($orders) ORDER BY order_id"
cut order_lines "SELECT * FROM order_lines WHERE order_id IN ($orders) ORDER BY order_id, line_no"
cut payments    "SELECT * FROM payments WHERE order_id IN ($orders) ORDER BY order_id"
wc -l $out/*.csv
