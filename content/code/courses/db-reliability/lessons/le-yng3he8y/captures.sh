#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of db-reliability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the machine as lesson 5 leaves it, rebuilt quietly: `lab.sh
# base`, the second server 16/restore, pgbackrest.conf as lesson 5 prints it,
# archive-push, the stanza and one full backup. inventory.sql and walwatch.sh
# are taken out of this lesson's .md files.
#
# THE LAB PLAYS BOTH SIDES, and the lesson says which commands are the
# intruder's. The role `maint_svc` stands for a foothold left days before the
# damage; the damage is two UPDATE statements the lesson shows. Nothing here
# is an attack technique: creating a role and updating rows are what the
# lab's own superuser does every day.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, pgBackRest 2.50,
# TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/lib.sh

lab base
lab exec 'sudo pg_createcluster 16 restore --port 5433 >/dev/null && sudo pg_ctlcluster 16 restore start && sudo -u postgres createuser -p 5433 --superuser ana'
extract ../le-62bgpm2d/setting-up.md pgbackrest.conf | lab exec 'sudo tee /etc/pgbackrest.conf > /dev/null'
printf "ALTER SYSTEM SET archive_mode = on;\nALTER SYSTEM SET archive_command = 'pgbackrest --stanza=main archive-push %%p';\nALTER SYSTEM SET archive_timeout = '60s';\n" | lab psql shop >/dev/null
lab exec 'sudo pg_ctlcluster 16 main restart && sudo -u postgres pgbackrest --stanza=main stanza-create && sudo -u postgres pgbackrest --stanza=main backup --type=full'
extract the-clean-point.md inventory.sql | lab exec 'cat > inventory.sql'
extract watching.md walwatch.sh | lab exec 'cat > walwatch.sh && chmod +x walwatch.sh'

block inventory
on 'psql -X -A -t shop -f inventory.sql > inventory-known.txt'
on 'cat inventory-known.txt'

block foothold
printf "CREATE ROLE maint_svc LOGIN SUPERUSER PASSWORD 'not-a-real-secret';\n" | session shop
lab exec 'for i in 1 2 3; do psql -qX shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES ($i, 1800, now())"; done'
sleep 15

block watch
on './walwatch.sh 5 10 > walwatch.log &'
sleep 7
printf "UPDATE customers SET name = md5(name), city = md5(city);\nUPDATE orders SET total_cents = 1;\n" | session shop
sleep 9
lab exec 'pkill -u ana -f walwatch.sh' >/dev/null 2>&1 || true
on 'cat walwatch.log'

block symptoms
printf "SELECT name, city FROM customers ORDER BY id LIMIT 3;\nSELECT count(*), sum(total_cents) FROM orders;\n" | session shop

ALERT=$(lab exec "grep -m1 ALERT walwatch.log | cut -d' ' -f1")
TARGET="$(date +%F) $(date -d "$(date +%F) $ALERT 10 seconds ago" +%T)-03"
lab exec 'psql -qX shop -c "SELECT pg_switch_wal()" > /dev/null'
sleep 3

block restore
on 'sudo pg_ctlcluster 16 restore stop'
on 'sudo rm -rf /var/lib/postgresql/16/restore'
on "sudo -u postgres pgbackrest --stanza=main --pg1-path=/var/lib/postgresql/16/restore --archive-mode=off --type=time \"--target=$TARGET\" --target-action=pause restore"
on 'sudo pg_ctlcluster 16 restore start'
printf "SELECT name, city FROM customers ORDER BY id LIMIT 3;\nSELECT count(*), sum(total_cents) FROM orders;\n" | session shop -p 5433

block audit
on 'psql -X -A -t -p 5433 shop -f inventory.sql > inventory-restored.txt'
on 'diff inventory-known.txt inventory-restored.txt'
