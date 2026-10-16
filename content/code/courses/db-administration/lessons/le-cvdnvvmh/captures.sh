#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts where lesson 5 starts: PostgreSQL installed, ana's role and
# database, and shop loaded from lesson 4's shop.sql. The lesson makes its own
# pgbench database, bench, and drops it at the end.
#
# WHAT THE NUMBERS ARE. pgbench's transactions per second were measured on
# the recording computer, whose 4 processors and one disk were shared with
# other work while it ran; the lesson quotes them as this run's and argues
# from the ratio between two runs made one after the other, never from either
# number alone. The checkpoint counts and WAL volumes come from a fixed number
# of transactions and move much less between runs.
#
# THE CRASH is kill -9 of the postmaster, as the lesson tells the student to
# do it. That kills the server's processes and nothing else: the operating
# system and its page cache survive, which a power cut would not. The lesson
# says so. The two background writers (the acknowledging psql and pgbench) are
# started as ana in the background exactly as the lesson prints them.
set -uo pipefail
cd "$(dirname "$0")"
export LAB_NAME=${LAB_NAME:-db}
. ../../lab/capture.sh

D=/var/lib/postgresql/16/main
LOG=/var/log/postgresql/postgresql-16-main.log

lab reset 8

block dirty
printf "CREATE EXTENSION IF NOT EXISTS pg_buffercache;\nCREATE TABLE notes (id int PRIMARY KEY, body text);\nINSERT INTO notes VALUES (1, 'written down first');\nSELECT pg_relation_filepath('notes');\nSELECT count(*) AS dirty FROM pg_buffercache WHERE isdirty;\n" | session shop
F=$(lab as "psql -XAtc \"SELECT pg_relation_filepath('notes')\" shop")
on "sudo grep -c 'written down first' $D/$F"
printf "CHECKPOINT;\nSELECT count(*) AS dirty FROM pg_buffercache WHERE isdirty;\n" | session shop
on "sudo grep -c 'written down first' $D/$F"

block control
on "sudo /usr/lib/postgresql/16/bin/pg_controldata $D | grep -E 'state|checkpoint location|REDO'"
on "sudo tail -n 2 $LOG"

block settings
printf "SELECT name, setting, unit FROM pg_settings\n WHERE name IN ('checkpoint_timeout', 'max_wal_size', 'checkpoint_completion_target',\n                'checkpoint_warning', 'log_checkpoints');\n" | session shop

block bench-init
on 'createdb bench'
on 'pgbench -i -s 20 -q bench'

block small-wal
printf "ALTER SYSTEM SET max_wal_size = '64MB';\nSELECT pg_reload_conf();\nCHECKPOINT;\nSELECT pg_stat_reset_shared('bgwriter'), pg_stat_reset_shared('wal');\n" | session bench
on 'pgbench -n -c 4 -t 10000 bench'
on "sudo tail -n 5 $LOG"
printf "SELECT checkpoints_timed, checkpoints_req FROM pg_stat_bgwriter;\nSELECT wal_records, wal_fpi, pg_size_pretty(wal_bytes) AS wal FROM pg_stat_wal;\n" | session bench

block default-wal
printf "ALTER SYSTEM RESET max_wal_size;\nSELECT pg_reload_conf();\nCHECKPOINT;\nSELECT pg_stat_reset_shared('bgwriter'), pg_stat_reset_shared('wal');\n" | session bench
on 'pgbench -n -c 4 -t 10000 bench | tail -n 1'
printf "SELECT checkpoints_timed, checkpoints_req FROM pg_stat_bgwriter;\nSELECT wal_records, wal_fpi, pg_size_pretty(wal_bytes) AS wal FROM pg_stat_wal;\nSHOW full_page_writes;\nSHOW wal_compression;\n" | session bench

block crash
printf "CREATE TABLE acks (id int PRIMARY KEY);\n" | session shop
on "seq 1 1000000 | sed 's/.*/INSERT INTO acks VALUES (&) RETURNING id;/' | psql -XAtq shop > acked.txt 2> acked.err &"
on 'pgbench -n -c 4 -T 120 bench > bench.out 2>&1 &'
lab as 'sleep 10'
on 'wc -l acked.txt'
on "sudo kill -9 \$(sudo head -n 1 $D/postmaster.pid)"
lab as 'sleep 3'
on 'tail -n 1 acked.txt'
on 'cat acked.err'
on 'tail -n 2 bench.out'
on 'pg_lsclusters'
on 'sudo systemctl start postgresql@16-main'
on "sudo tail -n 11 $LOG"
printf "SELECT max(id), count(*) FROM acks;\n" | session shop

block sync
printf "SHOW fsync;\nSHOW synchronous_commit;\nSHOW wal_writer_delay;\n" | session shop
on "pgbench -n -c 4 -T 30 bench | grep -E 'processed|latency|tps'"
on "PGOPTIONS='-c synchronous_commit=off' pgbench -n -c 4 -T 30 bench | grep -E 'processed|latency|tps'"

block cleanup
printf "DROP TABLE acks;\nDROP TABLE notes;\n" | session shop
on 'dropdb bench'
on 'rm acked.txt acked.err bench.out'

lab down
