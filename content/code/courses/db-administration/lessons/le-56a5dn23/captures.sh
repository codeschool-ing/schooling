#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts where lesson 3 ends: PostgreSQL installed, a superuser role and a
# database for ana. shop.sql is taken out of this lesson's own .md and run as
# it is printed there. The tablespace section makes /srv/pg/fast, as the lesson
# tells the student to; on the recording machine it is a directory on the same
# disk, which is what it is on the student's virtual machine too.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

lab reset 4

fence le-56a5dn23/a-database-to-look-after.md '-- shop.sql' | lab as 'cat > shop.sql'

block load
on 'createdb shop'
on 'time psql shop -f shop.sql'
printf 'ana@db:~$ psql shop\n'
printf '#banner\n\\dt+\n\\di+\nSELECT count(*) FROM orders;\n\\q\n' | session shop

block datadir
on 'sudo ls -l /var/lib/postgresql/16/main'
on 'sudo du -h -d1 /var/lib/postgresql/16/main | sort -h'
on 'sudo cat /var/lib/postgresql/16/main/postmaster.pid'

block oids
printf "SELECT oid, datname FROM pg_database ORDER BY oid;\nSELECT pg_relation_filepath('orders');\nSELECT pg_relation_filepath('orders_created_at');\n" | session shop
F=$(lab as "psql -XAtc \"SELECT pg_relation_filepath('orders')\" shop")
D=$(dirname "$F"); B=$(basename "$F")
on "sudo find /var/lib/postgresql/16/main/$D -name '$B*' -printf '%-10s %f\\n'"
printf 'VACUUM orders;\n' | session shop
on "sudo find /var/lib/postgresql/16/main/$D -name '$B*' -printf '%-10s %f\\n'"
printf "SELECT pg_size_pretty(pg_relation_size('orders')) AS main_fork,\n       pg_size_pretty(pg_table_size('orders')) AS table_size,\n       pg_size_pretty(pg_indexes_size('orders')) AS indexes,\n       pg_size_pretty(pg_total_relation_size('orders')) AS total;\nSHOW block_size;\nSHOW segment_size;\n" | session shop

block relfilenode
printf "CREATE TABLE scratch AS SELECT * FROM orders WHERE id <= 1000;\nSELECT pg_relation_filepath('scratch');\nTRUNCATE scratch;\nSELECT pg_relation_filepath('scratch');\nDROP TABLE scratch;\n" | session shop

block etc
on 'ls -l /etc/postgresql/16/main'
on 'cat /etc/postgresql/16/main/start.conf | grep -v "^#"'
on 'ls -l /var/log/postgresql /var/run/postgresql'

block tablespace
on 'sudo mkdir -p /srv/pg/fast'
on 'sudo chown postgres:postgres /srv/pg/fast'
on 'sudo chmod 700 /srv/pg/fast'
printf "CREATE TABLESPACE fast LOCATION '/srv/pg/fast';\n\\\\db\nALTER TABLE customers SET TABLESPACE fast;\nSELECT pg_relation_filepath('customers');\n" | session shop
on 'sudo ls -l /var/lib/postgresql/16/main/pg_tblspc'
on 'sudo find /srv/pg/fast -maxdepth 3'
printf "ALTER TABLE customers SET TABLESPACE pg_default;\nDROP TABLESPACE fast;\n" | session shop

lab down
