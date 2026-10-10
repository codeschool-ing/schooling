#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh up    # once
#   sudo bash captures.sh
#
# It starts from the machine as `apt install postgresql` leaves it: no role
# for ana and no database. market.sql and ~/.psqlrc are taken out of this
# lesson's own installing.md and run as they are printed there. The loaded
# database is copied to `market_base`, as the lesson tells the student to do,
# and every later lesson's captures start from that copy (`lab.sh reset`).
#
# STAGED: "drop the cache" in first-measurement is run as root on the computer
# hosting the container, because a container cannot write to
# /proc/sys/vm/drop_caches. In a virtual machine the command printed does it.
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

lab root 'runuser -u postgres -- psql -qX -c "DROP DATABASE IF EXISTS market" -c "DROP DATABASE IF EXISTS market_base" -c "DROP ROLE IF EXISTS ana" -c "ALTER SYSTEM RESET ALL"; systemctl restart postgresql@16-main' >/dev/null
lab as 'rm -f ~/.psqlrc ~/market.sql'

block versions
on 'psql --version'
on 'pg_lsclusters'

block no-role
on 'psql market'

block createuser
on 'sudo -u postgres createuser --superuser $USER'
on 'createdb market'

python3 "$FENCE" installing.md '-- market.sql:' | lab as 'cat > market.sql'

block load
on 'time psql market -v ON_ERROR_STOP=1 -f market.sql'

python3 "$FENCE" installing.md 'cat > ~/.psqlrc' | lab as 'bash'

block sizes
printf 'ana@vm:~$ psql market\n'
printf "SELECT relname AS table, reltuples::bigint AS rows, pg_size_pretty(pg_total_relation_size(oid)) AS size FROM pg_class WHERE relnamespace = 'public'::regnamespace AND relkind = 'r' ORDER BY pg_total_relation_size(oid) DESC;\nSELECT pg_size_pretty(pg_database_size('market')) AS database;\n" | session market

# the copy every later lesson starts from
block copy
on 'createdb -T market market_base'

block query-suspect
printf "SELECT count(*) FROM orders WHERE date(placed_at) = '2025-06-01';\nSELECT count(*) FROM orders WHERE placed_at >= '2025-06-01' AND placed_at < '2025-06-02';\n" | session market

block schema-suspect
printf "SELECT count(*) FROM orders WHERE seller_id = 42;\nCREATE INDEX orders_seller_id_idx ON orders (seller_id);\nSELECT count(*) FROM orders WHERE seller_id = 42;\nDROP INDEX orders_seller_id_idx;\n" | session market

block machine
on 'nproc'
on 'free -h'

block cold
on 'sudo systemctl restart postgresql'
printf '%s\n' 'ana@vm:~$ sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"'
sync; echo 3 > /proc/sys/vm/drop_caches
printf 'ana@vm:~$ psql market\n'
printf "SELECT count(*) FROM order_lines WHERE quantity = 3;\nSELECT count(*) FROM order_lines WHERE quantity = 3;\nSELECT count(*) FROM order_lines WHERE quantity = 3;\n" | session market

block load-twice
on 'psql market -v ON_ERROR_STOP=1 -f market.sql'

block stopped
on 'sudo systemctl stop postgresql'
on 'psql market'
on 'pg_lsclusters'
on 'sudo systemctl start postgresql'

block buffers
printf "SHOW shared_buffers;\n" | session market
