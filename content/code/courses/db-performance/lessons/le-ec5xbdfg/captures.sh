#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # the machine lesson 1's captures built
#   sudo bash captures.sh
#
# It starts where lesson 3 starts (lab.sh reset), builds the second cluster
# `replica` on port 5433 exactly as a-replica.md prints it, and drops it again
# at the end. read-your-write.sh is taken out of your-own-write.md, and the
# workload out of lesson 2's a-workload.md.
#
# STAGED: the primary and the replica are two clusters on one machine, as the
# lesson says, so the lag measured without recovery_min_apply_delay is the lag
# of a loopback socket. In conflicts, two psql sessions run at once: the
# replica's in the background, the primary's started three seconds later, so
# that the replica's snapshot exists before the rows are removed. Each screen
# is printed as it appeared.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh
FENCE=../../lab/fence.py
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@vm:~$ %s\n' "$*"; lab as "$*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/db-performance-capture.lock; flock 9
OUT=$(mktemp -d)

lab reset
lab as 'sudo pg_dropcluster 16 replica --stop' >/dev/null 2>&1
python3 "$FENCE" ../le-9kwvr0x4/a-workload.md 'mkdir -p ~/workload' | lab as 'bash' >/dev/null
python3 "$FENCE" your-own-write.md 'cat > ~/read-your-write.sh' | lab as 'bash'

block create
on 'sudo pg_createcluster 16 replica --port 5433'

block basebackup
on 'sudo -u postgres rm -rf /var/lib/postgresql/16/replica'
on 'time sudo -u postgres pg_basebackup -D /var/lib/postgresql/16/replica -R -X stream -c fast'
on 'sudo cat /var/lib/postgresql/16/replica/postgresql.auto.conf'

block start
on 'sudo systemctl start postgresql@16-replica'
on 'pg_lsclusters'

block read-only
printf "SELECT pg_is_in_recovery();\nSELECT count(*) FROM orders;\nUPDATE orders SET status = 'cancelled' WHERE id = 1;\n" | session market -p 5433

block stat-replication
printf '\\x on\nSELECT * FROM pg_stat_replication;\n' | session market

block under-load
on 'cd ~/workload && pgbench -n -c 4 -T 20 -P 10 -f place-order.sql market'
printf "SELECT write_lag, flush_lag, replay_lag, pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes_behind FROM pg_stat_replication;\n" | session market

block idle-timestamp
printf "SELECT now() - pg_last_xact_replay_timestamp() AS behind;\n" | session market -p 5433
sleep 10
printf "SELECT now() - pg_last_xact_replay_timestamp() AS behind;\n" | session market -p 5433

block delay
printf "ALTER SYSTEM SET recovery_min_apply_delay = '10s';\nSELECT pg_reload_conf();\n" | session market -p 5433
on 'cd ~/workload && pgbench -n -c 4 -T 5 -f place-order.sql market | grep -E "^(number of transactions|tps)"'
printf "SELECT write_lag, flush_lag, replay_lag, pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes_behind FROM pg_stat_replication;\n" | session market
printf "SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn(), now() - pg_last_xact_replay_timestamp() AS behind;\n" | session market -p 5433
sleep 12

block stale
on "psql market -c \"SELECT id, status FROM orders WHERE id = 1999990\""
on "psql market -c \"UPDATE orders SET status = 'cancelled' WHERE id = 1999990\""
on "psql -p 5433 market -c \"SELECT id, status FROM orders WHERE id = 1999990\""
sleep 12
on "psql -p 5433 market -c \"SELECT id, status FROM orders WHERE id = 1999990\""

block wait-lsn
on '~/read-your-write.sh 1999991'

block conflict
printf "ALTER SYSTEM RESET recovery_min_apply_delay;\nALTER SYSTEM SET max_standby_streaming_delay = '5s';\nSELECT pg_reload_conf();\n" | session market -p 5433
printf "BEGIN ISOLATION LEVEL REPEATABLE READ;\nSELECT count(*) FROM events WHERE at < '2025-10-04';\nSELECT pg_sleep(30);\nROLLBACK;\n" | session market -p 5433 > "$OUT/a" 2>&1 &
A=$!
sleep 3
printf "DELETE FROM events WHERE at < '2025-10-04';\nVACUUM events;\n" | session market > "$OUT/b" 2>&1
wait $A
echo '--- replica'; cat "$OUT/a"; echo '--- primary'; cat "$OUT/b"
on 'sudo tail -n 3 /var/log/postgresql/postgresql-16-replica.log'

block feedback
printf "ALTER SYSTEM SET hot_standby_feedback = on;\nSELECT pg_reload_conf();\n" | session market -p 5433
sleep 2
printf "BEGIN ISOLATION LEVEL REPEATABLE READ;\nSELECT count(*) FROM events WHERE at < '2025-10-05';\nSELECT pg_sleep(15);\nROLLBACK;\n" | session market -p 5433 > "$OUT/a" 2>&1 &
A=$!
sleep 3
printf "DELETE FROM events WHERE at < '2025-10-05';\nVACUUM (VERBOSE) events;\n" | session market > "$OUT/b" 2>&1
wait $A
echo '--- replica'; cat "$OUT/a"; echo '--- primary'; cat "$OUT/b"

block teardown
on 'sudo pg_dropcluster 16 replica --stop'
on 'pg_lsclusters'
lab reset
rm -rf "$OUT"
