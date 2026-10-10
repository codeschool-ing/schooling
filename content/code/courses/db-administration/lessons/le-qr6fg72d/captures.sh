#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts where every lesson from 5 starts (shop loaded, ana a superuser)
# and builds lesson 11's end state by running the SQL printed in this lesson's
# first reading section, taken out of starting-here.md.
#
# STAGED, AND WHY:
#   - The student sets the two passwords with \password, which asks on the
#     terminal. Here the same passwords are set with ALTER ROLE ... PASSWORD,
#     typed into nothing that is shown; the stored verifier is the same kind.
#   - ~/.pgpass and layout.sql are written from the lesson's own blocks; the
#     student types them into an editor. layout.sql is the code parts of the
#     schooling-example in a-least-privilege-layout.md, joined in order.
export LAB_NAME=${LAB_NAME:-db}
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

lab reset 12

fence le-qr6fg72d/starting-here.md '-- where lesson 12 starts' | lab as 'psql -q -v ON_ERROR_STOP=1 shop'
lab as "psql -q shop -c \"ALTER ROLE bruno PASSWORD 'bruno-lab-only'\" -c \"ALTER ROLE app PASSWORD 'app-lab-only'\""
fence le-qr6fg72d/starting-here.md '# ~/.pgpass' | lab as 'cat > ~/.pgpass && chmod 600 ~/.pgpass'

asbruno() { printf 'ana@db:~$ psql -h localhost -U bruno shop\n'; session -h localhost -U bruno shop; }
asapp() { printf 'ana@db:~$ psql -h localhost -U app shop\n'; session -h localhost -U app shop; }

block start
printf '\\du\n\\drg\n' | session shop

block connect
on 'psql -h localhost -U bruno shop -c "SELECT current_user;"'
cat <<'EOF' | session shop
REVOKE CONNECT ON DATABASE shop FROM PUBLIC;
\l shop
EOF
on 'psql -h localhost -U bruno shop -c "SELECT current_user;"'
cat <<'EOF' | session shop
GRANT CONNECT ON DATABASE shop TO reporting, app;
EOF

block schema
cat <<'EOF' | session shop
CREATE SCHEMA reports;
CREATE VIEW reports.sales_by_month AS
SELECT date_trunc('month', created_at)::date AS month, count(*) AS orders, sum(total_cents) AS total_cents
FROM orders GROUP BY 1 ORDER BY 1;
GRANT SELECT ON reports.sales_by_month TO reporting;
EOF
cat <<'EOF' | asbruno
SELECT * FROM reports.sales_by_month;
SELECT count(*) FROM customers;
EOF

block usage
cat <<'EOF' | session shop
GRANT USAGE ON SCHEMA reports TO reporting;
EOF
cat <<'EOF' | asbruno
SELECT * FROM reports.sales_by_month;
EOF

block hasprivilege
cat <<'EOF' | session shop
SELECT has_database_privilege('bruno', 'shop', 'CONNECT') AS connect, has_schema_privilege('bruno', 'reports', 'USAGE') AS usage, has_table_privilege('bruno', 'customers', 'SELECT') AS select;
EOF

block public
cat <<'EOF' | session shop
\dn+ public
EOF
cat <<'EOF' | asbruno
CREATE TABLE notes (body text);
CREATE TEMP TABLE notes (body text);
EOF

block columns
cat <<'EOF' | session shop
GRANT SELECT (id, name, country, created_at) ON customers TO reporting;
EOF
cat <<'EOF' | asbruno
SELECT * FROM customers LIMIT 1;
SELECT id, name, country FROM customers ORDER BY id LIMIT 3;
EOF
cat <<'EOF' | session shop
\dp customers
EOF

block columntrap
cat <<'EOF' | session shop
GRANT SELECT ON customers TO app;
REVOKE SELECT (email) ON customers FROM app;
EOF
cat <<'EOF' | asapp
SELECT email FROM customers ORDER BY id LIMIT 1;
EOF
cat <<'EOF' | session shop
REVOKE SELECT ON customers FROM app;
EOF

block updatetrap
cat <<'EOF' | session shop
GRANT UPDATE (status) ON orders TO app;
EOF
cat <<'EOF' | asapp
BEGIN;
UPDATE orders SET status = 'shipped' WHERE id = 1;
ROLLBACK;
BEGIN;
UPDATE orders SET status = 'shipped';
ROLLBACK;
EOF
cat <<'EOF' | session shop
REVOKE UPDATE (status) ON orders FROM app;
EOF

block rls
cat <<'EOF' | session shop
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
EOF
cat <<'EOF' | asbruno
SELECT count(*) FROM customers;
EOF
cat <<'EOF' | session shop
CREATE POLICY reporting_brazil ON customers FOR SELECT TO reporting USING (country = 'BR');
EOF
cat <<'EOF' | asbruno
SELECT country, count(*) FROM customers GROUP BY country;
EOF
cat <<'EOF' | session shop
SELECT count(*) FROM customers;
\dp customers
EOF

block rlsoff
cat <<'EOF' | session shop
DROP POLICY reporting_brazil ON customers;
ALTER TABLE customers DISABLE ROW LEVEL SECURITY;
EOF

python3 - a-least-privilege-layout.md <<'PY' | lab as 'cat > layout.sql'
import json, sys
t = open(sys.argv[1], encoding='utf-8').read()
body = t.split('```schooling-example\n', 1)[1].split('\n```', 1)[0]
print('\n'.join(p['code'] for p in json.loads(body)['parts']))
PY

block layout
on 'psql shop -f layout.sql'
cat <<'EOF' | session shop
\l shop
\dp
\dp reports.*
EOF

block layouttest
cat <<'EOF' | asapp
BEGIN;
INSERT INTO orders (customer_id, status, total_cents, created_at) VALUES (1, 'paid', 990, now());
ROLLBACK;
DROP TABLE orders;
CREATE TABLE notes (body text);
EOF
cat <<'EOF' | asbruno
SELECT email FROM customers LIMIT 1;
SELECT count(*) FROM orders;
EOF

lab down
