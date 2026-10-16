#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of db-reliability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the machine as lesson 1 leaves it (`lab.sh base`), plus the
# second server 16/restore from lesson 2, created quietly. Lesson 4's
# archive_command is not carried over: this lesson replaces it, and the
# capture sets the new one exactly as setting-up.md prints it.
# pgbackrest.conf and nightly-backup.sh are taken out of this lesson's .md
# files and installed where the lesson tells the student to put them.
#
# The damage in `tamper` is done by the author with a shell redirect into the
# repository, standing in for a disk or a person; the lesson shows the command.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, pgBackRest 2.50,
# TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/lib.sh

lab base
lab exec 'sudo pg_createcluster 16 restore --port 5433 >/dev/null && sudo pg_ctlcluster 16 restore start && sudo -u postgres createuser -p 5433 --superuser ana'
extract ../le-5277pqzg/first-restore.md verify.sql | lab exec 'cat > verify.sql'
extract setting-up.md pgbackrest.conf | lab exec 'sudo tee /etc/pgbackrest.conf > /dev/null'

block version
on 'pgbackrest version'

block archive
printf "ALTER SYSTEM SET archive_mode = on;\nALTER SYSTEM SET archive_command = 'pgbackrest --stanza=main archive-push %%p';\n" | session shop
on 'sudo pg_ctlcluster 16 main restart'

block stanza
on 'sudo -u postgres pgbackrest --stanza=main --log-level-console=info stanza-create'
on 'sudo -u postgres pgbackrest --stanza=main --log-level-console=info check'

block full
on 'sudo -u postgres pgbackrest --stanza=main backup --type=full'
on 'sudo -u postgres pgbackrest --stanza=main info'

block diff
on 'psql shop -c "UPDATE orders SET total_cents = total_cents + 1 WHERE id <= 1000"'
on 'sudo -u postgres pgbackrest --stanza=main --log-level-console=info backup --type=diff'

block incr
on "psql shop -c \"INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (1, 700, '2026-09-01 11:00-03')\""
on 'sudo -u postgres pgbackrest --stanza=main backup --type=incr'
on 'sudo -u postgres pgbackrest --stanza=main info'

block retention
on 'sudo -u postgres pgbackrest --stanza=main backup --type=full'
on 'sudo -u postgres pgbackrest --stanza=main --log-level-console=info backup --type=full'
on 'sudo -u postgres pgbackrest --stanza=main info'

block verify-ok
shell <<'SH'
sudo -u postgres pgbackrest --stanza=main verify
echo $?
sudo -u postgres pgbackrest --stanza=main verify --verbose --output=text
SH

block tamper
on 'sudo ls /var/lib/pgbackrest/backup/main'
lab exec 'L=$(sudo -u postgres pgbackrest --stanza=main info --output=json | grep -o "\"label\":\"[^\"]*F\"" | tail -1 | cut -d\" -f4); echo $L > .lastfull'
L=$(lab exec 'cat .lastfull')
on "sudo sh -c 'echo junk >> /var/lib/pgbackrest/backup/main/$L/pg_data/PG_VERSION.zst'"
shell <<'SH'
sudo -u postgres pgbackrest --stanza=main verify
echo $?
sudo -u postgres pgbackrest --stanza=main verify --verbose --output=text
echo $?
SH

block retake
on "sudo -u postgres pgbackrest --stanza=main --log-level-console=info expire --set=$L"
on 'sudo -u postgres pgbackrest --stanza=main backup --type=full'
on 'sudo -u postgres pgbackrest --stanza=main verify --verbose --output=text'

block restore
on 'sudo pg_ctlcluster 16 restore stop'
on 'sudo rm -rf /var/lib/postgresql/16/restore'
on 'time sudo -u postgres pgbackrest --stanza=main --pg1-path=/var/lib/postgresql/16/restore --archive-mode=off restore'
on 'sudo tail -n 3 /var/lib/postgresql/16/restore/postgresql.auto.conf'
on 'sudo pg_ctlcluster 16 restore start'
on 'psql -X -A -t shop -f verify.sql > live.txt'
on 'psql -X -A -t -p 5433 shop -f verify.sql > restored.txt'
on 'diff live.txt restored.txt && echo identical'

extract the-job.md nightly-backup.sh | lab exec 'cat > nightly-backup.sh'

block job
on 'sudo install -m 755 nightly-backup.sh /usr/local/bin/nightly-backup.sh'
shell <<'SH'
sudo -u postgres /usr/local/bin/nightly-backup.sh
echo $?
SH

block job-fails
lab exec 'L=$(sudo -u postgres pgbackrest --stanza=main info --output=json | grep -o "\"label\":\"[^\"]*F\"" | tail -1 | cut -d\" -f4); sudo sh -c "echo junk >> /var/lib/pgbackrest/backup/main/$L/pg_data/PG_VERSION.zst"'
shell <<'SH'
sudo -u postgres /usr/local/bin/nightly-backup.sh
echo $?
SH
