#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts where lesson 5 starts: PostgreSQL installed, ana's role and
# database, and shop loaded from lesson 4's shop.sql. Nothing is staged beyond
# that. The log sequence numbers, the segment names and the sizes of pg_wal
# move between runs, because the WAL is a position in a stream that the load
# before the lesson has already advanced; the record types pg_waldump prints
# do not. The two pg_waldump commands are given the positions this run's own
# psql printed, which is what the lesson tells the student to do.
#
# The checkpoint the lesson relies on not happening (between the INSERT and
# the grep of the table file) is the timed one, five minutes after the server
# started; the first block runs well inside that.
set -uo pipefail
cd "$(dirname "$0")"
export LAB_NAME=${LAB_NAME:-db}
. ../../lab/capture.sh

D=/var/lib/postgresql/16/main
WALDUMP=/usr/lib/postgresql/16/bin/pg_waldump
TMP=$(mktemp)

lab reset 7

block log-first
printf "CREATE TABLE notes (id int PRIMARY KEY, body text);\nINSERT INTO notes VALUES (1, 'written down first');\nSELECT pg_relation_filepath('notes');\n" | session shop
F=$(lab as "psql -XAtc \"SELECT pg_relation_filepath('notes')\" shop")
on "sudo grep -c 'written down first' $D/$F"
on "sudo grep -rl 'written down first' $D/pg_wal"

block pg-wal
on "sudo ls -l $D/pg_wal | tail -n 4"
on "sudo du -sh $D/pg_wal"
printf "SELECT pg_current_wal_lsn(), pg_walfile_name(pg_current_wal_lsn());\n" | session shop

block waldump-insert
printf "SELECT pg_current_wal_lsn();\nINSERT INTO notes VALUES (2, 'and this one');\nSELECT pg_current_wal_lsn();\n" | session shop | tee "$TMP"
set -- $(grep -Eo '^ [0-9A-F]+/[0-9A-F]+' "$TMP")
on "sudo $WALDUMP -p $D/pg_wal -s $1 -e $2"

block one-row
printf "CHECKPOINT;\nSELECT pg_current_wal_lsn() AS before \\\\gset\nUPDATE orders SET status = 'shipped' WHERE id = 1000000;\nSELECT :'before' AS before, pg_current_wal_lsn() AS after,\n       pg_wal_lsn_diff(pg_current_wal_lsn(), :'before') AS bytes;\nSELECT pg_current_wal_lsn() AS before \\\\gset\nUPDATE orders SET status = 'paid' WHERE id = 1000000;\nSELECT :'before' AS before, pg_current_wal_lsn() AS after,\n       pg_wal_lsn_diff(pg_current_wal_lsn(), :'before') AS bytes;\n" | session shop | tee "$TMP"
L=$(grep -Eo '^ [0-9A-F]+/[0-9A-F]+ +\| [0-9A-F]+/[0-9A-F]+' "$TMP" | tr -d ' ')
S=$(echo "$L" | head -1 | cut -d'|' -f1); E=$(echo "$L" | tail -1 | cut -d'|' -f2)
on "sudo $WALDUMP -p $D/pg_wal -s $S -e $E"

block whole-table
printf "CREATE TABLE orders_copy AS SELECT * FROM orders;\nSELECT pg_size_pretty(pg_relation_size('orders_copy'));\nCHECKPOINT;\nSELECT pg_current_wal_lsn() AS before \\\\gset\nUPDATE orders_copy SET total_cents = total_cents + 1;\nSELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before'));\nSELECT pg_current_wal_lsn() AS before \\\\gset\nUPDATE orders_copy SET total_cents = total_cents - 1;\nSELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before'));\nDROP TABLE orders_copy;\n" | session shop

block depends
printf "SELECT name, setting FROM pg_settings\n WHERE name IN ('wal_level', 'archive_mode', 'max_wal_senders');\n" | session shop

block wal-size
printf "SELECT name, setting, unit FROM pg_settings\n WHERE name IN ('max_wal_size', 'min_wal_size', 'wal_keep_size',\n                'max_slot_wal_keep_size', 'wal_segment_size');\n" | session shop
on "sudo du -sh $D/pg_wal"
printf "CHECKPOINT;\n" | session shop
on "sudo tail -n 1 /var/log/postgresql/postgresql-16-main.log"
on "sudo du -sh $D/pg_wal"

block slot
printf "SELECT pg_create_physical_replication_slot('forgotten', true);\nCREATE TABLE orders_copy AS SELECT * FROM orders;\nUPDATE orders_copy SET total_cents = total_cents + 1;\nCHECKPOINT;\nSELECT slot_name, active, wal_status,\n       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS held\n  FROM pg_replication_slots;\n" | session shop
on "sudo tail -n 1 /var/log/postgresql/postgresql-16-main.log"
printf "SELECT pg_drop_replication_slot('forgotten');\nCHECKPOINT;\n" | session shop
on "sudo tail -n 1 /var/log/postgresql/postgresql-16-main.log"
printf "DROP TABLE orders_copy;\nDROP TABLE notes;\n" | session shop

rm -f "$TMP"
lab down
