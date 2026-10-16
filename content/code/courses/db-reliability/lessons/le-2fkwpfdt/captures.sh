#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of db-reliability, as a script that
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
# archive-push, the stanza and one full backup. The transaction id, the segment
# name and the times the lesson quotes come from this run; the script carries
# them from one block to the next the way a person copies them off the screen.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, pgBackRest 2.50,
# TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/lib.sh

lab base
lab exec 'sudo pg_createcluster 16 restore --port 5433 >/dev/null && sudo pg_ctlcluster 16 restore start && sudo -u postgres createuser -p 5433 --superuser ana'
extract ../le-62bgpm2d/setting-up.md pgbackrest.conf | lab exec 'sudo tee /etc/pgbackrest.conf > /dev/null'
printf "ALTER SYSTEM SET archive_mode = on;\nALTER SYSTEM SET archive_command = 'pgbackrest --stanza=main archive-push %%p';\n" | lab psql shop >/dev/null
lab exec 'sudo pg_ctlcluster 16 main restart && sudo -u postgres pgbackrest --stanza=main stanza-create && sudo -u postgres pgbackrest --stanza=main backup --type=full'

block backup
on 'sudo -u postgres pgbackrest --stanza=main info'

block day
shell <<'SH'
for i in 1 2 3 4 5; do psql -q shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES ($i, 1000 + $i, now())"; sleep 1; done
psql shop -c "DELETE FROM orders WHERE placed_at < '2026-03-01'"
for i in 6 7 8; do psql -q shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES ($i, 1000 + $i, now())"; sleep 1; done
SH

block noticed
printf "SELECT count(*), min(placed_at) FROM orders;\nSELECT pg_walfile_name(pg_current_wal_lsn());\n" | session shop

SEG=$(lab exec "psql -X -A -t shop -c 'SELECT pg_walfile_name(pg_current_wal_lsn())'")

block waldump-count
on "sudo /usr/lib/postgresql/16/bin/pg_waldump --path=/var/lib/postgresql/16/main/pg_wal $SEG | awk '/desc: DELETE/ {print \$8}' | sort | uniq -c"

XID=$(lab exec "sudo /usr/lib/postgresql/16/bin/pg_waldump --path=/var/lib/postgresql/16/main/pg_wal $SEG 2>/dev/null | awk '/desc: DELETE/ {print \$8}' | sort | uniq -c | sort -rn | head -1 | awk '{print \$2}' | tr -d ,")

block waldump-commits
on "sudo /usr/lib/postgresql/16/bin/pg_waldump --path=/var/lib/postgresql/16/main/pg_wal $SEG 2>/dev/null | grep 'desc: COMMIT' | sed -E 's/.*tx: +([0-9]+),.*COMMIT ([^;]*).*/\\1  \\2/'"

block first-try
on 'sudo pg_ctlcluster 16 restore stop'
on 'sudo rm -rf /var/lib/postgresql/16/restore'
on "sudo -u postgres pgbackrest --stanza=main --pg1-path=/var/lib/postgresql/16/restore --archive-mode=off --type=xid --target=$XID --target-exclusive --target-action=pause restore"
on 'sudo tail -n 4 /var/lib/postgresql/16/restore/postgresql.auto.conf'
on 'sudo pg_ctlcluster 16 restore start 2>&1 | grep -E "FATAL|could not start"'

block why
on 'sudo -u postgres pgbackrest --stanza=main info | grep "wal archive"'
printf "SELECT pg_switch_wal();\n" | session shop
sleep 2
on 'sudo -u postgres pgbackrest --stanza=main info | grep "wal archive"'

block restore-xid
on 'sudo rm -rf /var/lib/postgresql/16/restore'
on "sudo -u postgres pgbackrest --stanza=main --pg1-path=/var/lib/postgresql/16/restore --archive-mode=off --type=xid --target=$XID --target-exclusive --target-action=pause restore"
on 'sudo pg_ctlcluster 16 restore start'
on 'sudo grep -E "starting point-in-time|recovery stopping|pausing at|ready to accept" /var/log/postgresql/postgresql-16-restore.log | tail -n 4'

block inspect
printf "SELECT pg_is_in_recovery(), pg_get_wal_replay_pause_state();\nSELECT count(*), min(placed_at), max(id) FROM orders;\n" | session shop -p 5433

block promote
printf "SELECT pg_wal_replay_resume();\n" | session shop -p 5433
sleep 2
printf "SELECT pg_is_in_recovery();\nSELECT timeline_id FROM pg_control_checkpoint();\n" | session shop -p 5433

block history
on 'sudo ls /var/lib/postgresql/16/restore/pg_wal'
on 'sudo cat /var/lib/postgresql/16/restore/pg_wal/00000002.history'

block repair
on "psql -p 5433 shop -c \"\\copy (SELECT * FROM orders WHERE placed_at < '2026-03-01') TO 'deleted.csv' CSV\""
on "psql shop -c \"\\copy orders FROM 'deleted.csv' CSV\""
on 'psql shop -c "SELECT count(*), min(placed_at) FROM orders"'

block restore-time
TS=$(lab exec "sudo /usr/lib/postgresql/16/bin/pg_waldump --path=/var/lib/postgresql/16/main/pg_wal $SEG 2>/dev/null | grep -E 'tx: +$XID, .*desc: COMMIT' | sed -E 's/.*COMMIT ([0-9-]+ [0-9:]+)\\.[0-9]+ (.*)/\\1\\2/'")
on 'sudo pg_ctlcluster 16 restore stop'
on 'sudo rm -rf /var/lib/postgresql/16/restore'
on "sudo -u postgres pgbackrest --stanza=main --pg1-path=/var/lib/postgresql/16/restore --archive-mode=off --type=time \"--target=$TS\" --target-action=pause restore"
on 'sudo pg_ctlcluster 16 restore start'
printf "SELECT count(*), min(placed_at) FROM orders;\n" | session shop -p 5433
