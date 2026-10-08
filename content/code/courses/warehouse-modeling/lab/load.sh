#!/bin/sh
# Load the generated files in data/ into the shop's database, one table each,
# every table before the tables that point at it.
set -e
for t in shops categories publishers authors books book_authors customers \
         customer_changes promotions orders order_lines payments stock_counts \
         events event_attendance; do
  psql -q -c "\copy $t FROM 'data/$t.csv' WITH (FORMAT csv, HEADER true)"
done
psql -q -c 'VACUUM ANALYZE'
