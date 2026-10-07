#!/bin/sh
# Build the whole warehouse from nothing: a fresh extract of the shop's
# database, the staging layer, every dimension, then the facts that point at
# them.
set -e
rm -rf extract wh.duckdb wh.duckdb.wal
sh extract.sh
for f in staging dim_date dim_shop dim_book dim_customer dim_promotion dim_author \
         fact_sales fact_inventory fact_fulfilment fact_payments fact_event_attendance; do
  duckdb wh.duckdb < $f.sql
done
