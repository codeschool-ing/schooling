#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts from the server BEFORE PostgreSQL is installed, because the minor
# upgrade needs a server that is behind: 16.2, the version Ubuntu 24.04 was
# released with, is installed from apt's cache, and lessons 3 and 4 are
# replayed on it (ana's role and database, then shop.sql taken out of lesson
# 4's own .md). The upgrade to 16.15 is then the one the lesson prints, and
# from there the machine is in the state every lesson from 5 on starts in.
# apt's own output is not quoted, as in lesson 3.
#
# STAGED:
#   - /etc/default/locale says LANG=C.UTF-8, as on an Ubuntu server image. The
#     lab's base system has the file empty, and pg_createcluster takes its
#     locale from the environment, so without it a new cluster would be
#     SQL_ASCII where the student's is UTF-8.
#   - PostgreSQL 17. The lesson tells the student to add the PostgreSQL
#     project's apt repository (apt.postgresql.org) and install postgresql-17.
#     That repository was not reachable from the recording computer, and the
#     server has no network at all. So 17 was built on the recording computer
#     from the source tarball of Ubuntu's own postgresql-17 package (17.10),
#     configured into the paths the PGDG package uses (/usr/lib/postgresql/17,
#     /usr/share/postgresql/17, sockets in /var/run/postgresql) and kept as
#     /var/lib/machines/pg17.tar. It is unpacked into the server where the
#     lesson runs apt, and the package's postinst is replayed: postgresql-
#     common's own configure_version, which creates and starts 17/main. That
#     is why its version string reads `17.10` with no packaging suffix.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
export LAB_NAME=${LAB_NAME:-db}
LIVE=/var/lib/machines/dba-$LAB_NAME
PG17=${PG17:-/var/lib/machines/pg17.tar}
[ -f "$PG17" ] || { echo "no $PG17: build PostgreSQL 17 first" >&2; exit 1; }

lab reset 3
lab root 'echo LANG=C.UTF-8 > /etc/default/locale'
lab as 'sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-download postgresql-16=16.2-1ubuntu4 postgresql-client-16=16.2-1ubuntu4 libpq5=16.2-1ubuntu4 >/dev/null 2>&1'
lab root 'su - postgres -c "createuser --superuser ana"'
lab as 'createdb ana'
fence le-56a5dn23/a-database-to-look-after.md '-- shop.sql' | lab as 'cat > shop.sql'
lab as 'createdb shop && psql -q shop -f shop.sql >/dev/null'
sleep 2

block minor-before
on 'apt list --upgradable 2>/dev/null | grep postgresql'
on 'psql -c "SELECT version();" -c "SELECT pg_postmaster_start_time();"'

lab as 'sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-download postgresql-16 >/dev/null 2>&1'

block minor-after
on "psql -c 'SELECT version();' -c 'SELECT pg_postmaster_start_time();'"
on "sudo grep -E 'fast shutdown|system is shut down|starting PostgreSQL|ready to accept' /var/log/postgresql/postgresql-16-main.log"

block rehearsal
on 'sudo pg_createcluster 16 rehearsal --start'
on 'pg_lsclusters 16'
on 'sudo -u postgres pg_dumpall | sudo -u postgres psql -q -p 5433 >/dev/null'
on 'psql -p 5433 -c "SELECT count(*) FROM orders;" shop'

lab as 'sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-download postgresql-16-repack >/dev/null 2>&1'

block extensions
printf 'ana@db:~$ psql -p 5433 shop\n'
printf 'CREATE EXTENSION pg_stat_statements;\nCREATE EXTENSION pg_repack;\n\\dx\n\\q\n' | session shop -p 5433

# what the PGDG postgresql-17 package would do: the files, then its postinst
tar -C "$LIVE" -xf "$PG17"
lab root '. /usr/share/postgresql-common/maintscripts-functions; configure_version 17 "" >/dev/null 2>&1; systemctl daemon-reload; systemctl start postgresql@17-main'

block got17
on 'pg_lsclusters 17'
on 'psql --version'

block incompatible
on 'sudo -u postgres /usr/lib/postgresql/17/bin/postgres -D /var/lib/postgresql/16/rehearsal -c config_file=/etc/postgresql/16/rehearsal/postgresql.conf'

block upgrade-refused
on 'sudo pg_upgradecluster -m upgrade --link 16 rehearsal'
on 'sudo find /var/log/postgresql -name loadable_libraries.txt -exec cat {} +'
printf 'ana@db:~$ psql -p 5433 shop\n'
printf 'DROP EXTENSION pg_repack;\n\\q\n' | session shop -p 5433

block upgrade
on 'time sudo pg_upgradecluster -m upgrade --link 16 rehearsal'
on 'pg_lsclusters'

