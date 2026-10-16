#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts where lesson 4 left the server: shop loaded, nothing else changed.
# workload.sql is taken out of this lesson's own .md and run as printed there.
# postgresql-16-postgis-3 is installed from apt's cache (the machine has no
# network), so apt's output is not quoted; the lesson shows the command alone.
# Everything the lesson changes is put back at the end, as the lesson says.
set -uo pipefail
cd "$(dirname "$0")"
export LAB_NAME=${LAB_NAME:-db}
. ../../lab/capture.sh

lab down; sleep 3   # let the old machine finish exiting before reset removes it
lab reset 18

block available
printf "SELECT count(*) FROM pg_available_extensions;\nSELECT name, default_version, installed_version, comment\n  FROM pg_available_extensions\n WHERE name IN ('pg_stat_statements', 'pgcrypto', 'pg_trgm', 'plpgsql', 'postgis')\n ORDER BY name;\n" | session shop

block files
on 'ls /usr/share/postgresql/16/extension/pgcrypto*'
on 'cat /usr/share/postgresql/16/extension/pgcrypto.control'
on 'ls -l /usr/lib/postgresql/16/lib/pgcrypto.so'

block perdb
printf "CREATE EXTENSION pgcrypto;\n\\\\dx\n\\\\c shop\n\\\\dx\n" | session ana

block trusted
printf "CREATE ROLE clerk;\nGRANT CREATE ON DATABASE ana TO clerk;\nDROP EXTENSION pgcrypto;\nSET ROLE clerk;\nCREATE EXTENSION pgcrypto;\nCREATE EXTENSION pageinspect;\nRESET ROLE;\n\\\\dx pgcrypto\n" | session ana

block pgss-not-loaded
printf "CREATE EXTENSION pg_stat_statements;\nSELECT count(*) FROM pg_stat_statements;\n" | session shop

block typo
printf "ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statement';\n" | session shop
# The restart is printed in the lesson as a command. On the recording machine
# (a container) systemd never returned from the failed start, so its own
# reply is not quoted; the cluster's state and its log are.
lab as 'sudo timeout 20 systemctl restart postgresql@16-main' >/dev/null 2>&1
on 'pg_lsclusters'
on 'sudo tail -n 4 /var/log/postgresql/postgresql-16-main.log'

block fix
on 'sudo cat /var/lib/postgresql/16/main/postgresql.auto.conf'
on "sudo sed -i 's/pg_stat_statement'\"'\"'/pg_stat_statements'\"'\"'/' /var/lib/postgresql/16/main/postgresql.auto.conf"
on 'sudo systemctl restart postgresql@16-main'
on 'pg_lsclusters'

block loaded
printf "SHOW shared_preload_libraries;\nSELECT pg_stat_statements_reset();\n" | session shop

block workload
fence le-dn89k20k/pg-stat-statements.md '-- workload.sql' | lab as 'cat > workload.sql'
on 'pgbench -n -c 4 -t 50 --random-seed=1 -f workload.sql shop'

block top
printf "SELECT calls, round(total_exec_time) AS total_ms,\n       round(mean_exec_time::numeric, 2) AS mean_ms, rows,\n       left(query, 50) AS query\n  FROM pg_stat_statements\n ORDER BY total_exec_time DESC\n LIMIT 5;\n" | session shop

block digest
printf "%s\n" "SELECT encode(digest('correct horse battery', 'sha256'), 'hex');" "SELECT encode(digest('correct horse battery', 'sha256'), 'hex');" | session ana

block crypt
printf "%s\n" "CREATE TABLE app_users (" "    email         text PRIMARY KEY," "    password_hash text NOT NULL" ");" \
  "INSERT INTO app_users VALUES" "    ('ana@example.com', crypt('correct horse battery', gen_salt('bf')))," "    ('rui@example.com', crypt('correct horse battery', gen_salt('bf')));" \
  "SELECT * FROM app_users;" | session ana

block verify
printf "%s\n" "SELECT email FROM app_users" " WHERE email = 'ana@example.com'" "   AND password_hash = crypt('correct horse battery', password_hash);" \
  "SELECT email FROM app_users" " WHERE email = 'ana@example.com'" "   AND password_hash = crypt('correct horse batery', password_hash);" | session ana

block cost
printf "%s\n" "\\timing on" "SELECT count(digest(i::text, 'sha256')) FROM generate_series(1, 100000) AS i;" "\\timing off" | session ana
printf "%s\n" "\\timing on" "SELECT crypt('correct horse battery', gen_salt('bf')) IS NOT NULL;" "SELECT crypt('correct horse battery', gen_salt('bf', 12)) IS NOT NULL;" "\\timing off" | session ana

block uuid
printf "%s\n" "SELECT gen_random_uuid();" "\\df gen_random_uuid" | session shop

block postgis
lab as 'sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q postgresql-16-postgis-3 >/dev/null 2>&1'
printf "%s\n" "CREATE EXTENSION postgis;" "SELECT postgis_version();" "SELECT count(*) FROM pg_depend" " WHERE refobjid = (SELECT oid FROM pg_extension WHERE extname = 'postgis')" "   AND deptype = 'e';" | session ana

block warehouses
fence le-dn89k20k/postgis.md '-- warehouses.sql' | lab as 'cat > warehouses.sql'
on 'psql -f warehouses.sql'
printf "%s\n" "SELECT name," "       round(ST_Distance(location, 'POINT(-43.1729 -22.9068)') / 1000) AS km_from_rio" "  FROM warehouses" " ORDER BY km_from_rio;" \
  "SELECT name FROM warehouses" " WHERE ST_DWithin(location, 'POINT(-43.1729 -22.9068)', 2000000);" \
  "SELECT round(ST_Distance('POINT(-46.6333 -23.5505)'::geometry," "                         'POINT(-43.1729 -22.9068)'::geometry)::numeric, 2);" | session ana

block versions
printf "%s\n" "CREATE EXTENSION pg_trgm VERSION '1.5';" "SELECT name, default_version, installed_version" "  FROM pg_available_extensions" " WHERE installed_version IS NOT NULL" " ORDER BY name;" "ALTER EXTENSION pg_trgm UPDATE;" "\\dx pg_trgm" | session ana

block dump
on 'pg_dump --schema-only ana | grep -i extension'
on 'pg_dump --schema-only ana | wc -l'

block putback
printf "%s\n" "DROP TABLE app_users, warehouses;" "DROP EXTENSION pgcrypto, postgis, pg_trgm;" "REVOKE CREATE ON DATABASE ana FROM clerk;" "DROP ROLE clerk;" "\\c shop" "DROP EXTENSION pg_stat_statements;" "ALTER SYSTEM RESET shared_preload_libraries;" | session ana
on 'sudo systemctl restart postgresql@16-main'
on 'psql shop -c "SHOW shared_preload_libraries"'
lab as 'rm -f workload.sql warehouses.sql'

lab down
