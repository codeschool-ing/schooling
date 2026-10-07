# Where lesson 1 leaves the database: ana and the six logins, their lab
# passwords, the pg_hba.conf the lesson writes, log_connections on, and
# CONNECT on `ipe` granted by name instead of to PUBLIC.
set -euo pipefail
pg() { runuser -u postgres -- env PGPORT=$PORT psql -X -q -v ON_ERROR_STOP=1 -d ipe "$@"; }
pg <<'SQL'
CREATE ROLE ana LOGIN CREATEROLE;
GRANT ipe_owner TO ana WITH INHERIT FALSE;
SQL
runuser -u postgres -- env PGPORT=$PORT psql -X -q -v ON_ERROR_STOP=1 -d ipe -c "SET ROLE ana" -c "
CREATE ROLE bruno LOGIN PASSWORD 'lab-bruno-2026';
CREATE ROLE carla LOGIN PASSWORD 'lab-carla-2026';
CREATE ROLE davi  LOGIN PASSWORD 'lab-davi-2026';
CREATE ROLE lia   LOGIN PASSWORD 'lab-lia-2026' VALID UNTIL '2026-06-30';
CREATE ROLE site_app   LOGIN PASSWORD 'lab-site-2026' CONNECTION LIMIT 3;
CREATE ROLE etl_loader LOGIN PASSWORD 'lab-etl-2026';"
cat > /etc/postgresql/16/gov/pg_hba.conf <<'HBA'
# TYPE  DATABASE  USER      ADDRESS        METHOD
local   all       postgres                 peer
local   ipe       ana                      peer
host    ipe       all       127.0.0.1/32   scram-sha-256
host    all       all       all            reject
HBA
chown postgres:postgres /etc/postgresql/16/gov/pg_hba.conf
chmod 640 /etc/postgresql/16/gov/pg_hba.conf
pg -c "ALTER SYSTEM SET log_connections = on" -c "SELECT pg_reload_conf()" >/dev/null
pg <<'SQL'
REVOKE CONNECT, TEMPORARY ON DATABASE ipe FROM PUBLIC;
GRANT CONNECT ON DATABASE ipe TO bruno, carla, davi, site_app, etl_loader;
GRANT CONNECT ON DATABASE ipe TO ana;
SQL
printf '%s\n' 'db.ipe.example:5433:ipe:bruno:lab-bruno-2026' \
  'db.ipe.example:5433:ipe:carla:lab-carla-2026' 'db.ipe.example:5433:ipe:davi:lab-davi-2026' \
  'db.ipe.example:5433:ipe:lia:lab-lia-2026' 'db.ipe.example:5433:ipe:site_app:lab-site-2026' \
  'db.ipe.example:5433:ipe:etl_loader:lab-etl-2026' > /home/ana/.pgpass
chown ana:ana /home/ana/.pgpass
chmod 600 /home/ana/.pgpass
