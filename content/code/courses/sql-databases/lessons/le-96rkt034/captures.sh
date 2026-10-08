#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of sql-databases, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from a cluster exactly as `apt install postgresql` leaves it — no
# role for ana, no database — because the setup sections quote the refusals a
# student meets on the way. ~/.psqlrc and shop.sql are taken out of this
# lesson's own .md files and run as they are printed there.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, TZ=UTC.
set -uo pipefail
cd "$(dirname "$0")"
export TZ=UTC LC_ALL=C.UTF-8
LAB_SH=../../lab.sh
FENCE=../../lab/fence.py
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@vm:~$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/sql-capture.lock; flock 9

lab fresh
lab exec 'rm -f ~/.psqlrc ~/shop.sql'

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

python3 "$FENCE" installing-postgresql.md 'cat > ~/.psqlrc' | lab exec 'bash'

block first-session
printf 'ana@vm:~$ psql shop\n'
printf '#banner\nSELECT 1 + 1 AS two;\nSELECT NULL AS nothing;\n\\q\n' | session shop

block stopped
on 'sudo pg_ctlcluster 16 main stop'
on 'psql shop'
on 'pg_lsclusters'
on 'sudo pg_ctlcluster 16 main start'

python3 "$FENCE" reading-a-schema.md '-- shop.sql:' | lab exec 'cat > shop.sql'

block load
on 'psql shop -f shop.sql'

block load-twice
on 'psql shop -f shop.sql'

block reload
on 'dropdb shop'
on 'createdb shop'
on 'psql shop -f shop.sql >/dev/null'

block schema
printf 'ana@vm:~$ psql shop\n'
printf '#banner\n\\dt\n\\d orders\n' | session shop

block null
printf 'SELECT NULL = NULL;\nSELECT NULL = 5, NULL <> 5, NULL > 5, NULL + 1, %s;\n' "'a' || NULL" | session shop
