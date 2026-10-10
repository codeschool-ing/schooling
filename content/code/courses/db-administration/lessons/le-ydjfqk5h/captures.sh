#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts where lesson 4 leaves the server: shop loaded. Everything the
# lesson bloats and repairs is orders_copy, which the lesson creates and drops,
# so shop ends as it began. postgresql-16-repack comes from apt's cache, as
# every package in this course does; apt's output is not quoted.
#
# The two lock pictures are three psql sessions at once. The session that reads
# pg_locks connects first and waits at a shell command that is typed and not
# printed; the script starts the rebuild in a second session, the reader in a
# third, and then lets the first one go. Their transcripts are printed one
# after the other, in the order the lesson shows them.
set -uo pipefail
export LAB_NAME=${LAB_NAME:-db}
cd "$(dirname "$0")"
. ../../lab/capture.sh
T=$(mktemp -d)

lab reset 15
lab as 'until [ "$(psql -XAtc "SELECT count(*) FROM pg_stat_user_tables WHERE last_autovacuum IS NOT NULL" shop)" = 2 ]; do sleep 2; done'

SIZE="SELECT pg_size_pretty(pg_relation_size('orders_copy')) AS table_size, pg_size_pretty(pg_indexes_size('orders_copy')) AS indexes;"
LOCKS="SELECT l.pid, l.mode, l.granted, a.query FROM pg_locks l JOIN pg_stat_activity a USING (pid) WHERE l.relation = 'orders_copy'::regclass;"

block what-bloat-is
printf "CREATE TABLE orders_copy AS SELECT * FROM orders;\nALTER TABLE orders_copy ADD PRIMARY KEY (id);\nCREATE INDEX orders_copy_customer_id ON orders_copy (customer_id);\nCREATE INDEX orders_copy_created_at ON orders_copy (created_at);\nVACUUM ANALYZE orders_copy;\n%s\nUPDATE orders_copy SET total_cents = total_cents + 1;\nVACUUM orders_copy;\n%s\nSELECT count(*) FROM orders_copy;\n" "$SIZE" "$SIZE" | session shop
block truncate
printf "DELETE FROM orders_copy WHERE id > 900000;\nVACUUM orders_copy;\n%s\nDELETE FROM orders_copy WHERE id > 800000;\nVACUUM orders_copy;\n%s\n" "$SIZE" "$SIZE" | session shop

block measuring
printf "CREATE EXTENSION pgstattuple;\n\\\\timing on\nSELECT table_len, tuple_count, tuple_percent, dead_tuple_count, free_space, free_percent FROM pgstattuple('orders_copy');\nSELECT table_len, scanned_percent, approx_tuple_count, approx_free_percent FROM pgstattuple_approx('orders_copy');\n\\\\timing off\n" | session shop
block estimate
printf "ANALYZE orders_copy;\nSELECT c.relname, c.relpages, ceil(c.reltuples * (24 + 4 + sum(s.avg_width)) / (8192 - 24)) AS expected_pages FROM pg_class c JOIN pg_stats s ON s.schemaname = 'public' AND s.tablename = c.relname WHERE c.relname IN ('orders', 'orders_copy') GROUP BY c.relname, c.relpages, c.reltuples;\n" | session shop

block index-bloat
printf "SELECT i.indexrelid::regclass AS index, pg_size_pretty(s.index_size) AS size, s.avg_leaf_density, s.leaf_fragmentation FROM pg_index i, pgstatindex(i.indexrelid::regclass::text) s WHERE i.indrelid IN ('orders'::regclass, 'orders_copy'::regclass) ORDER BY 1;\n" | session shop

block vacuum-full
lab as 'rm -f /tmp/go'
printf "#quiet \\\\! while [ ! -e /tmp/go ]; do sleep 0.05; done\n%s\n" "$LOCKS" | session shop > "$T/b.out" &
B=$!
lab as 'until [ "$(psql -XAtc "SELECT count(*) FROM pg_stat_activity WHERE datname = '"'shop'"' AND backend_type = '"'client backend'"'" shop)" = 2 ]; do sleep 0.1; done'
printf "\\\\timing on\nVACUUM FULL orders_copy;\n" | session shop > "$T/v.out" &
V=$!
lab as 'until [ "$(psql -XAtc "SELECT count(*) FROM pg_locks WHERE mode = '"'AccessExclusiveLock'"' AND granted AND relation = '"'orders_copy'"'::regclass" shop)" = 1 ]; do sleep 0.02; done'
printf "\\\\timing on\nSELECT count(*) FROM orders_copy;\n" | session shop > "$T/s.out" &
C=$!
lab as 'until [ "$(psql -XAtc "SELECT count(*) FROM pg_locks WHERE NOT granted" shop)" = 1 ]; do sleep 0.02; done; touch /tmp/go'
wait $B $V $C
cat "$T/v.out"; block vacuum-full-select; cat "$T/s.out"; block vacuum-full-locks; cat "$T/b.out"
block vacuum-full-after
printf "%s\n" "$SIZE" | session shop

block repack
printf "UPDATE orders_copy SET total_cents = total_cents + 1;\nVACUUM orders_copy;\n%s\n" "$SIZE" | session shop
lab as 'sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q postgresql-16-repack >/dev/null 2>&1'
printf "CREATE EXTENSION pg_repack;\n" | session shop
lab as 'rm -f /tmp/go'
printf "#quiet \\\\! while [ ! -e /tmp/go ]; do sleep 0.05; done\n%s\n\\\\timing on\nUPDATE orders_copy SET status = 'paid' WHERE id = 3;\n" "$LOCKS" | session shop > "$T/b.out" &
B=$!
lab as 'until [ "$(psql -XAtc "SELECT count(*) FROM pg_stat_activity WHERE datname = '"'shop'"' AND backend_type = '"'client backend'"'" shop)" = 2 ]; do sleep 0.1; done'
( on 'time pg_repack -d shop -t orders_copy' > "$T/r.out" ) &
R=$!
lab as 'until psql -XAtc "SELECT query FROM pg_stat_activity" shop | grep -q "INSERT INTO repack.table_"; do sleep 0.02; done; touch /tmp/go'
wait $B $R
cat "$T/r.out"; block repack-locks; cat "$T/b.out"
block repack-after
printf "%s\n" "$SIZE" | session shop

block steady
printf "UPDATE orders_copy SET total_cents = total_cents + 1 WHERE id %% 5 = 0;\nVACUUM orders_copy;\n%s\nUPDATE orders_copy SET total_cents = total_cents + 1 WHERE id %% 5 = 1;\nVACUUM orders_copy;\n%s\nUPDATE orders_copy SET total_cents = total_cents + 1 WHERE id %% 5 = 2;\nVACUUM orders_copy;\n%s\n" "$SIZE" "$SIZE" "$SIZE" | session shop

block cleanup
printf "DROP TABLE orders_copy;\nDROP EXTENSION pg_repack;\nDROP EXTENSION pgstattuple;\n" | session shop

rm -rf "$T"
lab down
