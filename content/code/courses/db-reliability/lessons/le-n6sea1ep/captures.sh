#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of db-reliability, as a script that
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
# archive-push, the stanza, bigshop loaded from lesson 2's more-orders.sql, and
# one full backup. report.sql and restore-drill.sh are taken out of this
# lesson's .md files. The timings are this machine's: 4 cores and an SSD.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, pgBackRest 2.50,
# TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/lib.sh

lab base
lab exec 'sudo pg_createcluster 16 restore --port 5433 >/dev/null && sudo pg_ctlcluster 16 restore start && sudo -u postgres createuser -p 5433 --superuser ana'
extract ../le-62bgpm2d/setting-up.md pgbackrest.conf | lab exec 'sudo tee /etc/pgbackrest.conf > /dev/null'
extract ../le-nf0v8e40/where-it-stops.md '-- more-orders.sql' | lab exec 'cat > more-orders.sql'
lab exec 'createdb bigshop && psql -qX bigshop -f shop.sql >/dev/null 2>&1 && psql -qX bigshop -f more-orders.sql >/dev/null'
printf "ALTER SYSTEM SET archive_mode = on;\nALTER SYSTEM SET archive_command = 'pgbackrest --stanza=main archive-push %%p';\n" | lab psql shop >/dev/null
lab exec 'sudo pg_ctlcluster 16 main restart && sudo -u postgres pgbackrest --stanza=main stanza-create && sudo -u postgres pgbackrest --stanza=main backup --type=full'
extract the-report.md report.sql | lab exec 'cat > report.sql'
extract the-script.md restore-drill.sh | lab exec 'cat > restore-drill.sh'

block report
on 'psql -X -A -t shop -f report.sql'
on 'time psql -X -A -t bigshop -f report.sql'

block first-run
on 'chmod +x restore-drill.sh'
shell <<'SH'
./restore-drill.sh
echo $?
SH

block moving
shell <<'SH'
(for i in $(seq 1 600); do psql -q bigshop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (1, 900, now())"; done) &
./restore-drill.sh
echo $?
wait
SH

block history
on './restore-drill.sh > /dev/null'
on 'cat drills.csv'
