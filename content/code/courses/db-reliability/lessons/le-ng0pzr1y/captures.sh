#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of db-reliability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the machine as lesson 7 leaves it, rebuilt quietly: `lab.sh
# base`, the second server 16/restore, pgbackrest.conf as lesson 5 prints it,
# archive-push, the stanza, bigshop loaded from lesson 2's more-orders.sql,
# one full backup, and lesson 7's report.sql and restore-drill.sh as that
# lesson prints them. rpo.sql is taken out of this lesson's measuring-rpo.md.
# The waits (`sleep`) stand for time passing on an ordinary afternoon. The
# timings are this machine's: 4 cores and an SSD.
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
extract ../le-n6sea1ep/the-report.md report.sql | lab exec 'cat > report.sql'
extract ../le-n6sea1ep/the-script.md restore-drill.sh | lab exec 'cat > restore-drill.sh && chmod +x restore-drill.sh'
extract measuring-rpo.md rpo.sql | lab exec 'cat > rpo.sql'

block rpo-quiet
on 'psql -X shop -f rpo.sql'
lab exec 'for i in 1 2 3; do psql -qX shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES ($i, 1500, now())"; done'
sleep 40
on 'psql -X shop -f rpo.sql'

block rpo-bounded
printf "ALTER SYSTEM SET archive_timeout = '60s';\nSELECT pg_reload_conf();\n" | session shop
sleep 30
on 'psql -X shop -f rpo.sql'

block wal-rate
printf "SELECT pg_current_wal_lsn() AS before \\\\gset\n\\\\timing on\nUPDATE orders SET total_cents = total_cents + 1;\nUPDATE orders SET total_cents = total_cents + 1;\n\\\\timing off\nSELECT pg_size_pretty(pg_current_wal_lsn() - :'before');\n" | session bigshop

block replay
on 'sudo -u postgres pgbackrest --stanza=main check'
on './restore-drill.sh'
