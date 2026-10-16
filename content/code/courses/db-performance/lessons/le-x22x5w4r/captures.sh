#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # the machine lesson 1's captures built
#   sudo bash captures.sh
#
# It starts where lesson 3 starts (lab.sh reset). Lesson 2's workload is taken
# out of lesson 2's a-workload.md, and reprice.sql and oldest.sql out of this
# lesson's own bloat.md and finding-them.md, so the files shown are the files
# that ran.
#
# STAGED: the lesson asks the student to keep two terminals open, one holding a
# transaction and one working. Here "Session A" is a psql typed at by
# lab/session.py in the background, and it waits for its next line by running
# a shell loop through psql's \! that is typed and not printed (#quiet), until
# this script creates a file. That is how a person leaves a terminal alone and
# comes back to it; nothing else about the session differs. The extra sessions
# in finding-them are started the same way and their screens are not shown.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh
FENCE=../../lab/fence.py
L2=../le-9kwvr0x4
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@vm:~$ %s\n' "$*"; lab as "$*" 2>&1 || true; }
onw() { printf 'ana@vm:~/workload$ %s\n' "$*"; lab as "cd ~/workload && $*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
# wait until N sessions on market are idle in a transaction
idle() { for _ in $(seq 300); do
  n=$(lab as "psql -XAtqc \"SELECT count(*) FROM pg_stat_activity WHERE datname = 'market' AND state = 'idle in transaction'\" market")
  [ "$n" -ge "$1" ] && return 0; sleep 0.2; done; echo "idle: gave up" >&2; }
# a background session typed from the text in $2; its quiet waits end when
# /tmp/go-NAME exists, and its screen goes to $TMP/NAME
TMP=$(mktemp -d)
declare -A PID
start() { lab as "rm -f /tmp/go-$1"; printf '%s\n' "$2" > "$TMP/$1.in"
  session market < "$TMP/$1.in" > "$TMP/$1" 2>&1 & PID[$1]=$!; }
go() { lab as "touch /tmp/go-$1"; wait "${PID[$1]}"; }
W() { printf '#quiet \\! while [ ! -f /tmp/go-%s ]; do sleep 0.2; done' "$1"; }
exec 9>/var/tmp/db-performance-capture.lock; flock 9

lab reset
python3 "$FENCE" "$L2/a-workload.md" 'mkdir -p ~/workload' | lab as 'bash' >/dev/null
python3 "$FENCE" bloat.md "cat > ~/workload/reprice.sql" | lab as 'bash'
python3 "$FENCE" finding-them.md "cat > ~/oldest.sql" | lab as 'bash'

# ---------------------------------------------------------------- the horizon
start h "BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT sum(price_cents) FROM products;
$(W h)
SELECT sum(price_cents) FROM products;
COMMIT;"
idle 1
block h-b1
printf "UPDATE products SET price_cents = price_cents + 100 WHERE id = 7;\nVACUUM (VERBOSE) products;\n" | session market
block h-b2
printf "SELECT pid, state, backend_xmin, age(backend_xmin) FROM pg_stat_activity WHERE backend_xmin IS NOT NULL AND pid <> pg_backend_pid();\n" | session market
go h
block h-b3
printf "VACUUM (VERBOSE) products;\n" | session market
block h-a
cat "$TMP/h"

# ---------------------------------------------------------------- bloat
SIZE="SELECT pg_size_pretty(pg_table_size('products')) AS size, n_live_tup, n_dead_tup FROM pg_stat_user_tables WHERE relname = 'products';"
block size-0
printf '%s\n' "$SIZE" | session market
block tag-0
onw 'pgbench -n -T 10 -f tag-search.sql market | tail -3'
block robot-free
onw 'pgbench -n -c 4 -j 4 -T 30 -f reprice.sql market'
printf '%s\n' "$SIZE" | session market

start b "BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT count(*) FROM products;
$(W b)
COMMIT;"
idle 1
block robot-held
onw 'pgbench -n -c 4 -j 4 -T 30 -f reprice.sql market'
printf '%s\n' "$SIZE" | session market
block vacuum-held
printf "VACUUM (VERBOSE) products;\n" | session market
block tag-held
onw 'pgbench -n -T 10 -f tag-search.sql market | tail -3'
go b
block b-a
cat "$TMP/b"
block vacuum-after
printf "VACUUM (VERBOSE) products;\n" | session market
printf '%s\n' "$SIZE" | session market
block tag-after
onw 'pgbench -n -T 10 -f tag-search.sql market | tail -3'

# ---------------------------------------------------------------- timeouts
block idle-timeout
printf "SHOW idle_in_transaction_session_timeout;\nSET idle_in_transaction_session_timeout = '5s';\nBEGIN;\nSELECT count(*) FROM sellers;\n#quiet \\\\! sleep 6\nSELECT count(*) FROM sellers;\n" | session market
block statement-timeout
printf "SET statement_timeout = '100ms';\nSELECT count(*) FROM order_lines WHERE quantity = 3;\n" | session market
block alter-database
printf "ALTER DATABASE market SET idle_in_transaction_session_timeout = '1min';\n" | session market
printf 'market=# \\q\nana@vm:~$ psql market\n'
printf "SHOW idle_in_transaction_session_timeout;\n" | session market
block alter-reset
printf "ALTER DATABASE market RESET idle_in_transaction_session_timeout;\n" | session market

# ---------------------------------------------------------------- finding them
start f1 "BEGIN;
SELECT count(*) FROM sellers;
$(W f1)
COMMIT;"
idle 1
start f2 "BEGIN;
UPDATE sellers SET name = 'Seller 2 (verified)' WHERE id = 2;
$(W f2)
ROLLBACK;"
idle 2
start f3 "BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT count(*) FROM sellers;
$(W f3)
COMMIT;"
idle 3
lab as "setsid psql -qX market -c 'SELECT pg_sleep(40)' >/dev/null 2>&1 < /dev/null &"
sleep 1
lab as 'cd ~/workload && pgbench -n -c 4 -j 4 -T 5 -f reprice.sql market' >/dev/null 2>&1
block oldest
printf '\\i oldest.sql\n' | session market
block others
printf "SELECT gid, prepared, owner FROM pg_prepared_xacts;\nSELECT slot_name, xmin, catalog_xmin FROM pg_replication_slots;\nBEGIN;\nPREPARE TRANSACTION 'pay-1';\n" | session market
go f1; go f2; go f3
lab as "psql -qX market -c \"SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE query = 'SELECT pg_sleep(40)'\"" >/dev/null

block reset
on '~/reset-market.sh'
rm -rf "$TMP"
