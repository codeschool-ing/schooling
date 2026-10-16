#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of db-reliability, as a script that
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
# and slot standby1, asynchronous. The second standby, 16/standby2 on 5435, is
# built in the lesson, from the first.
#
# ONE MACHINE HAS NO DISTANCE. The lesson's "region" is a role, not a place: the
# standby on 5435 is the one that would be far away, and the lesson says what
# the distance would add. The waits (`sleep`) are the server's own timings:
# max_standby_streaming_delay is 30 seconds by default, and the delayed standby
# applies the log two minutes late.
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

block cascade
on 'sudo pg_createcluster 16 standby2 --port 5435 > /dev/null && sudo rm -rf /var/lib/postgresql/16/standby2'
on "sudo -u postgres pg_basebackup -d 'host=127.0.0.1 port=5434 user=replicator application_name=standby2' -D /var/lib/postgresql/16/standby2 -R -C -S standby2 -X stream -c fast"
on 'sudo pg_ctlcluster 16 standby2 start'
sleep 4
printf "SELECT application_name, state FROM pg_stat_replication;\n" | session shop
printf "SELECT application_name, state FROM pg_stat_replication;\n" | session shop -p 5434
printf "SELECT status, sender_port FROM pg_stat_wal_receiver;\n" | session shop -p 5435

block conflict
on "psql -p 5435 shop -c 'BEGIN ISOLATION LEVEL REPEATABLE READ' -c 'SELECT count(*) FROM orders' -c 'SELECT pg_sleep(60)' -c 'SELECT count(*) FROM orders' -c 'COMMIT' > report.log 2>&1 &"
sleep 2
printf "UPDATE orders SET total_cents = total_cents + 1 WHERE id <= 1000;\nVACUUM orders;\n" | session shop
sleep 40
on 'cat report.log'

block feedback
on "sudo -u postgres psql -p 5435 -c 'ALTER SYSTEM SET hot_standby_feedback = on' -c 'SELECT pg_reload_conf()'"
on "sudo -u postgres psql -p 5434 -c 'ALTER SYSTEM SET hot_standby_feedback = on' -c 'SELECT pg_reload_conf()'"
sleep 3
on "psql -p 5435 shop -c 'BEGIN ISOLATION LEVEL REPEATABLE READ' -c 'SELECT count(*) FROM orders' -c 'SELECT pg_sleep(45)' -c 'SELECT count(*) FROM orders' -c 'COMMIT' > report.log 2>&1 &"
sleep 3
sleep 12
printf "SELECT slot_name, xmin FROM pg_replication_slots;\nUPDATE orders SET total_cents = total_cents + 1 WHERE id <= 1000;\nVACUUM orders;\nSELECT n_dead_tup FROM pg_stat_user_tables WHERE relname = 'orders';\n" | session shop
sleep 38
on 'cat report.log'

block delay
on "sudo -u postgres psql -p 5434 -c \"ALTER SYSTEM SET recovery_min_apply_delay = '2min'\" -c 'SELECT pg_reload_conf()'"
sleep 2

block mistake
printf "SELECT now();\nDELETE FROM orders WHERE customer_id = 7;\n" | session shop
sleep 5
printf "SELECT count(*) FROM orders WHERE customer_id = 7;\n" | session shop -p 5434
printf "SELECT count(*) FROM orders WHERE customer_id = 7;\n" | session shop -p 5435

block rescue
printf "SELECT pg_wal_replay_pause();\n" | session shop -p 5434
on "psql -p 5434 shop -c \"\\copy (SELECT * FROM orders WHERE customer_id = 7) TO 'orders-7.csv' CSV\""
on "psql shop -c \"\\copy orders FROM 'orders-7.csv' CSV\""
on 'psql -XAt shop -c "SELECT count(*) FROM orders WHERE customer_id = 7"'
printf "SELECT pg_wal_replay_resume();\n" | session shop -p 5434
