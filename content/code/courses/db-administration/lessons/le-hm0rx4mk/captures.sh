#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts where every lesson from 5 starts (shop loaded, ana a superuser)
# and builds the end of lesson 12 by running the SQL printed in this lesson's
# first reading section, taken out of starting-here.md.
#
# STAGED, AND WHY:
#   - The student sets the two passwords with \password, which asks on the
#     terminal. Here the same passwords are set with ALTER ROLE ... PASSWORD,
#     typed into nothing that is shown.
#   - ~/.pgpass is written from the lesson's own block.
#   - The predefined-roles section needs a second session belonging to app,
#     busy for a while: it is started in the background with
#     psql -c "SELECT pg_sleep(60)", as the section tells the student to do in
#     a second terminal.
export LAB_NAME=${LAB_NAME:-db}
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

lab reset 13

fence le-hm0rx4mk/starting-here.md '-- where lesson 13 starts' | lab as 'psql -q -v ON_ERROR_STOP=1 shop'
lab as "psql -q shop -c \"ALTER ROLE bruno PASSWORD 'bruno-lab-only'\" -c \"ALTER ROLE app PASSWORD 'app-lab-only'\""
fence le-hm0rx4mk/starting-here.md '# ~/.pgpass' | lab as 'cat > ~/.pgpass && chmod 600 ~/.pgpass'

asbruno() { printf 'ana@db:~$ psql -h localhost -U bruno shop\n'; session -h localhost -U bruno shop; }
asapp() { printf 'ana@db:~$ psql -h localhost -U app shop\n'; session -h localhost -U app shop; }

block start
printf '\\dt\n\\dp\n' | session shop

block nexttable
cat <<'EOF' | session shop
SET ROLE shop_owner;
CREATE TABLE refunds (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id     bigint NOT NULL REFERENCES orders (id),
    amount_cents integer NOT NULL,
    created_at   timestamptz NOT NULL DEFAULT now()
);
RESET ROLE;
\dp refunds
EOF
cat <<'EOF' | asapp
INSERT INTO refunds (order_id, amount_cents) VALUES (1, 500);
EOF
cat <<'EOF' | asbruno
SELECT count(*) FROM refunds;
EOF

block defaults
cat <<'EOF' | session shop
ALTER DEFAULT PRIVILEGES FOR ROLE shop_owner IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app;
ALTER DEFAULT PRIVILEGES FOR ROLE shop_owner IN SCHEMA public
    GRANT SELECT ON TABLES TO reporting;
\dp refunds
EOF

block catchup
cat <<'EOF' | session shop
GRANT SELECT, INSERT, UPDATE, DELETE ON refunds TO app;
GRANT SELECT ON refunds TO reporting;
EOF

block shipments
cat <<'EOF' | session shop
SET ROLE shop_owner;
CREATE TABLE shipments (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id   bigint NOT NULL REFERENCES orders (id),
    shipped_at timestamptz NOT NULL DEFAULT now()
);
RESET ROLE;
\dp shipments
EOF
cat <<'EOF' | asbruno
SELECT count(*) FROM shipments;
EOF

block trap
cat <<'EOF' | session shop
CREATE TABLE coupons (code text PRIMARY KEY, percent integer NOT NULL);
\dt coupons
\dp coupons
ALTER TABLE coupons OWNER TO shop_owner;
\dp coupons
EOF
cat <<'EOF' | asbruno
SELECT count(*) FROM coupons;
EOF

block trapfix
cat <<'EOF' | session shop
DROP TABLE coupons;
SET ROLE shop_owner;
CREATE TABLE coupons (code text PRIMARY KEY, percent integer NOT NULL);
RESET ROLE;
\dp coupons
EOF

block ddp
cat <<'EOF' | session shop
\ddp
EOF

block functions
cat <<'EOF' | session shop
ALTER DEFAULT PRIVILEGES FOR ROLE shop_owner REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
\ddp
EOF

block intern
cat <<'EOF' | session shop
CREATE ROLE intern LOGIN;
GRANT USAGE, CREATE ON SCHEMA reports TO intern;
SET ROLE intern;
CREATE TABLE reports.ideas (body text);
GRANT SELECT ON reports.ideas TO reporting;
RESET ROLE;
\c ana
CREATE TABLE notes (body text);
ALTER TABLE notes OWNER TO intern;
\c shop
DROP ROLE intern;
EOF

block reassign
cat <<'EOF' | session shop
REASSIGN OWNED BY intern TO shop_owner;
DROP OWNED BY intern;
DROP ROLE intern;
\c ana
REASSIGN OWNED BY intern TO ana;
DROP OWNED BY intern;
DROP ROLE intern;
EOF

block afterreassign
cat <<'EOF' | session shop
\dp reports.ideas
EOF

block inventory
cat <<'EOF' | session shop
DROP ROLE reporting;
EOF

block predefined
cat <<'EOF' | session shop
SELECT rolname FROM pg_roles WHERE rolname LIKE 'pg\_%' ORDER BY 1;
EOF

block readall
cat <<'EOF' | session shop
CREATE ROLE auditor LOGIN IN ROLE pg_read_all_data;
SELECT has_database_privilege('auditor', 'shop', 'CONNECT');
SET ROLE auditor;
SELECT email FROM customers ORDER BY id LIMIT 1;
SELECT count(*) FROM reports.ideas;
INSERT INTO coupons VALUES ('WELCOME', 10);
RESET ROLE;
DROP ROLE auditor;
EOF

lab as 'nohup psql -h localhost -U app shop -c "SELECT pg_sleep(60)" >/dev/null 2>&1 &'
sleep 2

block monitor
cat <<'EOF' | asbruno
SELECT pid, usename, state, query FROM pg_stat_activity WHERE usename = 'app';
EOF
cat <<'EOF' | session shop
GRANT pg_monitor TO bruno;
EOF
cat <<'EOF' | asbruno
SELECT pid, usename, state, query FROM pg_stat_activity WHERE usename = 'app';
EOF

block signal
cat <<'EOF' | asbruno
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE usename = 'app';
EOF
cat <<'EOF' | session shop
GRANT pg_signal_backend TO bruno;
EOF
cat <<'EOF' | asbruno
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE usename = 'app';
EOF
cat <<'EOF' | session shop
REVOKE pg_monitor, pg_signal_backend FROM bruno;
EOF

lab down
