#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of db-reliability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the machine as lesson 1 leaves it (`lab.sh base`). The waits
# between commands (`sleep`) are the author's, so that the archiver has had
# time to act before the next question; a student typing by hand waits longer
# than that without trying.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/lib.sh

lab base

block segments
on 'sudo ls -l /var/lib/postgresql/16/main/pg_wal'
printf "SELECT pg_current_wal_lsn(), pg_walfile_name(pg_current_wal_lsn());\n" | session shop

block measure
printf "SELECT pg_current_wal_lsn() AS before \\\\gset\nUPDATE orders SET total_cents = total_cents + 1;\nSELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before'));\n" | session shop

block switch
printf "SELECT pg_walfile_name(pg_current_wal_lsn());\nSELECT pg_switch_wal();\n" | session shop

block archive-dir
on 'sudo -u postgres mkdir /var/lib/postgresql/wal-archive'
on 'sudo -u postgres chmod 700 /var/lib/postgresql/wal-archive'

block configure
printf "ALTER SYSTEM SET archive_mode = on;\nALTER SYSTEM SET archive_command = 'test ! -f /var/lib/postgresql/wal-archive/%%f && cp %%p /var/lib/postgresql/wal-archive/%%f';\n" | session shop
on 'sudo pg_ctlcluster 16 main restart'
printf "SHOW archive_mode;\nSELECT archived_count, last_archived_wal, failed_count FROM pg_stat_archiver;\n" | session shop

block first-archive
printf "SELECT pg_switch_wal();\n" | session shop
sleep 2
printf "SELECT archived_count, last_archived_wal, last_archived_time, failed_count FROM pg_stat_archiver;\n" | session shop
on 'sudo ls -l /var/lib/postgresql/wal-archive'

block break
on 'sudo chmod 500 /var/lib/postgresql/wal-archive'
printf "UPDATE orders SET total_cents = total_cents + 1;\nSELECT pg_switch_wal();\n" | session shop
sleep 3
printf "SELECT archived_count, last_archived_wal, failed_count, last_failed_wal FROM pg_stat_archiver;\n" | session shop
on 'sudo tail -n 4 /var/log/postgresql/postgresql-16-main.log'

block pile-up
on 'sudo ls /var/lib/postgresql/16/main/pg_wal/archive_status'
shell <<'SH'
for i in 1 2 3 4 5 6; do psql -q shop -c "UPDATE orders SET total_cents = total_cents + 1" -c "SELECT pg_switch_wal()" > /dev/null; done
sudo ls /var/lib/postgresql/16/main/pg_wal/archive_status | grep -c ready
sudo du -sh /var/lib/postgresql/16/main/pg_wal
SH

block fix
on 'sudo chmod 700 /var/lib/postgresql/wal-archive'
sleep 65
printf "SELECT archived_count, last_archived_wal, failed_count FROM pg_stat_archiver;\n" | session shop
on 'sudo ls /var/lib/postgresql/16/main/pg_wal/archive_status | grep -c ready'

block quiet
printf "SELECT last_archived_wal, last_archived_time FROM pg_stat_archiver;\nINSERT INTO orders (customer_id, total_cents, placed_at) VALUES (7, 1250, now());\nSELECT pg_walfile_name(pg_current_wal_lsn()), now();\n" | session shop
sleep 30
printf "SELECT last_archived_wal, last_archived_time, now() FROM pg_stat_archiver;\n" | session shop

block timeout
printf "ALTER SYSTEM SET archive_timeout = '60s';\nSELECT pg_reload_conf();\nINSERT INTO orders (customer_id, total_cents, placed_at) VALUES (8, 990, now());\nSELECT pg_walfile_name(pg_current_wal_lsn()), now();\n" | session shop
sleep 75
printf "SELECT last_archived_wal, last_archived_time FROM pg_stat_archiver;\n" | session shop

block receivewal
on 'mkdir walstream'
on 'pg_receivewal --create-slot --slot=walstream'
on 'pg_receivewal -D walstream --slot=walstream > walstream.log 2>&1 &'
sleep 2
printf "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (9, 4400, now());\nSELECT pg_walfile_name(pg_current_wal_lsn());\n" | session shop
sleep 1
on 'ls -l walstream'

block slot
lab exec 'pkill -u ana -x pg_receivewal' || true
sleep 1
printf "SELECT slot_name, active, restart_lsn FROM pg_replication_slots;\n" | session shop
on 'pg_receivewal --drop-slot --slot=walstream'
