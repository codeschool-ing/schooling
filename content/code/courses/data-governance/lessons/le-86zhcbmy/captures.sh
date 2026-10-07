#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of data-governance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: the cluster `16/gov` and the database
# `ipe`, loaded by lab.sh; the lab passwords, written into ~/.pgpass by `put`
# so that ana can connect as each role (the lesson says why a real ~/.pgpass
# holds one person's password and not five). The passwords are typed at
# psql's \password prompts by lab/typein.py, which prints the prompts and not
# the answers.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, 4 cores, TZ=America/Sao_Paulo.
. ../../lab/capture.sh
lab reset >/dev/null
TYPEIN="python3 $(cd ../../lab && pwd)/typein.py"
cp ../../lab/typein.py /usr/local/bin/typein.py

block versions
on 'psql --version'
on 'pg_lsclusters'

block first-try
on 'psql'

block du-before
on 'sudo -u postgres psql -c "\du"'

block hba-default
on "sudo grep -v -e '^#' -e '^\$' /etc/postgresql/16/gov/pg_hba.conf"

put ana.sql <<'EOF'
-- Ana's own login. She creates and manages the other roles, and may
-- become the owner of the tables when she chooses to, never by default.
CREATE ROLE ana LOGIN CREATEROLE;
GRANT ipe_owner TO ana WITH INHERIT FALSE;
EOF
code ana-sql ana.sql
block ana
on 'sudo -u postgres psql -d ipe < ana.sql'
on 'psql -c "SELECT current_user, session_user"'

put logins.sql <<'EOF'
-- One login per person and one per program. No passwords here: a password
-- typed into SQL travels to the server as text and can land in a log.
CREATE ROLE bruno LOGIN;                          -- analyst, BI
CREATE ROLE carla LOGIN;                          -- customer support
CREATE ROLE davi  LOGIN;                          -- the DPO (encarregado)
CREATE ROLE lia   LOGIN VALID UNTIL '2026-06-30'; -- intern, contract ended
CREATE ROLE site_app   LOGIN CONNECTION LIMIT 3;  -- the website
CREATE ROLE etl_loader LOGIN;                     -- the nightly pipeline
EOF
code logins-sql logins.sql
block logins
on 'psql -f logins.sql'

put logddl.sql <<'EOF'
ALTER SYSTEM SET log_statement = 'ddl';
SELECT pg_reload_conf();
EOF
code logddl-sql logddl.sql
block ddl-log
on 'sudo -u postgres psql < logddl.sql'
on "psql -c \"ALTER ROLE lia PASSWORD 'lab-lia-2026'\""
on 'sudo grep PASSWORD /var/log/postgresql/postgresql-16-gov.log'
quiet 'sudo -u postgres psql -c "ALTER SYSTEM RESET log_statement" -c "SELECT pg_reload_conf()"'
quiet 'rm -f ~/.psql_history'

block password
printf 'ana@lab:~/gov$ %s\n' 'psql -c "\password bruno"'
lab exec "$TYPEIN lab-bruno-2026 lab-bruno-2026 -- psql -c '\\password bruno'"
quiet "$TYPEIN lab-carla-2026 lab-carla-2026 -- psql -c '\\password carla'"
quiet "$TYPEIN lab-davi-2026 lab-davi-2026 -- psql -c '\\password davi'"
quiet "$TYPEIN lab-lia-2026 lab-lia-2026 -- psql -c '\\password lia'"
quiet "$TYPEIN lab-site-2026 lab-site-2026 -- psql -c '\\password site_app'"
quiet "$TYPEIN lab-etl-2026 lab-etl-2026 -- psql -c '\\password etl_loader'"

block verifier
on "sudo -u postgres psql -d ipe -c \"SELECT rolname, rolpassword FROM pg_authid WHERE rolname = 'bruno'\""

block du-after
on 'psql -c "\du"'

block peer-refused
on 'psql -U bruno'

put pg_hba.conf <<'EOF'
# TYPE  DATABASE  USER      ADDRESS        METHOD
local   all       postgres                 peer
local   ipe       ana                      peer
host    ipe       all       127.0.0.1/32   scram-sha-256
host    all       all       all            reject
EOF
code hba-new pg_hba.conf
block hba-install
on 'sudo install -o postgres -g postgres -m 640 pg_hba.conf /etc/postgresql/16/gov/'
on 'sudo -u postgres psql -c "SELECT pg_reload_conf()"'
on 'sudo -u postgres psql -c "SELECT line_number, type, database, user_name, address, auth_method FROM pg_hba_file_rules"'

block socket-refused
on 'psql -U bruno'

block pgpass
lab exec "printf '%s\n' 'db.ipe.example:5433:ipe:bruno:lab-bruno-2026' 'db.ipe.example:5433:ipe:carla:lab-carla-2026' 'db.ipe.example:5433:ipe:davi:lab-davi-2026' 'db.ipe.example:5433:ipe:lia:lab-lia-2026' 'db.ipe.example:5433:ipe:site_app:lab-site-2026' 'db.ipe.example:5433:ipe:etl_loader:lab-etl-2026' > ~/.pgpass && chmod 644 ~/.pgpass"
on 'ls -l ~/.pgpass'
on 'psql -h db.ipe.example -U bruno -c "SELECT current_user"'
on 'chmod 600 ~/.pgpass'
on 'psql -h db.ipe.example -U bruno -c "SELECT current_user"'

block wrong-password
on 'PGPASSWORD=lab-bruno-2025 psql -h db.ipe.example -U bruno -c "SELECT 1"'
on 'PGPASSWORD=lab-bruno-2026 psql -h db.ipe.example -U nobody -c "SELECT 1"'

block expired
on 'psql -h db.ipe.example -U lia -c "SELECT 1"'

block log-auth
on 'sudo grep DETAIL /var/log/postgresql/postgresql-16-gov.log'

block conn-limit
on 'for i in 1 2 3; do psql -h db.ipe.example -U site_app -c "SELECT pg_sleep(2)" >/dev/null & done; sleep 1; psql -h db.ipe.example -U site_app -c "SELECT 1"; wait'

block log-connections
on 'sudo -u postgres psql -c "ALTER SYSTEM SET log_connections = on" -c "SELECT pg_reload_conf()"'
on 'psql -h db.ipe.example -U carla -c "SELECT 1" >/dev/null'
on 'sudo tail -n 2 /var/log/postgresql/postgresql-16-gov.log'

block public-default
on 'psql -c "\l ipe"'
on 'psql -h db.ipe.example -U bruno -c "SELECT count(*) FROM sales.customers"'
on 'psql -h db.ipe.example -U bruno -c "\dn"'

put connect.sql <<'EOF'
-- Who may open a session on `ipe` at all: nobody, until a grant says so.
REVOKE CONNECT, TEMPORARY ON DATABASE ipe FROM PUBLIC;
GRANT CONNECT ON DATABASE ipe TO bruno, carla, davi, site_app, etl_loader;
EOF
code connect-sql connect.sql
block connect
on 'sudo -u postgres psql -d ipe < connect.sql'
on 'psql -c "\l ipe"'
on 'sudo -u postgres psql -c "GRANT CONNECT ON DATABASE ipe TO ana"'
on 'psql -c "\l ipe"'
