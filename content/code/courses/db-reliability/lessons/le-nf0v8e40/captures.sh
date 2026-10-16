#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of db-reliability, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the machine as lesson 1 leaves it (`lab.sh base`: role ana,
# database shop loaded from lesson 1's shop.sql). more-orders.sql is taken out
# of this lesson's where-it-stops.md and run as printed there. The timings in
# where-it-stops are whatever this machine took on the run that was pasted:
# 4 cores and an SSD, against the 2 processors lesson 1 recommends.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/lib.sh

lab base
extract ../le-5277pqzg/first-restore.md verify.sql | lab exec 'cat > verify.sql'

block roles
printf "CREATE ROLE shop_owner NOLOGIN;\nCREATE ROLE shop_app LOGIN PASSWORD 'app-secret-1';\nALTER TABLE customers OWNER TO shop_owner;\nALTER TABLE orders OWNER TO shop_owner;\nGRANT SELECT, INSERT ON orders, customers TO shop_app;\n" | session shop

block plain
on "pg_dump shop | grep -E '^(CREATE|ALTER|GRANT|COPY)'"

block formats
on 'pg_dump -Fp -f shop-plain.sql shop'
on 'pg_dump -Fc -f shop.dump shop'
on 'pg_dump -Fd -f shop.dir shop'
on 'pg_dump -Ft -f shop.tar shop'
on 'ls -l shop-plain.sql shop.dump shop.tar shop.dir'

block toc
on 'pg_restore -l shop.dump'

block new-server
on 'sudo pg_createcluster 16 restore --port 5433 --start'
on 'pg_lsclusters'
on 'psql -p 5433 -d postgres'

block restore-fails
on 'sudo -u postgres createuser -p 5433 --superuser $USER'
on 'createdb -p 5433 shop'
shell <<'SH'
pg_restore -p 5433 -d shop shop.dump
echo $?
SH

block globals
on 'pg_dumpall --globals-only -f globals.sql'
on "grep -E '^(CREATE|ALTER) ROLE' globals.sql"

block restore-again
on 'dropdb -p 5433 shop'
on 'psql -p 5433 -d postgres -f globals.sql'
on 'createdb -p 5433 shop'
shell <<'SH'
pg_restore -p 5433 -d shop shop.dump
echo $?
SH
on 'psql -X -A -t -p 5433 shop -f verify.sql > restored.txt'
on 'psql -X -A -t shop -f verify.sql > live.txt'
on 'diff live.txt restored.txt && echo identical'

block accident
on 'psql -X -A -t shop -f verify.sql > before.txt'
on "psql shop -c \"DELETE FROM orders WHERE customer_id IN (SELECT id FROM customers WHERE city = 'Curitiba')\""

block partial
on 'createdb scratch'
shell <<'SH'
pg_restore -d scratch -t orders -t customers shop.dump
echo $?
SH
on 'psql scratch -c "\d orders"'

block copy-back
on "psql scratch -c \"\\copy (SELECT o.* FROM orders o JOIN customers c ON c.id = o.customer_id WHERE c.city = 'Curitiba') TO 'curitiba.csv' CSV\""
on "psql shop -c \"\\copy orders FROM 'curitiba.csv' CSV\""
on 'psql -X -A -t shop -f verify.sql > after.txt'
on 'diff before.txt after.txt && echo identical'
on 'dropdb scratch'

extract where-it-stops.md '-- more-orders.sql' | lab exec 'cat > more-orders.sql'

block big
on 'createdb bigshop'
on 'psql -q bigshop -f shop.sql'
on 'psql bigshop -f more-orders.sql'
on "psql -X -A -t bigshop -c \"SELECT pg_size_pretty(pg_database_size('bigshop'))\""

block big-dump
on 'time pg_dump -Fc -f bigshop.dump bigshop'
on 'ls -lh bigshop.dump'
on 'createdb -p 5433 bigshop'
on 'time pg_restore -p 5433 -d bigshop bigshop.dump'

block big-parallel
on 'time pg_dump -Fd -j 2 -f bigshop.dir bigshop'
on 'dropdb -p 5433 bigshop'
on 'createdb -p 5433 bigshop'
on 'time pg_restore -p 5433 -j 2 -d bigshop bigshop.dir'
