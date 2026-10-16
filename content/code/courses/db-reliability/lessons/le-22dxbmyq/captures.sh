#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of db-reliability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the machine as lesson 1 leaves it (`lab.sh base`). Archiving
# is left off on purpose: this lesson is about the standby and its slot, and
# lesson 13 puts the archive back beside them. The waits (`sleep`) give the
# standby time to connect and replay; a person typing waits longer.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/lib.sh

lab base

block role
printf "CREATE ROLE replicator LOGIN REPLICATION PASSWORD 'replica-pass-1';\n" | session shop
on "echo '127.0.0.1:5432:*:replicator:replica-pass-1' | sudo -u postgres tee /var/lib/postgresql/.pgpass > /dev/null"
on 'sudo -u postgres chmod 600 /var/lib/postgresql/.pgpass'

block cluster
on 'sudo pg_createcluster 16 standby --port 5434'
on 'sudo rm -rf /var/lib/postgresql/16/standby'

block basebackup
on 'sudo -u postgres pg_basebackup -h 127.0.0.1 -p 5432 -U replicator -D /var/lib/postgresql/16/standby -R -C -S standby1 -X stream -c fast'
on 'sudo cat /var/lib/postgresql/16/standby/postgresql.auto.conf'
on 'sudo ls /var/lib/postgresql/16/standby/standby.signal'

block start
on 'sudo pg_ctlcluster 16 standby start'
sleep 2
on 'pg_lsclusters'

block primary-view
printf "\\\\x\nSELECT application_name, client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn, sync_state FROM pg_stat_replication;\n" | session shop

block standby-view
printf "SELECT pg_is_in_recovery();\nSELECT status, sender_host, sender_port, slot_name FROM pg_stat_wal_receiver;\n" | session shop -p 5434

block read-write
printf "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (11, 4200, now()) RETURNING id;\n" | session shop
sleep 1
printf "SELECT id, total_cents FROM orders ORDER BY id DESC LIMIT 1;\nINSERT INTO orders (customer_id, total_cents, placed_at) VALUES (12, 100, now());\n" | session shop -p 5434

block slot
printf "SELECT slot_name, slot_type, active, restart_lsn, wal_status FROM pg_replication_slots;\n" | session shop

block slot-holds
on 'sudo pg_ctlcluster 16 standby stop'
printf "UPDATE orders SET total_cents = total_cents + 1;\nUPDATE orders SET total_cents = total_cents + 1;\nUPDATE orders SET total_cents = total_cents + 1;\nCHECKPOINT;\nSELECT slot_name, active, wal_status, pg_size_pretty(pg_current_wal_lsn() - restart_lsn) AS held FROM pg_replication_slots;\n" | session shop
on 'sudo du -sh /var/lib/postgresql/16/main/pg_wal'

block limit
printf "ALTER SYSTEM SET max_slot_wal_keep_size = '32MB';\nSELECT pg_reload_conf();\nCHECKPOINT;\nSELECT slot_name, active, wal_status, pg_size_pretty(pg_current_wal_lsn() - restart_lsn) AS held FROM pg_replication_slots;\n" | session shop
on 'sudo du -sh /var/lib/postgresql/16/main/pg_wal'

block lost
on 'sudo pg_ctlcluster 16 standby start'
sleep 3
on 'sudo tail -n 3 /var/log/postgresql/postgresql-16-standby.log'
