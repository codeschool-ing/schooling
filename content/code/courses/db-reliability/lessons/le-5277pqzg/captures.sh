#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of db-reliability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from a cluster exactly as `apt install postgresql` leaves it, with
# no role for ana and no database, because the setup sections quote the
# refusals a student meets on the way. shop.sql and verify.sql are taken out of
# this lesson's own .md files and run as they are printed there.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/lib.sh

lab fresh

block versions
on 'psql --version'
on 'pg_lsclusters'

block no-role
on 'psql'

block createuser
on 'sudo -u postgres createuser --superuser $USER'
on 'psql'

block peer
on 'psql -U postgres'

block createdb
on 'createdb shop'

extract installing.md shop.sql | lab exec 'cat > shop.sql'

block load
on 'psql shop -f shop.sql'

block count
printf 'SELECT count(*) AS customers FROM customers;\nSELECT count(*) AS orders, min(placed_at), max(placed_at) FROM orders;\n' | session shop

block dump
on 'pg_dump -Fc shop > shop.dump'
on 'ls -l shop.dump'
on 'createdb shop_restored'
on 'pg_restore -d shop_restored shop.dump'

extract first-restore.md verify.sql | lab exec 'cat > verify.sql'

block verify
on 'psql -X -A -t shop -f verify.sql > live.txt'
on 'psql -X -A -t shop_restored -f verify.sql > restored.txt'
on 'diff live.txt restored.txt && echo identical'
on 'cat restored.txt'

block broken
on 'psql shop_restored -c "DELETE FROM orders WHERE id = 49999"'
on 'psql -X -A -t shop_restored -f verify.sql > restored.txt'
on 'diff live.txt restored.txt && echo identical'

block pipe
shell <<'SH'
pg_dump shpo | gzip > shop.sql.gz
echo $?
ls -l shop.sql.gz
SH

block pipefail
shell <<'SH'
set -o pipefail
pg_dump shpo | gzip > shop.sql.gz
echo $?
SH

block stopped
on 'sudo pg_ctlcluster 16 main stop'
on 'psql shop'
on 'pg_lsclusters'
on 'sudo pg_ctlcluster 16 main start'
