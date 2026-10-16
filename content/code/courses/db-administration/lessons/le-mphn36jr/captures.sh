#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts where lesson 4 leaves the server: shop loaded. Before the first
# transcript it waits for autovacuum's first visit to both tables, which comes
# about a minute after the load and has long since happened on a student's
# server. Everything the lesson changes happens on orders_copy, which the
# lesson creates and drops, so shop ends as it began.
#
# Two places wait for autovacuum, as the lesson tells the student to: the
# script polls pg_stat_user_tables instead of sleeping a fixed minute. The held
# transaction in "falling-behind" is a second psql session typed in the
# background; it waits at a shell command that is typed and not printed (the
# student simply leaves that terminal alone), and its transcript is printed
# after the other session's, in two fences in the lesson.
#
# The wraparound section makes a scratch cluster, 16/wrap, and pushes its next
# transaction id close to the limit with pg_resetwal, as the lesson shows; the
# cluster is dropped at the end of the section.
set -uo pipefail
export LAB_NAME=${LAB_NAME:-db}
cd "$(dirname "$0")"
. ../../lab/capture.sh
T=$(mktemp -d)

lab reset 14
lab as 'until [ "$(psql -XAtc "SELECT count(*) FROM pg_stat_user_tables WHERE last_autovacuum IS NOT NULL" shop)" = 2 ]; do sleep 2; done'

block dead-rows
printf "CREATE TABLE orders_copy AS SELECT * FROM orders;\nALTER TABLE orders_copy ADD PRIMARY KEY (id);\nVACUUM ANALYZE orders_copy;\nCREATE EXTENSION pageinspect;\nSELECT ctid, xmin, xmax, id, status FROM orders_copy WHERE id = 7;\nBEGIN;\nUPDATE orders_copy SET status = 'shipped' WHERE id = 7;\nSELECT ctid, xmin, xmax, id, status FROM orders_copy WHERE id = 7;\nSELECT lp, t_xmin, t_xmax, t_ctid FROM heap_page_items(get_raw_page('orders_copy', 0)) WHERE lp BETWEEN 6 AND 8;\nCOMMIT;\n" | session shop
printf "BEGIN;\nUPDATE orders_copy SET status = 'shipped' WHERE id = 500000;\nROLLBACK;\n#quiet \\\\! sleep 11\nSELECT n_live_tup, n_dead_tup FROM pg_stat_user_tables WHERE relname = 'orders_copy';\n" | session shop

block what-vacuum-does
V="SELECT pg_size_pretty(pg_relation_size('orders_copy')) AS size, * FROM pg_visibility_map_summary('orders_copy');"
printf "CREATE EXTENSION pg_visibility;\nUPDATE orders_copy SET total_cents = total_cents + 1 WHERE id <= 50000;\n%s\nVACUUM orders_copy;\n%s\nSELECT relname, relfrozenxid, age(relfrozenxid) FROM pg_class WHERE relname = 'orders_copy';\nVACUUM (FREEZE) orders_copy;\n%s\nSELECT relname, relfrozenxid, age(relfrozenxid) FROM pg_class WHERE relname = 'orders_copy';\n" "$V" "$V" "$V" | session shop

block the-trigger
S="SELECT n_dead_tup, last_autovacuum, last_autoanalyze FROM pg_stat_user_tables WHERE relname = 'orders_copy';"
printf "SELECT name, setting, unit FROM pg_settings WHERE name IN ('autovacuum', 'autovacuum_naptime', 'autovacuum_max_workers', 'autovacuum_vacuum_threshold', 'autovacuum_vacuum_scale_factor', 'autovacuum_vacuum_insert_threshold', 'autovacuum_vacuum_insert_scale_factor', 'autovacuum_vacuum_cost_limit', 'autovacuum_vacuum_cost_delay');\nSELECT relname, last_analyze, last_autovacuum, autovacuum_count FROM pg_stat_user_tables WHERE relname IN ('customers', 'orders');\nSELECT reltuples, 50 + 0.2 * reltuples AS vacuum_after, 50 + 0.1 * reltuples AS analyze_after FROM pg_class WHERE relname = 'orders';\nUPDATE orders_copy SET total_cents = total_cents + 1 WHERE id <= 150000;\n" | session shop
lab as 'until [ -n "$(psql -XAtc "SELECT last_autoanalyze FROM pg_stat_user_tables WHERE relname = '"'orders_copy'"'" shop)" ]; do sleep 2; done; sleep 3'
printf "%s\nUPDATE orders_copy SET total_cents = total_cents + 1 WHERE id > 150000 AND id <= 250000;\n" "$S" | session shop
lab as 'until [ -n "$(psql -XAtc "SELECT last_autovacuum FROM pg_stat_user_tables WHERE relname = '"'orders_copy'"'" shop)" ]; do sleep 2; done; sleep 3'
printf "SELECT n_dead_tup, last_autovacuum, autovacuum_count FROM pg_stat_user_tables WHERE relname = 'orders_copy';\n" | session shop

