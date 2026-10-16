#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of db-reliability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the machine as lesson 11 leaves it, rebuilt quietly: `lab.sh
# base`, the role replicator with its .pgpass, and the standby 16/standby on
# port 5434 built by lesson 11's pg_basebackup, with application_name=standby1
# added to its connection as this lesson's first section shows. The second
# standby, 16/standby2 on 5435, is built in the lesson.
#
# THE TWO STANDBYS ARE ON THE SAME MACHINE AS THE PRIMARY, so the network adds
# almost nothing to a synchronous commit, and this kernel has no netem to add
# a delay. The pgbench numbers are this machine's (4 cores, an SSD); the lesson
# says so and does the arithmetic for real distances separately.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/lib.sh

lab base
printf "CREATE ROLE replicator LOGIN REPLICATION PASSWORD 'replica-pass-1';\n" | lab psql shop >/dev/null
lab exec "echo '127.0.0.1:5432:*:replicator:replica-pass-1' | sudo -u postgres tee /var/lib/postgresql/.pgpass > /dev/null && sudo -u postgres chmod 600 /var/lib/postgresql/.pgpass"
lab exec 'sudo pg_createcluster 16 standby --port 5434 >/dev/null && sudo rm -rf /var/lib/postgresql/16/standby'

block name
on "sudo -u postgres pg_basebackup -d 'host=127.0.0.1 port=5432 user=replicator application_name=standby1' -D /var/lib/postgresql/16/standby -R -C -S standby1 -X stream -c fast"
on 'sudo grep -o "application_name=[a-z0-9]*" /var/lib/postgresql/16/standby/postgresql.auto.conf'
on 'sudo pg_ctlcluster 16 standby start'
lab exec 'createdb bench && pgbench -q -i -s 10 bench > /dev/null 2>&1'
sleep 2

block async
on 'pgbench -c 4 -T 10 -n bench | grep -E "latency average|tps"'

block sync-on
printf "ALTER SYSTEM SET synchronous_standby_names = 'standby1';\nSELECT pg_reload_conf();\nSELECT application_name, sync_state FROM pg_stat_replication;\n" | session shop

block sync-on-bench
on 'pgbench -c 4 -T 10 -n bench | grep -E "latency average|tps"'

block apply
on "PGOPTIONS='-c synchronous_commit=remote_apply' pgbench -c 4 -T 10 -n bench | grep -E 'latency average|tps'"
on "PGOPTIONS='-c synchronous_commit=off' pgbench -c 4 -T 10 -n bench | grep -E 'latency average|tps'"

block stall
on 'sudo pg_ctlcluster 16 standby stop'
on "timeout 10 psql shop -c \"INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (21, 777777, now())\"; echo \"exit \$?\""
printf "SELECT state, wait_event_type, wait_event, left(query, 40) AS query FROM pg_stat_activity WHERE wait_event = 'SyncRep';\nSELECT count(*) FROM orders WHERE total_cents = 777777;\n" | session shop

block timeout
on "PGOPTIONS='-c statement_timeout=3s' timeout 10 psql shop -c \"INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (23, 888888, now())\"; echo \"exit \$?\""

block cancel
on "psql shop -c \"INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (24, 999999, now())\" > insert.log 2>&1 &"
sleep 2
printf "SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE wait_event = 'SyncRep';\nSELECT total_cents, count(*) FROM orders WHERE total_cents > 700000 GROUP BY 1 ORDER BY 1;\n" | session shop
sleep 1
on 'cat insert.log'

block second
lab exec "sudo pg_createcluster 16 standby2 --port 5435 >/dev/null && sudo rm -rf /var/lib/postgresql/16/standby2"
on "sudo -u postgres pg_basebackup -d 'host=127.0.0.1 port=5432 user=replicator application_name=standby2' -D /var/lib/postgresql/16/standby2 -R -C -S standby2 -X stream -c fast"
on 'sudo pg_ctlcluster 16 standby2 start'
on 'sudo pg_ctlcluster 16 standby start'
printf "ALTER SYSTEM SET synchronous_standby_names = 'ANY 1 (standby1, standby2)';\nSELECT pg_reload_conf();\nSELECT application_name, sync_state FROM pg_stat_replication ORDER BY 1;\n" | session shop

block quorum
on 'sudo pg_ctlcluster 16 standby stop'
on "timeout 10 psql shop -c \"INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (22, 2200, now())\"; echo \"exit \$?\""
printf "SELECT application_name, sync_state FROM pg_stat_replication ORDER BY 1;\n" | session shop
