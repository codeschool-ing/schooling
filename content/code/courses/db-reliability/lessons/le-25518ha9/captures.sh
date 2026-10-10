#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of db-reliability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the machine as lesson 2 leaves it, rebuilt quietly: `lab.sh
# base` (role ana, database shop), the second server 16/restore on port 5433
# with ana on it, and bigshop loaded from lesson 2's more-orders.sql as that
# lesson prints it. Timings are this machine's: 4 cores and an SSD.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/lib.sh

lab base
lab exec 'sudo pg_createcluster 16 restore --port 5433 --start >/dev/null && sudo -u postgres createuser -p 5433 --superuser ana'
extract ../le-5277pqzg/first-restore.md verify.sql | lab exec 'cat > verify.sql'
extract ../le-nf0v8e40/where-it-stops.md '-- more-orders.sql' | lab exec 'cat > more-orders.sql'
lab exec 'createdb bigshop && psql -qX bigshop -f shop.sql >/dev/null 2>&1 && psql -qX bigshop -f more-orders.sql >/dev/null'

block cold
on 'sudo pg_ctlcluster 16 main stop'
on 'sudo cp -a /var/lib/postgresql/16/main cold-copy'
on 'sudo pg_ctlcluster 16 main start'
on 'sudo du -sh cold-copy'
on 'sudo du -sh cold-copy/pg_wal'

block basebackup
on 'pg_basebackup -D base -X stream -c fast -v'
on 'ls base'

block label
on 'cat base/backup_label'

block verify
on '/usr/lib/postgresql/16/bin/pg_verifybackup base'
on 'echo "tampered" | sudo tee -a base/global/pg_control > /dev/null'
on '/usr/lib/postgresql/16/bin/pg_verifybackup base'

block retake
on 'rm -rf base'
on 'pg_basebackup -D base -X stream -c fast'
on '/usr/lib/postgresql/16/bin/pg_verifybackup base'

block restore-base
on 'sudo pg_ctlcluster 16 restore stop'
on 'sudo rm -rf /var/lib/postgresql/16/restore'
on 'sudo cp -a base /var/lib/postgresql/16/restore'
on 'sudo chown -R postgres:postgres /var/lib/postgresql/16/restore'
on 'sudo chmod 700 /var/lib/postgresql/16/restore'
on 'sudo pg_ctlcluster 16 restore start'
on 'sudo tail -n 6 /var/log/postgresql/postgresql-16-restore.log'

block compare
on 'psql -X -A -t shop -f verify.sql > live.txt'
on 'psql -X -A -t -p 5433 shop -f verify.sql > restored.txt'
on 'diff live.txt restored.txt && echo identical'
on 'psql -p 5433 -l'

block timing
on 'rm -rf base'
on 'time pg_basebackup -D base -X stream -c fast'
on 'du -sh base'
on 'sudo pg_ctlcluster 16 restore stop'
on 'sudo rm -rf /var/lib/postgresql/16/restore'
shell <<'SH'
time { sudo cp -a base /var/lib/postgresql/16/restore && sudo chown -R postgres:postgres /var/lib/postgresql/16/restore && sudo chmod 700 /var/lib/postgresql/16/restore && sudo pg_ctlcluster 16 restore start; }
SH
on 'psql -X -A -t -p 5433 bigshop -c "SELECT count(*) FROM orders"'