block falling-behind
lab as 'rm -f /tmp/go'
printf "BEGIN ISOLATION LEVEL REPEATABLE READ;\nSELECT count(*) FROM orders_copy;\n#quiet \\\\! while [ ! -e /tmp/go ]; do sleep 0.2; done\nCOMMIT;\n" | session shop > "$T/a.out" &
A=$!
lab as 'until [ "$(psql -XAtc "SELECT count(*) FROM pg_stat_activity WHERE state = '"'idle in transaction'"'" shop)" = 1 ]; do sleep 0.2; done'
printf "UPDATE orders_copy SET total_cents = total_cents + 1 WHERE id <= 100000;\nSELECT pid, state, backend_xmin, xact_start FROM pg_stat_activity WHERE backend_xmin IS NOT NULL;\nVACUUM (VERBOSE, PROCESS_TOAST false) orders_copy;\n" | session shop
lab as 'touch /tmp/go'
wait $A
block falling-behind-a
cat "$T/a.out"
block falling-behind-after
printf "SELECT count(*) FROM pg_stat_activity WHERE state = 'idle in transaction';\nVACUUM (VERBOSE, PROCESS_TOAST false) orders_copy;\n" | session shop

block wraparound
printf "SELECT datname, age(datfrozenxid) FROM pg_database;\nSELECT relname, age(relfrozenxid) FROM pg_class WHERE relkind = 'r' ORDER BY 2 DESC LIMIT 3;\nSHOW autovacuum_freeze_max_age;\n" | session shop
on 'sudo pg_createcluster 16 wrap >/dev/null'
on 'sudo -u postgres /usr/lib/postgresql/16/bin/pg_resetwal -x 2145000000 /var/lib/postgresql/16/wrap'
on 'sudo -u postgres dd if=/dev/zero of=/var/lib/postgresql/16/wrap/pg_xact/07FD bs=256k count=1 status=none'
on 'sudo pg_ctlcluster 16 wrap start'
on 'sudo -u postgres psql -p 5433 -c "SELECT datname, age(datfrozenxid) FROM pg_database;"'
on 'sudo -u postgres psql -p 5433 -c "CREATE TABLE t (i int);"'
on 'sudo -u postgres psql -p 5433 -c "SELECT count(*) FROM pg_class;"'
block wraparound-vacuum
on 'sudo -u postgres vacuumdb -p 5433 --all --freeze 2> vacuum.log'
on 'grep -c "as a failsafe" vacuum.log'
on 'grep -m1 -A3 "as a failsafe" vacuum.log'
on 'grep -A2 "must be vacuumed" vacuum.log'
on 'sudo -u postgres psql -p 5433 -c "SELECT datname, datallowconn, age(datfrozenxid) FROM pg_database;"'
lab as 'until [ "$(sudo -u postgres psql -p 5433 -XAtc "SELECT max(age(datfrozenxid)) < 1000000 FROM pg_database")" = t ]; do sleep 2; done'
block wraparound-after
on 'sudo -u postgres psql -p 5433 -c "SELECT datname, datallowconn, age(datfrozenxid) FROM pg_database;"'
on 'sudo -u postgres psql -p 5433 -c "CREATE TABLE t (i int);"'
on 'sudo pg_dropcluster --stop 16 wrap'
lab as 'rm -f vacuum.log'

block noticing
printf "SELECT relname, n_live_tup, n_dead_tup, last_vacuum, last_autovacuum FROM pg_stat_user_tables ORDER BY n_dead_tup DESC;\nSHOW log_autovacuum_min_duration;\nALTER TABLE orders_copy SET (autovacuum_vacuum_scale_factor = 0.01, log_autovacuum_min_duration = 0);\nSELECT relname, reloptions FROM pg_class WHERE relname = 'orders_copy';\nUPDATE orders_copy SET total_cents = total_cents + 1 WHERE id <= 20000;\n" | session shop
lab as 'until [ "$(psql -XAtc "SELECT autovacuum_count FROM pg_stat_user_tables WHERE relname = '"'orders_copy'"'" shop)" = 2 ]; do sleep 2; done; sleep 2'
on "sudo grep -A10 'automatic vacuum of table \"shop.public.orders_copy\"' /var/log/postgresql/postgresql-16-main.log"

block cleanup
printf "DROP TABLE orders_copy;\nDROP EXTENSION pageinspect;\nDROP EXTENSION pg_visibility;\n" | session shop

rm -rf "$T"
lab down
