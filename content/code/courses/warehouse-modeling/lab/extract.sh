#!/bin/sh
# Copy every table of the shop's database into extract/, one CSV file each.
set -e
mkdir -p extract
for t in shops categories publishers authors books book_authors customers \
         customer_changes promotions orders order_lines payments stock_counts \
         events event_attendance; do
  psql -q -c "\copy $t TO 'extract/$t.csv' WITH (FORMAT csv, HEADER true)"
done
