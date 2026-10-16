#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of db-reliability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the machine as lesson 12's first section leaves it, rebuilt
# quietly: `lab.sh base`, the role replicator with its .pgpass, and the standby
# 16/standby on port 5434 built by pg_basebackup with application_name=standby1
# and slot standby1, asynchronous.
#
# THE CRASH IS A kill -9 OF THE PRIMARY'S POSTMASTER, which stops the server as
# a power cut would stop the process, without a checkpoint or a goodbye to the
# standby. It is not a power cut: the operating system still writes out what
# PostgreSQL had handed it. What the lesson needs from it, a primary that
# stopped mid-stream and comes back thinking it is still the primary, is real.
#
# The waits (`sleep`) give servers time to start and the standby time to
# connect.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/lib.sh

lab base
printf "CREATE ROLE replicator LOGIN REPLICATION PASSWORD 'replica-pass-1';\n" | lab psql shop >/dev/null
lab exec "echo '127.0.0.1:*:*:replicator:replica-pass-1' | sudo -u postgres tee /var/lib/postgresql/.pgpass > /dev/null && sudo -u postgres chmod 600 /var/lib/postgresql/.pgpass"
lab exec 'sudo pg_createcluster 16 standby --port 5434 >/dev/null && sudo rm -rf /var/lib/postgresql/16/standby'
lab exec "sudo -u postgres pg_basebackup -d 'host=127.0.0.1 port=5432 user=replicator application_name=standby1' -D /var/lib/postgresql/16/standby -R -C -S standby1 -X stream -c fast"
lab exec 'sudo pg_ctlcluster 16 standby start'
sleep 3

block before
printf "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (51, 5100, now()) RETURNING id;\n" | session shop
sleep 1
on 'sudo kill -9 $(sudo head -n 1 /var/lib/postgresql/16/main/postmaster.pid)'
sleep 2
on 'pg_lsclusters'

block check
printf "SELECT pg_is_in_recovery();\nSELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn();\nSELECT max(id) FROM orders;\nSELECT status FROM pg_stat_wal_receiver;\n" | session shop -p 5434

block promote
on 'sudo pg_ctlcluster 16 standby promote'
sleep 2
printf "SELECT pg_is_in_recovery();\nSELECT timeline_id FROM pg_control_checkpoint();\nINSERT INTO orders (customer_id, total_cents, placed_at) VALUES (52, 5200, now()) RETURNING id;\n" | session shop -p 5434

block old-back
on 'sudo pg_ctlcluster 16 main start'
sleep 2
on 'pg_lsclusters'
printf "SELECT pg_is_in_recovery();\nINSERT INTO orders (customer_id, total_cents, placed_at) VALUES (53, 5300, now()) RETURNING id;\n" | session shop
on 'psql -XAt shop -c "SELECT id, customer_id FROM orders WHERE id > 50000 ORDER BY id"'
on 'psql -XAt -p 5434 shop -c "SELECT id, customer_id FROM orders WHERE id > 50000 ORDER BY id"'

block rewind-refused
on 'sudo pg_ctlcluster 16 main stop'
on "sudo -u postgres /usr/lib/postgresql/16/bin/pg_rewind --target-pgdata=/var/lib/postgresql/16/main --source-server='port=5434 user=postgres dbname=postgres'"

block rebuild
on 'sudo rm -rf /var/lib/postgresql/16/main'
on "sudo -u postgres pg_basebackup -d 'host=127.0.0.1 port=5434 user=replicator application_name=main' -D /var/lib/postgresql/16/main -R -C -S main -X stream -c fast"
on 'sudo pg_ctlcluster 16 main start'
sleep 3
printf "SELECT application_name, state FROM pg_stat_replication;\nSELECT slot_name, active FROM pg_replication_slots;\n" | session shop -p 5434

block hints
printf "ALTER SYSTEM SET wal_log_hints = on;\n" | session shop -p 5434
on 'sudo pg_ctlcluster 16 standby restart'
sleep 3
on 'sudo pg_ctlcluster 16 main restart'
sleep 3
on 'psql -XAt shop -c "SHOW wal_log_hints"'
printf "ALTER SYSTEM SET wal_log_hints = on;\n" | session shop
on 'sudo pg_ctlcluster 16 main restart'
sleep 3
on 'psql -XAt shop -c "SHOW wal_log_hints"'

block switchover
on 'sudo pg_ctlcluster 16 standby stop'
on "sudo /usr/lib/postgresql/16/bin/pg_controldata /var/lib/postgresql/16/standby | grep -E 'cluster state|Latest checkpoint location'"
printf "SELECT pg_last_wal_replay_lsn();\n" | session shop
on 'sudo pg_ctlcluster 16 main promote'
sleep 2
printf "SELECT pg_create_physical_replication_slot('standby1');\n" | session shop
on 'sudo -u postgres touch /var/lib/postgresql/16/standby/standby.signal'
on 'sudo grep -E "primary_conninfo|primary_slot_name" /var/lib/postgresql/16/standby/postgresql.auto.conf'
on 'sudo pg_ctlcluster 16 standby start'
sleep 4
printf "SELECT application_name, state FROM pg_stat_replication;\n" | session shop

block crash-again
printf "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (54, 5400, now()) RETURNING id;\n" | session shop
sleep 1
on 'sudo kill -9 $(sudo head -n 1 /var/lib/postgresql/16/main/postmaster.pid)'
on 'sudo pg_ctlcluster 16 standby promote'
sleep 2
printf "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (55, 5500, now()) RETURNING id;\n" | session shop -p 5434

block rewind
on "sudo -u postgres /usr/lib/postgresql/16/bin/pg_rewind --target-pgdata=/var/lib/postgresql/16/main --source-server='port=5434 user=postgres dbname=postgres application_name=main' --config-file=/etc/postgresql/16/main/postgresql.conf --write-recovery-conf"
on 'sudo grep -E "primary_conninfo|primary_slot_name" /var/lib/postgresql/16/main/postgresql.auto.conf'
on 'sudo pg_ctlcluster 16 main start'
sleep 4
on 'sudo tail -n 2 /var/log/postgresql/postgresql-16-main.log'
printf "SELECT application_name, state FROM pg_stat_replication;\nSELECT slot_name, active FROM pg_replication_slots;\n" | session shop -p 5434
on 'psql -XAt shop -c "SELECT pg_is_in_recovery()"'

block slot-fix
on "sudo -u postgres psql -c \"ALTER SYSTEM SET primary_slot_name = 'main'\""
on 'sudo pg_ctlcluster 16 main reload'
sleep 4
printf "SELECT application_name, state FROM pg_stat_replication;\nSELECT slot_name, active FROM pg_replication_slots;\n" | session shop -p 5434
