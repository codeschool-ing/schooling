#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of db-reliability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from `lab.sh base`: 16/main on 5432 with the shop. No standby is
# needed. PgBouncer 1.22 is Ubuntu's package; the lesson runs its own instance
# as ana on port 6433, which is what this script runs, so nothing here depends
# on the package's service (which this machine, having no systemd, never
# started). pgbouncer.ini is taken out of this lesson's .md, so the file the
# student copies is the file that ran.
#
# The waits (`sleep`) let pgbench's clients connect before the pools are
# inspected.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, PgBouncer 1.22.0,
# TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/lib.sh

lab base

block too-many
on 'psql -XAt shop -c "SHOW max_connections"'
on 'createdb bench && pgbench -q -i -s 10 bench > /dev/null 2>&1'
on 'pgbench -c 120 -T 5 -n bench 2>&1 | tail -n 3'

block app-role
printf "CREATE ROLE shop_app LOGIN PASSWORD 'app-pass-1';\nGRANT SELECT, INSERT, UPDATE ON customers, orders TO shop_app;\nGRANT USAGE ON SEQUENCE orders_id_seq TO shop_app;\nALTER DATABASE bench OWNER TO shop_app;\n" | session shop
on "echo '127.0.0.1:*:*:shop_app:app-pass-1' >> ~/.pgpass && chmod 600 ~/.pgpass"
on 'dropdb bench && createdb -O shop_app bench && pgbench -q -i -s 10 -h 127.0.0.1 -U shop_app bench > /dev/null 2>&1'

block userlist
on 'mkdir -p ~/pgbouncer'
on "psql -XAt shop -c \"SELECT format('\\\"%s\\\" \\\"%s\\\"', rolname, rolpassword) FROM pg_authid WHERE rolname = 'shop_app'\" > ~/pgbouncer/userlist.txt"
on 'cut -c1-60 ~/pgbouncer/userlist.txt'
extract the-pooler.md pgbouncer.ini | lab exec 'cat > ~/pgbouncer/pgbouncer.ini'

block start
on 'pgbouncer -d ~/pgbouncer/pgbouncer.ini'
on 'psql -h 127.0.0.1 -p 6433 -U shop_app -XAt shop -c "SELECT count(*) FROM orders"'

block through
on 'pgbench -c 120 -T 10 -n -h 127.0.0.1 -p 6433 -U shop_app bench > ~/bench.out 2>&1 &'
sleep 4
on 'psql -h 127.0.0.1 -p 6433 -U shop_app pgbouncer -c "SHOW POOLS" | cut -c1-80 | head -n 4'
on 'time psql -h 127.0.0.1 -p 6433 -U shop_app -XAt bench -c "SELECT 1"'
printf "SELECT count(*) FROM pg_stat_activity WHERE usename = 'shop_app';\n" | session shop
sleep 9
on 'grep -E "number of failed|latency average|tps" ~/bench.out'

block leak
on "psql -h 127.0.0.1 -p 6433 -U shop_app shop -c \"SET statement_timeout = '1ms'\""
on 'psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "SHOW statement_timeout"'
on 'psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "SELECT count(*) FROM orders"'

block local
on "psql -h 127.0.0.1 -p 6433 -U shop_app shop -c \"SET statement_timeout = 0\""
on "psql -h 127.0.0.1 -p 6433 -U shop_app shop -c \"BEGIN\" -c \"SET LOCAL statement_timeout = '1ms'\" -c \"SHOW statement_timeout\" -c \"COMMIT\""
on 'psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "SHOW statement_timeout"'

block session-mode
on "sed -i 's/^pool_mode = transaction/pool_mode = session/' ~/pgbouncer/pgbouncer.ini"
on 'kill -HUP $(cat ~/pgbouncer/pgbouncer.pid)'
sleep 1
on "psql -h 127.0.0.1 -p 6433 -U shop_app shop -c \"SET statement_timeout = '1ms'\""
on 'psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "SHOW statement_timeout"'
on 'pgbench -c 120 -T 5 -n -h 127.0.0.1 -p 6433 -U shop_app bench > ~/bench.out 2>&1 &'
sleep 3
on 'psql -h 127.0.0.1 -p 6433 -U shop_app pgbouncer -c "SHOW POOLS" | cut -c1-80 | head -n 4'
on 'time psql -h 127.0.0.1 -p 6433 -U shop_app -XAt bench -c "SELECT 1"'
sleep 4
