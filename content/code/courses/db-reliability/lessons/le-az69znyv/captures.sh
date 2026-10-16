#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of db-reliability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the machine as lessons 5 and 12 leave it, rebuilt quietly:
# `lab.sh base`; pgBackRest with lesson 5's pgbackrest.conf, archive_command
# and stanza `main`, and one full backup; the role replicator with its .pgpass;
# the standby 16/standby on port 5434 built with application_name=standby1 and
# slot standby1, asynchronous (lesson 12's synchronous_standby_names is not
# carried over); and the database bench from `pgbench -i -s 10`.
#
# lagcheck.sh is taken out of this lesson's .md, so the file the student copies
# is the file that ran. The waits (`sleep`) give the standby time to report
# and pgbench time to make log.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, pgBackRest 2.50,
# TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/lib.sh
L5=../le-62bgpm2d

lab base
extract $L5/setting-up.md pgbackrest.conf | lab exec 'sudo tee /etc/pgbackrest.conf > /dev/null'
printf "ALTER SYSTEM SET archive_mode = on;\nALTER SYSTEM SET archive_command = 'pgbackrest --stanza=main archive-push %%p';\n" | lab psql shop >/dev/null
lab exec 'sudo pg_ctlcluster 16 main restart'
lab exec 'sudo -u postgres pgbackrest --stanza=main stanza-create >/dev/null && sudo -u postgres pgbackrest --stanza=main backup --type=full >/dev/null'
printf "CREATE ROLE replicator LOGIN REPLICATION PASSWORD 'replica-pass-1';\n" | lab psql shop >/dev/null
lab exec "echo '127.0.0.1:5432:*:replicator:replica-pass-1' | sudo -u postgres tee /var/lib/postgresql/.pgpass > /dev/null && sudo -u postgres chmod 600 /var/lib/postgresql/.pgpass"
lab exec 'sudo pg_createcluster 16 standby --port 5434 >/dev/null && sudo rm -rf /var/lib/postgresql/16/standby'
lab exec "sudo -u postgres pg_basebackup -d 'host=127.0.0.1 port=5432 user=replicator application_name=standby1' -D /var/lib/postgresql/16/standby -R -C -S standby1 -X stream -c fast"
lab exec 'sudo pg_ctlcluster 16 standby start'
lab exec 'createdb bench && pgbench -q -i -s 10 bench > /dev/null 2>&1'
extract lag-alerts.md lagcheck.sh | lab exec 'cat > lagcheck.sh && chmod +x lagcheck.sh'
sleep 3

LAG="SELECT application_name, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS behind, write_lag, flush_lag, replay_lag FROM pg_stat_replication;"

block busy
on 'pgbench -c 4 -T 20 -n bench > /dev/null 2>&1 &'
sleep 8
printf "\\\\x\n$LAG\n" | session shop
sleep 14

block idle
printf "$LAG\n" | session shop
printf "SELECT now() - pg_last_xact_replay_timestamp() AS since_last_replay;\n" | session shop -p 5434
sleep 20
printf "SELECT now() - pg_last_xact_replay_timestamp() AS since_last_replay;\n" | session shop -p 5434
printf "SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn();\n" | session shop -p 5434
printf "SELECT pg_current_wal_lsn();\n" | session shop

block pause
printf "SELECT pg_wal_replay_pause();\n" | session shop -p 5434
on 'pgbench -c 4 -T 10 -n bench > /dev/null 2>&1'
printf "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (31, 3100, now()) RETURNING id;\n" | session shop
sleep 2
printf "$LAG\n" | session shop
printf "SELECT count(*) FROM orders WHERE customer_id = 31 AND total_cents = 3100;\n" | session shop -p 5434

block lsn
shell <<'SH'
lsn=$(psql -XAt shop -c "SELECT pg_current_wal_lsn()")
echo $lsn
psql -XAt -p 5434 shop -c "SELECT pg_last_wal_replay_lsn() >= '$lsn'"
SH

block resume
printf "SELECT pg_wal_replay_resume();\n" | session shop -p 5434
sleep 2
shell <<'SH'
psql -XAt -p 5434 shop -c "SELECT pg_last_wal_replay_lsn() >= '$(psql -XAt shop -c 'SELECT pg_current_wal_lsn()')'"
psql -XAt -p 5434 shop -c "SELECT count(*) FROM orders WHERE customer_id = 31 AND total_cents = 3100"
SH

block naive
on "psql -XAt shop -c \"SELECT application_name FROM pg_stat_replication WHERE pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) > 64 * 1024 * 1024\""
on 'sudo pg_ctlcluster 16 standby stop'
on "psql -XAt shop -c \"SELECT application_name FROM pg_stat_replication WHERE pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) > 64 * 1024 * 1024\"; echo \"exit \$?\""

block check
on './lagcheck.sh standby1; echo "exit $?"'
on 'sudo pg_ctlcluster 16 standby start'
sleep 3
on './lagcheck.sh standby1; echo "exit $?"'
printf "SELECT pg_wal_replay_pause();\n" | lab psql shop -p 5434 >/dev/null
on 'pgbench -c 4 -T 40 -n bench > /dev/null 2>&1'
on './lagcheck.sh standby1; echo "exit $?"'
printf "SELECT pg_wal_replay_resume();\n" | lab psql shop -p 5434 >/dev/null
sleep 5

block restore-command
on "sudo -u postgres psql -p 5434 -c \"ALTER SYSTEM SET restore_command = 'pgbackrest --stanza=main archive-get %f \\\"%p\\\"'\""
on 'sudo pg_ctlcluster 16 standby restart'

block lose
on 'sudo pg_ctlcluster 16 standby stop'
printf "ALTER SYSTEM SET max_slot_wal_keep_size = '32MB';\nSELECT pg_reload_conf();\nUPDATE orders SET total_cents = total_cents + 1;\nUPDATE orders SET total_cents = total_cents + 1;\nUPDATE orders SET total_cents = total_cents + 1;\nCHECKPOINT;\nSELECT slot_name, wal_status FROM pg_replication_slots;\n" | session shop
on 'sudo -u postgres pgbackrest --stanza=main info | grep wal'

block back
on 'sudo pg_ctlcluster 16 standby start'
sleep 8
on 'sudo grep -E "ERROR: \[|FATAL" /var/log/postgresql/postgresql-16-standby.log | tail -n 3'

block fix
on "sudo -u postgres psql -p 5434 -c \"ALTER SYSTEM SET restore_command = 'pgbackrest --stanza=main --pg1-path=/var/lib/postgresql/16/standby archive-get %f \\\"%p\\\"'\""
on 'sudo pg_ctlcluster 16 standby reload'
sleep 10
on 'sudo grep -E "restored log|FATAL|started streaming" /var/log/postgresql/postgresql-16-standby.log | tail -n 6'

block slot-after
printf "SELECT application_name, state, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS behind FROM pg_stat_replication;\nSELECT slot_name, active, wal_status FROM pg_replication_slots;\nCHECKPOINT;\nSELECT slot_name, active, wal_status FROM pg_replication_slots;\n" | session shop