block links
F=$(lab as "psql -p 5433 -XAtc \"SELECT pg_relation_filepath('orders')\" shop")
on "sudo ls -li /var/lib/postgresql/16/rehearsal/$F /var/lib/postgresql/17/rehearsal/$F"
on 'sudo du -sh /var/lib/postgresql/16/rehearsal /var/lib/postgresql/17/rehearsal'
on 'sudo pg_ctlcluster 16 rehearsal start'
on 'sudo tail -n 5 /var/log/postgresql/postgresql-16-rehearsal.log'

block dump
on 'pg_dump --version'
on '/usr/lib/postgresql/17/bin/pg_dump --version'
on 'time /usr/lib/postgresql/17/bin/pg_dump -Fc -f shop.dump shop'
on 'ls -lh shop.dump'

block restore
on 'sudo -u postgres /usr/lib/postgresql/17/bin/pg_dumpall --globals-only | sudo -u postgres psql -q -p 5434'
on 'createdb -p 5434 shop'
on 'time pg_restore -p 5434 -d shop -j 4 shop.dump'
printf 'ana@db:~$ psql -p 5434 shop\n'
Q="SELECT pg_size_pretty(pg_table_size('orders')) AS orders, pg_size_pretty(pg_indexes_size('orders')) AS its_indexes;"
printf '#banner\nSELECT count(*) FROM orders;\n%s\n\\q\n' "$Q" | session shop -p 5434
on "psql -c \"$Q\" shop"

block source
on 'sudo pg_createcluster 16 source -o wal_level=logical --start >/dev/null'
on 'sudo -u postgres pg_dumpall | sudo -u postgres psql -q -p 5436 >/dev/null'
printf 'ana@db:~$ psql -p 5436 shop\n'
printf 'SHOW wal_level;\nCREATE PUBLICATION upgrade FOR ALL TABLES;\n\\q\n' | session shop -p 5436

block subscribe
on 'dropdb -p 5434 shop && createdb -p 5434 shop'
on '/usr/lib/postgresql/17/bin/pg_dump -p 5436 --schema-only --no-publications shop | psql -q -p 5434 shop >/dev/null'
printf 'ana@db:~$ psql -p 5434 shop\n'
printf "CREATE SUBSCRIPTION upgrade\n    CONNECTION 'host=/var/run/postgresql port=5436 dbname=shop user=postgres'\n    PUBLICATION upgrade;\n\\\\q\n" | session shop -p 5434
lab as "until [ \"\$(psql -p 5434 -XAtc \"SELECT count(*) FROM pg_subscription_rel WHERE srsubstate <> 'r'\" shop)\" = 0 ]; do sleep 1; done"

block caught-up
printf 'ana@db:~$ psql -p 5434 shop\n'
printf "SELECT srrelid::regclass, srsubstate FROM pg_subscription_rel;\nSELECT count(*) FROM orders;\n\\\\q\n" | session shop -p 5434
printf 'ana@db:~$ psql -p 5436 shop\n'
printf "INSERT INTO orders (customer_id, status, total_cents, created_at)\nVALUES (42, 'paid', 1999, '2026-10-01 10:00-03') RETURNING id;\n\\\\q\n" | session shop -p 5436
sleep 3
printf 'ana@db:~$ psql -p 5434 shop\n'
printf "SELECT id, customer_id, total_cents FROM orders WHERE id > 999999;\nSELECT last_value, is_called FROM orders_id_seq;\n\\\\q\n" | session shop -p 5434

block cutover
printf 'ana@db:~$ psql -p 5434 shop\n'
printf "DROP SUBSCRIPTION upgrade;\nINSERT INTO orders (customer_id, status, total_cents, created_at)\nVALUES (7, 'paid', 500, '2026-10-02 09:00-03') RETURNING id;\nSELECT setval('orders_id_seq', (SELECT max(id) FROM orders));\nSELECT setval('customers_id_seq', (SELECT max(id) FROM customers));\nINSERT INTO orders (customer_id, status, total_cents, created_at)\nVALUES (7, 'paid', 500, '2026-10-02 09:00-03') RETURNING id;\n\\\\q\n" | session shop -p 5434

block after
on 'sudo find /var/log/postgresql -name update_extensions.sql -exec cat {} +'
printf 'ana@db:~$ psql -p 5433 shop\n'
printf "SELECT relname, last_analyze FROM pg_stat_user_tables ORDER BY relname;\n\\\\dx pg_stat_statements\nALTER EXTENSION pg_stat_statements UPDATE;\n\\\\dx pg_stat_statements\n\\\\q\n" | session shop -p 5433

block drop-old
on 'sudo pg_dropcluster 16 rehearsal'
on 'sudo du -sh /var/lib/postgresql/17/rehearsal'
on 'psql -p 5433 -Atc "SELECT count(*) FROM orders;" shop'

block cleanup
on 'sudo pg_dropcluster --stop 17 rehearsal'
on 'sudo pg_dropcluster --stop 17 main'
on 'sudo pg_dropcluster --stop 16 source'
on 'pg_lsclusters -h'
on 'psql -c "SHOW server_version;" -c "SELECT pg_postmaster_start_time();"'

lab down
