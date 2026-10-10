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
on 'sudo systemctl restart postgresql@16-main'
on 'pg_lsclusters'
on 'tail -n 3 /var/log/postgresql/postgresql-16-main.log'

block fix
on 'sudo cat /var/lib/postgresql/16/main/postgresql.auto.conf'
on "sudo sed -i 's/pg_stat_statement'\"'\"'/pg_stat_statements'\"'\"'/' /var/lib/postgresql/16/main/postgresql.auto.conf"
on 'sudo cat /var/lib/postgresql/16/main/postgresql.auto.conf'
on 'sudo systemctl restart postgresql@16-main'
on 'pg_lsclusters'

block loaded
printf "SHOW shared_preload_libraries;\nSELECT pg_stat_statements_reset();\n" | session shop

block workload
fence le-dn89k20k/pg-stat-statements.md '-- workload.sql' | lab as 'cat > workload.sql'
on 'pgbench -n -c 4 -t 50 --random-seed=1 -f workload.sql shop'

block top
printf "SELECT calls, round(total_exec_time) AS total_ms,\n       round(mean_exec_time, 2) AS mean_ms, rows,\n       left(query, 50) AS query\n  FROM pg_stat_statements\n ORDER BY total_exec_time DESC\n LIMIT 5;\n" | session shop

lab down
